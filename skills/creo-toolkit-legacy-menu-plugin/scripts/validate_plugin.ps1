param(
    [Parameter(Mandatory = $true)]
    [string]$PluginRoot,

    [Parameter(Mandatory = $true)]
    [string]$ConfigPro,

    [switch]$EffectiveConfigConfirmed,

    [switch]$AllowTestConfig
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$failures = [System.Collections.Generic.List[string]]::new()

function Require-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) { Write-Output "PASS: $Message" }
    else { Write-Output "FAIL: $Message"; $script:failures.Add($Message) }
}

function Get-NormalizedDirectory {
    param([string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
}

function Test-IsPathWithin {
    param(
        [string]$Candidate,
        [string]$Directory
    )

    $candidatePath = [System.IO.Path]::GetFullPath($Candidate)
    $directoryPath = Get-NormalizedDirectory $Directory
    return $candidatePath.StartsWith(
        $directoryPath + [System.IO.Path]::DirectorySeparatorChar,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}

if (-not $EffectiveConfigConfirmed) {
    throw "Refusing to validate an unconfirmed config.pro. Prove that Creo reads this file at startup, then pass -EffectiveConfigConfirmed."
}

$root = (Resolve-Path -LiteralPath $PluginRoot).Path
$registry = Join-Path $root "protk.dat"
Require-True (Test-Path -LiteralPath $registry -PathType Leaf) "protk.dat exists"
if (-not (Test-Path -LiteralPath $registry -PathType Leaf)) { exit 1 }

Require-True (Test-Path -LiteralPath $ConfigPro -PathType Leaf) "effective config.pro exists"
if (-not (Test-Path -LiteralPath $ConfigPro -PathType Leaf)) { exit 1 }
$configResolved = (Resolve-Path -LiteralPath $ConfigPro).Path
Require-True ([string]::Equals(
        [System.IO.Path]::GetFileName($configResolved),
        "config.pro",
        [System.StringComparison]::OrdinalIgnoreCase
    )) "startup target is named config.pro"
$isInsidePluginRoot = Test-IsPathWithin -Candidate $configResolved -Directory $root
$isTestLikePath = $configResolved -match '(?i)[\\/](?:tests?|fixtures?|samples?)[\\/]'
if (($isInsidePluginRoot -or $isTestLikePath) -and -not $AllowTestConfig) {
    throw "Refusing a plugin-local or test config.pro as startup proof: $configResolved"
}
if ($AllowTestConfig) {
    Write-Warning "TEST-ONLY validation: do not report this as Creo startup registration."
}

$dat = Get-Content -LiteralPath $registry -Raw
$execMatch = [regex]::Match($dat, '(?im)^\s*exec_file\s+(.+?)\s*$')
$textMatch = [regex]::Match($dat, '(?im)^\s*text_dir\s+(.+?)\s*$')
$nameMatch = [regex]::Match($dat, '(?im)^\s*name\s+(.+?)\s*$')
$allowStopMatch = [regex]::Match($dat, '(?im)^\s*allow_stop\s+(.+?)\s*$')
$startupMatch = [regex]::Match($dat, '(?im)^\s*startup\s+(.+?)\s*$')
$delayStartMatch = [regex]::Match($dat, '(?im)^\s*delay_start\s+(.+?)\s*$')
Require-True $execMatch.Success "protk.dat has exec_file"
Require-True $textMatch.Success "protk.dat has text_dir"
Require-True $nameMatch.Success "protk.dat has a stable application name"
Require-True ($allowStopMatch.Success -and $allowStopMatch.Groups[1].Value.Trim() -ieq "true") "protk.dat enables allow_stop for automated live switching"
Require-True ($startupMatch.Success -and $startupMatch.Groups[1].Value.Trim() -ieq "dll") "protk.dat declares startup dll"
Require-True ($delayStartMatch.Success -and $delayStartMatch.Groups[1].Value.Trim() -ieq "false") "protk.dat disables delayed startup"

$execFile = if ($execMatch.Success) { $execMatch.Groups[1].Value.Trim().Trim('"') } else { "" }
$textDir = if ($textMatch.Success) { $textMatch.Groups[1].Value.Trim().Trim('"') } else { "" }
Require-True ([System.IO.Path]::IsPathRooted($execFile)) "exec_file is absolute"
Require-True (Test-Path -LiteralPath $execFile -PathType Leaf) "versioned DLL exists"
Require-True ([System.IO.Path]::IsPathRooted($textDir)) "text_dir is absolute"
Require-True (Test-Path -LiteralPath $textDir -PathType Container) "text_dir exists"

$sources = @(Get-ChildItem -LiteralPath $root -Recurse -File |
    Where-Object {
        $_.Extension -in @(".c", ".cpp") -and
        $_.Name -notmatch '\.bak|recovered'
    })
$sourceText = ($sources | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
Require-True ($sourceText -match 'ProCmdActionAdd\s*\(') "source registers Toolkit commands"
Require-True ($sourceText -match 'ProCmdDesignate\s*\(') "source designates localized command text"
Require-True ($sourceText -match 'ProMenubarMenuAdd\s*\(') "source creates a legacy parent menu"
Require-True ($sourceText -match 'ProMenubarmenuPushbuttonAdd\s*\(') "source adds legacy menu buttons"
Require-True ($sourceText -notmatch 'ProRibbonDefinitionfileLoad\s*\(') "source does not mix in Ribbon loading"
Require-True ($sourceText -match 'user_initialize\s*\(') "user_initialize is exported in source"
Require-True ($sourceText -match 'user_terminate\s*\(') "user_terminate is exported in source"

$messages = if (Test-Path -LiteralPath $textDir -PathType Container) {
    @(Get-ChildItem -LiteralPath $textDir -Recurse -File -Filter *.txt)
} else { @() }
Require-True ($messages.Count -gt 0) "a message file exists under text_dir"

$configText = Get-Content -LiteralPath $configResolved -Raw
$registryResolved = [System.IO.Path]::GetFullPath($registry)
$escaped = [regex]::Escape($registryResolved)
$count = ([regex]::Matches($configText, "(?im)^\s*protkdat\s+`"?$escaped`"?\s*$")).Count
Require-True ($count -eq 1) "effective config.pro has exactly one startup registration"
if ($AllowTestConfig) {
    Require-True $false "test config.pro cannot prove Creo automatic startup"
}

if ($failures.Count -gt 0) {
    Write-Output "Validation failed with $($failures.Count) issue(s)."
    exit 1
}
Write-Output "Legacy-menu Toolkit plugin validation passed."

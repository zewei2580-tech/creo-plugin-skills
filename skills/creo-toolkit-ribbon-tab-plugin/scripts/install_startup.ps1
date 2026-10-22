param(
    [Parameter(Mandatory = $true)]
    [string]$PluginRoot,

    [Parameter(Mandatory = $true)]
    [string]$ConfigPro,

    [string]$RegistryFile = "protk.dat",

    [switch]$EffectiveConfigConfirmed,

    [switch]$AllowTestConfig
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Get-DetectedEncoding {
    param([byte[]]$Bytes)

    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        return @{ Encoding = [System.Text.UTF8Encoding]::new($true); Offset = 3 }
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
        return @{ Encoding = [System.Text.UnicodeEncoding]::new($false, $true); Offset = 2 }
    }
    if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
        return @{ Encoding = [System.Text.UnicodeEncoding]::new($true, $true); Offset = 2 }
    }

    $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
    try {
        [void]$strictUtf8.GetString($Bytes)
        return @{ Encoding = [System.Text.UTF8Encoding]::new($false); Offset = 0 }
    }
    catch {
        return @{ Encoding = [System.Text.Encoding]::Default; Offset = 0 }
    }
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

if (-not (Test-Path -LiteralPath $PluginRoot -PathType Container)) {
    throw "Plugin root not found: $PluginRoot"
}
if (-not (Test-Path -LiteralPath $ConfigPro -PathType Leaf)) {
    throw "Effective config.pro not found: $ConfigPro"
}
if (-not $EffectiveConfigConfirmed) {
    throw "Refusing to register an unconfirmed config.pro. Prove that Creo reads this file at startup, then pass -EffectiveConfigConfirmed."
}

$root = Get-NormalizedDirectory (Resolve-Path -LiteralPath $PluginRoot).Path
$registry = Join-Path $root $RegistryFile
if (-not (Test-Path -LiteralPath $registry -PathType Leaf)) {
    throw "Toolkit registry file not found: $registry"
}
$registry = [System.IO.Path]::GetFullPath($registry)
$config = (Resolve-Path -LiteralPath $ConfigPro).Path
if (-not [string]::Equals(
        [System.IO.Path]::GetFileName($config),
        "config.pro",
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
    throw "Startup registration target must be a file named config.pro: $config"
}

$isInsidePluginRoot = Test-IsPathWithin -Candidate $config -Directory $root
$isTestLikePath = $config -match '(?i)[\\/](?:tests?|fixtures?|samples?)[\\/]'
if (($isInsidePluginRoot -or $isTestLikePath) -and -not $AllowTestConfig) {
    throw "Refusing a plugin-local or test config.pro as startup proof: $config. Pass the actual Creo startup config.pro."
}
if ($AllowTestConfig) {
    Write-Warning "TEST-ONLY registration: this config.pro must not be reported as Creo startup registration."
}

$registryText = Get-Content -LiteralPath $registry -Raw
if ($registryText -notmatch '(?im)^\s*startup\s+dll\s*$') {
    throw "protk.dat must declare 'startup dll' for automatic startup: $registry"
}
if ($registryText -notmatch '(?im)^\s*delay_start\s+false\s*$') {
    throw "protk.dat must declare 'delay_start false' for immediate Creo startup loading: $registry"
}

$configDirectory = Split-Path -Parent $config
$bytes = [System.IO.File]::ReadAllBytes($config)
$detected = Get-DetectedEncoding $bytes
$text = $detected.Encoding.GetString($bytes, $detected.Offset, $bytes.Length - $detected.Offset)
$lines = @($text -split "\r?\n")

$kept = [System.Collections.Generic.List[string]]::new()
foreach ($line in $lines) {
    if ($line -match '^\s*protkdat\s+(.+?)\s*$') {
        $rawPath = $Matches[1].Trim().Trim('"')
        try {
            $entryPath = if ([System.IO.Path]::IsPathRooted($rawPath)) {
                [System.IO.Path]::GetFullPath($rawPath)
            }
            else {
                [System.IO.Path]::GetFullPath((Join-Path $configDirectory $rawPath))
            }
            $entryRoot = Get-NormalizedDirectory (Split-Path -Parent $entryPath)
            if ([string]::Equals($entryRoot, $root, [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }
        }
        catch {
            # Preserve malformed or environment-dependent entries outside this plugin.
        }
    }
    $kept.Add($line)
}

while ($kept.Count -gt 0 -and [string]::IsNullOrWhiteSpace($kept[$kept.Count - 1])) {
    $kept.RemoveAt($kept.Count - 1)
}
$kept.Add("protkdat $registry")
$newText = [string]::Join("`r`n", $kept) + "`r`n"
$backup = $null

if ($newText -ne $text) {
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
    $backup = "$config.before_creo_toolkit_startup_$stamp"
    Copy-Item -LiteralPath $config -Destination $backup -Force
    try {
        [System.IO.File]::WriteAllText($config, $newText, $detected.Encoding)
    }
    catch {
        Copy-Item -LiteralPath $backup -Destination $config -Force
        throw
    }
}

$verifyBytes = [System.IO.File]::ReadAllBytes($config)
$verifyDetected = Get-DetectedEncoding $verifyBytes
$verifyText = $verifyDetected.Encoding.GetString(
    $verifyBytes,
    $verifyDetected.Offset,
    $verifyBytes.Length - $verifyDetected.Offset
)
$escaped = [regex]::Escape($registry)
$count = ([regex]::Matches($verifyText, "(?im)^\s*protkdat\s+`"?$escaped`"?\s*$")).Count
if ($count -ne 1) {
    if ($null -ne $backup -and (Test-Path -LiteralPath $backup -PathType Leaf)) {
        Copy-Item -LiteralPath $backup -Destination $config -Force
    }
    throw "Startup registration verification failed; expected exactly one entry, found $count."
}

Write-Output "EFFECTIVE_CONFIG=$config"
if ($null -ne $backup) {
    Write-Output "BACKUP=$backup"
}
else {
    Write-Output "BACKUP=not-required"
}
Write-Output "REGISTRATION=protkdat $registry"
Write-Output "STARTUP_SCOPE=$(if ($AllowTestConfig) { 'TEST_ONLY' } else { 'CREO_STARTUP' })"

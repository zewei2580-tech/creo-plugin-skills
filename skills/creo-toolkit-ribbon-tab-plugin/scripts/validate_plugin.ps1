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

function Test-ToolkitMessageStructure {
    param([string]$Text)

    $normalized = $Text.TrimEnd("`r", "`n")
    if ([string]::IsNullOrWhiteSpace($normalized)) { return $false }
    $lines = @($normalized -split "\r?\n")
    if ($lines.Count % 4 -ne 0) { return $false }

    $seenKeys = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::Ordinal
    )
    for ($index = 0; $index -lt $lines.Count; $index += 4) {
        if ([string]::IsNullOrWhiteSpace($lines[$index]) -or
            [string]::IsNullOrWhiteSpace($lines[$index + 1]) -or
            [string]::IsNullOrWhiteSpace($lines[$index + 2]) -or
            $lines[$index + 3] -cne "#" -or
            -not $seenKeys.Add($lines[$index])) {
            return $false
        }
    }
    return $true
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
$applicationName = if ($nameMatch.Success) { $nameMatch.Groups[1].Value.Trim().Trim('"') } else { "" }
Require-True ([System.IO.Path]::IsPathRooted($execFile)) "exec_file is absolute"
Require-True (Test-Path -LiteralPath $execFile -PathType Leaf) "versioned DLL exists"
Require-True ([System.IO.Path]::IsPathRooted($textDir)) "text_dir is absolute"
Require-True (Test-Path -LiteralPath $textDir -PathType Container) "text_dir exists"

$sources = @(Get-ChildItem -LiteralPath $root -Recurse -File |
    Where-Object {
        $_.Extension -in @(".c", ".cpp") -and
        $_.Name -notmatch '\.bak|recovered' -and
        $_.FullName -notmatch '(?i)\\(?:archive|output)\\'
    })
$sourceText = ($sources | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }) -join "`n"
Require-True ($sourceText -match 'ProCmdActionAdd\s*\(') "source registers Toolkit commands"
Require-True ($sourceText -match 'ProCmdDesignate\s*\(') "source designates localized command text"
Require-True ($sourceText -match '\w+\s*=\s*ProCmdDesignate\s*\(') "source checks ProCmdDesignate return values"
Require-True ($sourceText -match '\w+\s*=\s*ProCmdIconSet\s*\(') "source checks ProCmdIconSet return values"
Require-True ($sourceText -match 'ProRibbonDefinitionfileLoad\s*\(') "source loads a Ribbon definition"
Require-True ($sourceText.IndexOf('ProCmdActionAdd', [System.StringComparison]::Ordinal) -lt $sourceText.IndexOf('ProRibbonDefinitionfileLoad', [System.StringComparison]::Ordinal)) "commands are registered before Ribbon load"
Require-True ($sourceText -match 'user_initialize\s*\(') "user_initialize is exported in source"
Require-True ($sourceText -match 'user_terminate\s*\(') "user_terminate is exported in source"

$ribbons = @()
if (Test-Path -LiteralPath $textDir -PathType Container) {
    $ribbons = @(Get-ChildItem -LiteralPath $textDir -Recurse -File -Filter *.rbn |
        Where-Object { $_.DirectoryName -match '(?i)\\ribbon$' })
}
Require-True ($ribbons.Count -gt 0) "a generated .rbn exists in a supported ribbon directory"

$ownerMarker = Join-Path $textDir "ribbon\ribbon_application_name.txt"
Require-True (Test-Path -LiteralPath $ownerMarker -PathType Leaf) "Ribbon application-name marker exists"
if (Test-Path -LiteralPath $ownerMarker -PathType Leaf) {
    $ribbonApplicationName = (Get-Content -LiteralPath $ownerMarker -Raw).Trim()
    Require-True ($ribbonApplicationName -ceq $applicationName) "protk.dat name matches the application that owns the generated Ribbon"
}

$messageRefMatches = @([regex]::Matches($sourceText, '(?i)L"([^"]+\.txt)"') |
    ForEach-Object { $_.Groups[1].Value } |
    Where-Object { $_ -match '(?i)(?:msg|message)' } |
    Sort-Object -Unique)
Require-True ($messageRefMatches.Count -gt 0) "source names its message file"
$messageText = ""
$localizedMessageTexts = @{
    chinese_cn = ""
    usascii = ""
}
foreach ($messageRef in $messageRefMatches) {
    $messagePath = Join-Path $textDir $messageRef
    Require-True (Test-Path -LiteralPath $messagePath -PathType Leaf) "referenced message file exists: $messageRef"
    if (-not (Test-Path -LiteralPath $messagePath -PathType Leaf)) { continue }

    $messageBytes = [System.IO.File]::ReadAllBytes($messagePath)
    $hasUtf8Bom = $messageBytes.Length -ge 3 -and
        $messageBytes[0] -eq 0xEF -and
        $messageBytes[1] -eq 0xBB -and
        $messageBytes[2] -eq 0xBF
    Require-True $hasUtf8Bom "message file uses UTF-8 BOM: $messageRef"
    try {
        $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
        $decoded = $strictUtf8.GetString($messageBytes).TrimStart([char]0xFEFF)
        Require-True $true "message file is valid UTF-8: $messageRef"
        Require-True (Test-ToolkitMessageStructure $decoded) "message file has strict key/text/translation/# records: $messageRef"
        $messageText += "`n$decoded"
    }
    catch {
        Require-True $false "message file is valid UTF-8: $messageRef"
    }

    foreach ($localeName in @("chinese_cn", "usascii")) {
        $localeMessagePath = Join-Path (Join-Path $textDir $localeName) $messageRef
        Require-True (Test-Path -LiteralPath $localeMessagePath -PathType Leaf) "deployed $localeName message file exists: $messageRef"
        if (-not (Test-Path -LiteralPath $localeMessagePath -PathType Leaf)) { continue }

        $localeMessageBytes = [System.IO.File]::ReadAllBytes($localeMessagePath)
        $localeHasUtf8Bom = $localeMessageBytes.Length -ge 3 -and
            $localeMessageBytes[0] -eq 0xEF -and
            $localeMessageBytes[1] -eq 0xBB -and
            $localeMessageBytes[2] -eq 0xBF
        Require-True $localeHasUtf8Bom "$localeName message file uses UTF-8 BOM: $messageRef"
        try {
            $strictLocaleUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
            $localeDecoded = $strictLocaleUtf8.GetString($localeMessageBytes).TrimStart([char]0xFEFF)
            Require-True $true "$localeName message file is valid UTF-8: $messageRef"
            Require-True (Test-ToolkitMessageStructure $localeDecoded) "$localeName message file has strict key/text/translation/# records: $messageRef"
            $localizedMessageTexts[$localeName] += "`n$localeDecoded"
        }
        catch {
            Require-True $false "$localeName message file is valid UTF-8: $messageRef"
        }
    }
}

$designationKeyDefs = @([regex]::Matches(
        $sourceText,
        '(?im)^\s*#define\s+(\w+_(?:LABEL|HELP|DESC)_KEY)\s+"([^"]+)"') |
    ForEach-Object {
        [pscustomobject]@{
            Macro = $_.Groups[1].Value
            Key = $_.Groups[2].Value
        }
    })
Require-True ($designationKeyDefs.Count -gt 0) "designation message keys are declared"
foreach ($keyDef in $designationKeyDefs) {
    $entryPattern = '(?ms)^' + [regex]::Escape($keyDef.Key) + '\r?\n([^\r\n]*)\r?\n([^\r\n]*)\r?\n#'
    $entryMatch = [regex]::Match($messageText, $entryPattern)
    Require-True $entryMatch.Success "message key resolves: $($keyDef.Key)"
    if ($entryMatch.Success -and $keyDef.Macro -match '_LABEL_KEY$') {
        $displayValues = @($entryMatch.Groups[1].Value, $entryMatch.Groups[2].Value)
        $hasChineseLabel = ($displayValues -join "") -match '[\u4e00-\u9fff]'
        $leaksInternalKey = @($displayValues | Where-Object {
                $_ -ceq $keyDef.Key -or $_ -match '^[A-Za-z_][A-Za-z0-9_.-]+$'
            }).Count -gt 0
        Require-True $hasChineseLabel "label key has a Chinese value: $($keyDef.Key)"
        Require-True (-not $leaksInternalKey) "label value is not an internal key: $($keyDef.Key)"
    }

    foreach ($localeName in @("chinese_cn", "usascii")) {
        $localeEntryMatch = [regex]::Match($localizedMessageTexts[$localeName], $entryPattern)
        Require-True $localeEntryMatch.Success "$localeName message key resolves: $($keyDef.Key)"
        if ($localeName -eq "chinese_cn" -and
            $localeEntryMatch.Success -and
            $keyDef.Macro -match '_LABEL_KEY$') {
            $localeDisplayValues = @(
                $localeEntryMatch.Groups[1].Value,
                $localeEntryMatch.Groups[2].Value
            )
            Require-True (($localeDisplayValues -join "") -match '[\u4e00-\u9fff]') "chinese_cn label key has a Chinese value: $($keyDef.Key)"
        }
    }
}

if ($sourceText -match 'ProCmdIconSet\s*\(') {
    $icons = @(Get-ChildItem -LiteralPath $textDir -Recurse -File |
        Where-Object { $_.Extension -eq ".png" })
    Require-True ($icons.Count -gt 0) "icon assets exist for ProCmdIconSet"
    $rawLiteralIconRefs = @([regex]::Matches($sourceText, '(?i)"([^"]+\.(?:png|ico))"') |
        ForEach-Object { $_.Groups[1].Value.ToLowerInvariant() })
    $literalIconRefs = @($rawLiteralIconRefs | Sort-Object -Unique)
    Require-True (@($literalIconRefs | Where-Object { [System.IO.Path]::GetExtension($_) -ne ".png" }).Count -eq 0) "Ribbon command icons use PNG, not ICO placeholders"
    $duplicateIconRefs = @($rawLiteralIconRefs | Group-Object | Where-Object { $_.Count -gt 1 })
    Require-True ($duplicateIconRefs.Count -eq 0) "literal icon references are unique per command"

    $resolvedSmallIcons = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($iconRef in $literalIconRefs) {
        $iconPath = Join-Path (Join-Path $textDir "resource") $iconRef
        Require-True (Test-Path -LiteralPath $iconPath -PathType Leaf) "referenced icon exists: $iconRef"
        if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) { continue }
        $iconFile = Get-Item -LiteralPath $iconPath
        $resolvedSmallIcons.Add($iconFile)

        $pngBytes = [System.IO.File]::ReadAllBytes($iconPath)
        $isPng = $pngBytes.Length -ge 24 -and
            $pngBytes[0] -eq 0x89 -and $pngBytes[1] -eq 0x50 -and
            $pngBytes[2] -eq 0x4E -and $pngBytes[3] -eq 0x47
        $width = if ($isPng) {
            [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($pngBytes, 16))
        } else { -1 }
        $height = if ($isPng) {
            [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($pngBytes, 20))
        } else { -1 }
        Require-True ($isPng -and $width -eq 16 -and $height -eq 16) "small icon is a native 16x16 PNG: $iconRef"

        $largeName = [System.IO.Path]::GetFileNameWithoutExtension($iconRef) + "_large.png"
        $largePath = Join-Path (Join-Path $textDir "resource") $largeName
        Require-True (Test-Path -LiteralPath $largePath -PathType Leaf) "32x32 companion exists: $largeName"
        if (Test-Path -LiteralPath $largePath -PathType Leaf) {
            $largeBytes = [System.IO.File]::ReadAllBytes($largePath)
            $largeIsPng = $largeBytes.Length -ge 24 -and
                $largeBytes[0] -eq 0x89 -and $largeBytes[1] -eq 0x50 -and
                $largeBytes[2] -eq 0x4E -and $largeBytes[3] -eq 0x47
            $largeWidth = if ($largeIsPng) {
                [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($largeBytes, 16))
            } else { -1 }
            $largeHeight = if ($largeIsPng) {
                [System.Net.IPAddress]::NetworkToHostOrder([BitConverter]::ToInt32($largeBytes, 20))
            } else { -1 }
            Require-True ($largeIsPng -and $largeWidth -eq 32 -and $largeHeight -eq 32) "large icon is a native 32x32 PNG: $largeName"
        }
    }

    $contentDuplicates = @($resolvedSmallIcons |
        ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                Hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
            }
        } |
        Group-Object Hash |
        Where-Object { $_.Count -gt 1 })
    Require-True ($contentDuplicates.Count -eq 0) "small icon artwork is byte-distinct"
}

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
Write-Output "Ribbon Toolkit plugin validation passed."

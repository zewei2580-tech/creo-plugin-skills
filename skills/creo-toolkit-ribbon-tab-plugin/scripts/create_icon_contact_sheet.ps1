param(
    [Parameter(Mandatory = $true)]
    [string]$IconDirectory,

    [Parameter(Mandatory = $true)]
    [string]$OutputPath,

    [int]$Columns = 6
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore

if (-not (Test-Path -LiteralPath $IconDirectory -PathType Container)) {
    throw "Icon directory not found: $IconDirectory"
}
if ($Columns -lt 1) {
    throw "Columns must be at least 1."
}

$icons = @(Get-ChildItem -LiteralPath $IconDirectory -Recurse -File |
    Where-Object { $_.Extension -in @(".png", ".ico") } |
    Sort-Object FullName)
if ($icons.Count -eq 0) {
    throw "No PNG or ICO files found under: $IconDirectory"
}

$cellWidth = 190
$cellHeight = 48
$rows = [int][Math]::Ceiling($icons.Count / [double]$Columns)
$bitmap = [System.Drawing.Bitmap]::new($cellWidth * $Columns, $cellHeight * $rows)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$font = [System.Drawing.Font]::new("Microsoft YaHei UI", 8)
$borderPen = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(225, 225, 225))
$textBrush = [System.Drawing.Brushes]::Black

try {
    $graphics.Clear([System.Drawing.Color]::White)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

    for ($i = 0; $i -lt $icons.Count; $i++) {
        $column = $i % $Columns
        $row = [int][Math]::Floor($i / [double]$Columns)
        $x = $column * $cellWidth
        $y = $row * $cellHeight
        $graphics.DrawRectangle($borderPen, $x, $y, $cellWidth - 1, $cellHeight - 1)

        $image = if ($icons[$i].Extension -ieq ".ico") {
            # WPF's decoder accepts modern compressed ICO payloads that
            # System.Drawing.Icon.ToBitmap can reject on Windows PowerShell.
            $bitmapImage = [System.Windows.Media.Imaging.BitmapImage]::new()
            $bitmapImage.BeginInit()
            $bitmapImage.UriSource = [Uri]$icons[$i].FullName
            $bitmapImage.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bitmapImage.EndInit()

            $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
            $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bitmapImage))
            $stream = [System.IO.MemoryStream]::new()
            try {
                $encoder.Save($stream)
                $stream.Position = 0
                $temporaryImage = [System.Drawing.Image]::FromStream($stream)
                try {
                    [System.Drawing.Bitmap]::new($temporaryImage)
                }
                finally {
                    $temporaryImage.Dispose()
                }
            }
            finally {
                $stream.Dispose()
            }
        }
        else {
            [System.Drawing.Image]::FromFile($icons[$i].FullName)
        }
        try {
            $graphics.DrawImage($image, $x + 12, $y + 16, 16, 16)
        }
        finally {
            $image.Dispose()
        }

        $label = $icons[$i].BaseName
        $graphics.DrawString($label, $font, $textBrush, $x + 38, $y + 15)
    }

    $outputDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($OutputPath))
    if (-not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }
    $bitmap.Save([System.IO.Path]::GetFullPath($OutputPath), [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $borderPen.Dispose()
    $font.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

Write-Output "Contact sheet: $([System.IO.Path]::GetFullPath($OutputPath))"

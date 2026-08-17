param(
    [int]$RuntimeSize = 32
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $repoRoot 'source-assets\icons'
$runtimeRoot = Join-Path $repoRoot 'workshop\Contents\mods\AuxiliasCrossbow\42.20\media\textures'

if ($RuntimeSize -ne 32) {
    throw "Project Zomboid hotbar icons must remain 32x32; requested $RuntimeSize."
}
if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
    throw "Icon source directory not found: $sourceRoot"
}
if (-not (Test-Path -LiteralPath $runtimeRoot -PathType Container)) {
    throw "Runtime texture directory not found: $runtimeRoot"
}

$icons = @(Get-ChildItem -LiteralPath $sourceRoot -Filter 'Item_Auxilia*.png' -File)
if ($icons.Count -ne 10) {
    throw "Expected 10 dedicated icon masters, found $($icons.Count)."
}

foreach ($icon in $icons) {
    $source = [System.Drawing.Bitmap]::new($icon.FullName)
    try {
        if ($source.Width -ne 128 -or $source.Height -ne 128) {
            throw "Dedicated icon master must be 128x128: $($icon.FullName)"
        }

        $runtime = [System.Drawing.Bitmap]::new(
            $RuntimeSize,
            $RuntimeSize,
            [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
        )
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($runtime)
            try {
                $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.Clear([System.Drawing.Color]::Transparent)
                $graphics.DrawImage($source, 0, 0, $RuntimeSize, $RuntimeSize)
            }
            finally {
                $graphics.Dispose()
            }

            $destination = Join-Path $runtimeRoot $icon.Name
            $runtime.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $runtime.Dispose()
        }
    }
    finally {
        $source.Dispose()
    }
}

Write-Host "Synchronized $($icons.Count) dedicated 128x128 icon masters as 32x32 runtime textures."

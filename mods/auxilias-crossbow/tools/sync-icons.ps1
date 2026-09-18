param(
    [int]$RuntimeSize = 32
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$monorepoRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot '..\..'))
$gameConfigPath = Join-Path $monorepoRoot 'config\project-zomboid.json'
$gameReleaseLine = [string]((Get-Content -LiteralPath $gameConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json).target.releaseLine)
if ($gameReleaseLine -notmatch '^\d+\.\d+$') {
    throw "Invalid central Project Zomboid release line: $gameReleaseLine"
}
$sourceRoot = Join-Path $repoRoot 'source-assets\icons'
$runtimeRoot = Join-Path $repoRoot "workshop\Contents\mods\AuxiliasCrossbow\$gameReleaseLine\media\textures"
$validationRoot = Join-Path $monorepoRoot 'work\icon-validation'

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
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None
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

$sheetOrder = @(
    'AuxiliaCrossbowBolt',
    'AuxiliaBrokenBolt',
    'AuxiliaStoneCrossbowBolt',
    'AuxiliaBrokenStoneBolt',
    'AuxiliaBoltShaft',
    'AuxiliaBoltHead',
    'AuxiliaStoneBoltHead',
    'AuxiliaImprovisedCrossbow',
    'AuxiliaReinforcedCrossbow',
    'AuxiliaHeavyArbalest'
)
$cellWidth = 180
$cellHeight = 210
$columns = 5
$rows = 2
$sheet = [System.Drawing.Bitmap]::new(
    $cellWidth * $columns,
    $cellHeight * $rows,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
)
try {
    $graphics = [System.Drawing.Graphics]::FromImage($sheet)
    $font = [System.Drawing.Font]::new('Segoe UI', 10)
    $labelBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(235, 240, 240, 240))
    try {
        $graphics.Clear([System.Drawing.Color]::FromArgb(255, 38, 43, 46))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        for ($index = 0; $index -lt $sheetOrder.Count; $index++) {
            $name = $sheetOrder[$index]
            $runtimePath = Join-Path $runtimeRoot "Item_$name.png"
            $runtime = [System.Drawing.Bitmap]::new($runtimePath)
            try {
                $column = $index % $columns
                $row = [math]::Floor($index / $columns)
                $left = $column * $cellWidth
                $top = $row * $cellHeight
                $graphics.DrawImage($runtime, $left + 26, $top + 8, 128, 128)
                $graphics.DrawImageUnscaled($runtime, $left + 8, $top + 144)
                $graphics.DrawString($name, $font, $labelBrush, $left + 8, $top + 181)
            }
            finally {
                $runtime.Dispose()
            }
        }
    }
    finally {
        $labelBrush.Dispose()
        $font.Dispose()
        $graphics.Dispose()
    }

    New-Item -ItemType Directory -Force -Path $validationRoot | Out-Null
    $sheetPath = Join-Path $validationRoot 'icons-32px-contact-sheet.png'
    $sheet.Save($sheetPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $sheet.Dispose()
}

Write-Host "Synchronized $($icons.Count) dedicated 128x128 icon masters as 32x32 runtime textures."
Write-Host "Wrote native and nearest-neighbor 4x icon comparison sheet: $sheetPath"

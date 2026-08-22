param([string[]]$Mod)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\Monorepo.psm1') -Force
Add-Type -AssemblyName System.Drawing

function Save-SquarePng {
    param(
        [Parameter(Mandatory)] [System.Drawing.Image]$Source,
        [Parameter(Mandatory)] [int]$Size,
        [Parameter(Mandatory)] [string]$Destination
    )

    $bitmap = [System.Drawing.Bitmap]::new(
        $Size,
        $Size,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.DrawImage($Source, 0, 0, $Size, $Size)
        }
        finally {
            $graphics.Dispose()
        }
        $parent = Split-Path -Parent $Destination
        if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        $bitmap.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $bitmap.Dispose()
    }
}

$repoRoot = Get-MonorepoRoot
$branding = Get-Content -LiteralPath (Join-Path $repoRoot 'shared\branding\brand.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$projects = @(Get-ModProjects -Mod $Mod)

foreach ($project in $projects) {
    $sourcePath = Join-Path $project.FullPath $project.coverSource
    $source = [System.Drawing.Image]::FromFile($sourcePath)
    try {
        if ($source.Width -ne $source.Height -or $source.Width -lt [int]$branding.sourceCanvas) {
            throw "Cover source must be square and at least $($branding.sourceCanvas)px: $sourcePath"
        }

        $workshopRoot = Join-Path $project.FullPath 'workshop'
        $modRoot = Join-Path $workshopRoot "Contents\mods\$($project.modId)"
        $outputPath = Join-Path $workshopRoot 'preview.png'
        Save-SquarePng -Source $source -Size ([int]$branding.outputCanvas) -Destination $outputPath
        Copy-Item -LiteralPath $outputPath -Destination (Join-Path $modRoot 'poster.png') -Force
        Copy-Item -LiteralPath $outputPath -Destination (Join-Path $modRoot 'icon.png') -Force

        $previewRoot = Join-Path $project.FullPath 'work\branding'
        foreach ($previewSize in @($branding.previewSizes)) {
            Save-SquarePng -Source $source -Size ([int]$previewSize) -Destination (Join-Path $previewRoot "$($project.slug)-$previewSize.png")
        }
    }
    finally {
        $source.Dispose()
    }
    Write-Host "Synchronized Workshop art for $($project.slug) and rendered 128/64/32px review previews."
}

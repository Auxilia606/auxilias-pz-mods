param([string[]]$Mod)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'lib\Monorepo.psm1') -Force

function Get-PngSize {
    param([Parameter(Mandatory)] [string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "PNG file not found: $Path"
    }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 24 -or $bytes[0] -ne 137 -or $bytes[1] -ne 80 -or $bytes[2] -ne 78 -or $bytes[3] -ne 71) {
        throw "File is not a valid PNG: $Path"
    }
    $width = ([int]$bytes[16] -shl 24) -bor ([int]$bytes[17] -shl 16) -bor ([int]$bytes[18] -shl 8) -bor [int]$bytes[19]
    $height = ([int]$bytes[20] -shl 24) -bor ([int]$bytes[21] -shl 16) -bor ([int]$bytes[22] -shl 8) -bor [int]$bytes[23]
    return [pscustomobject]@{ Width = $width; Height = $height }
}

$repoRoot = Get-MonorepoRoot
$target = Get-GameTarget
$projects = @(Get-ModProjects -Mod $Mod)
$branding = Get-Content -LiteralPath (Join-Path $repoRoot 'shared\branding\brand.json') -Raw | ConvertFrom-Json
$expectedPreviewSizes = @(128, 64, 32)
if ((@($branding.previewSizes) -join ',') -ne ($expectedPreviewSizes -join ',')) {
    throw "Brand review previews must remain 128, 64, and 32px; found $(@($branding.previewSizes) -join ', ')."
}
if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'tools\sync-workshop-art.ps1') -PathType Leaf)) {
    throw 'Workshop-art synchronization tool is missing.'
}

$allProjects = @(Get-ModProjects)
foreach ($property in @('slug', 'modId', 'path', 'packageName', 'releaseTagPrefix')) {
    $duplicates = @($allProjects | Group-Object -Property $property | Where-Object Count -gt 1)
    if ($duplicates.Count -gt 0) {
        throw "Duplicate $property in config/mods.json: $($duplicates.Name -join ', ')"
    }
}

$registeredPaths = @($allProjects.path | ForEach-Object { $_.Replace('/', '\').TrimEnd('\') })
$unregistered = @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'mods') -Directory | Where-Object {
    $relative = [System.IO.Path]::GetRelativePath($repoRoot, $_.FullName).TrimEnd('\')
    $relative -notin $registeredPaths
})
if ($unregistered.Count -gt 0) {
    throw "Unregistered mod directories: $($unregistered.Name -join ', ')"
}

foreach ($project in $projects) {
    Write-Host "Validating $($project.slug) against Project Zomboid $($target.testedBuild)..."
    if (-not (Test-Path -LiteralPath $project.FullPath -PathType Container)) {
        throw "Mod project directory not found: $($project.FullPath)"
    }

    $versionPath = Join-Path $project.FullPath 'VERSION'
    $version = (Get-Content -LiteralPath $versionPath -Raw).Trim()
    if ($version -notmatch '^\d+\.\d+\.\d+$') {
        throw "Invalid semantic version for $($project.slug): $version"
    }

    $workshopRoot = Join-Path $project.FullPath 'workshop'
    $modRoot = Join-Path $workshopRoot "Contents\mods\$($project.modId)"
    $versionRoot = Join-Path $modRoot $target.releaseLine
    foreach ($requiredDirectory in @($workshopRoot, $modRoot, $versionRoot)) {
        if (-not (Test-Path -LiteralPath $requiredDirectory -PathType Container)) {
            throw "Required $($project.slug) directory not found: $requiredDirectory"
        }
    }

    foreach ($metadataPath in @((Join-Path $modRoot 'mod.info'), (Join-Path $versionRoot 'mod.info'))) {
        $metadata = Get-Content -LiteralPath $metadataPath -Raw
        if ($metadata -notmatch "(?m)^id=$([regex]::Escape($project.modId))\r?$") {
            throw "mod.info id does not match config/mods.json: $metadataPath"
        }
        if ($metadata -notmatch "(?m)^versionMin=$([regex]::Escape($target.releaseLine))\r?$") {
            throw "mod.info versionMin must match central releaseLine $($target.releaseLine): $metadataPath"
        }
        if ($metadata -notmatch [regex]::Escape("Version $version")) {
            throw "mod.info does not contain Version ${version}: $metadataPath"
        }
    }

    $outputImages = @(
        (Join-Path $workshopRoot 'preview.png'),
        (Join-Path $modRoot 'poster.png'),
        (Join-Path $modRoot 'icon.png')
    )
    $hashes = foreach ($imagePath in $outputImages) {
        $size = Get-PngSize -Path $imagePath
        if ($size.Width -ne $branding.outputCanvas -or $size.Height -ne $branding.outputCanvas) {
            throw "Workshop image must be $($branding.outputCanvas)x$($branding.outputCanvas): $imagePath is $($size.Width)x$($size.Height)"
        }
        (Get-FileHash -LiteralPath $imagePath -Algorithm SHA256).Hash
    }
    if (@($hashes | Select-Object -Unique).Count -ne 1) {
        throw "preview.png, poster.png, and icon.png must be identical for $($project.slug)."
    }

    $coverSource = Join-Path $project.FullPath $project.coverSource
    $sourceSize = Get-PngSize -Path $coverSource
    if ($sourceSize.Width -ne $sourceSize.Height -or $sourceSize.Width -lt $branding.sourceCanvas) {
        throw "Cover source must be square and at least $($branding.sourceCanvas)px: $coverSource is $($sourceSize.Width)x$($sourceSize.Height)"
    }

    foreach ($mapping in @($project.sharedLua)) {
        $source = Join-Path (Join-Path $repoRoot 'shared\lua') $mapping.source
        $destination = Join-Path $versionRoot $mapping.destination
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
            throw "Shared Lua mapping is incomplete for $($project.slug): $($mapping.source) -> $($mapping.destination)"
        }
        if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash) {
            throw "Shared Lua is out of sync for $($project.slug): $($mapping.source)"
        }
    }

    $requiredTools = @('validate.ps1', 'package.ps1', 'deploy.ps1')
    foreach ($toolName in $requiredTools) {
        $toolPath = Join-Path $project.FullPath "tools\$toolName"
        if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) {
            throw "Required mod tool not found: $toolPath"
        }
    }
    $modValidator = Join-Path $project.FullPath 'tools\validate.ps1'
    & $modValidator
}

Write-Host "Monorepo validation passed for $($projects.Count) mod(s); target Project Zomboid $($target.testedBuild)."

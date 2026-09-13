param()

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot '..\..'))
$gameConfigPath = Join-Path $repoRoot 'config\project-zomboid.json'
$registryPath = Join-Path $repoRoot 'config\mods.json'
$target = (Get-Content -LiteralPath $gameConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json).target
$releaseLine = [string]$target.releaseLine
if ($releaseLine -notmatch '^\d+\.\d+$') {
    throw "Invalid central Project Zomboid release line: $releaseLine"
}

$registeredMods = @((Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json).mods |
    Where-Object { $_.slug -eq 'auxilias-qol' })
if ($registeredMods.Count -ne 1) {
    throw "Expected one auxilias-qol entry in config/mods.json; found $($registeredMods.Count)."
}
$project = $registeredMods[0]
if ($project.modId -ne 'AuxiliasQoL' -or $project.packageName -ne 'AuxiliasQoL' -or
    $project.path -ne 'mods/auxilias-qol' -or $project.releaseTagPrefix -ne 'auxilias-qol/v') {
    throw 'AuxiliasQoL registration fields do not match this mod project.'
}

$modRoot = Join-Path $projectRoot 'workshop\Contents\mods\AuxiliasQoL'
$versionRoot = Join-Path $modRoot $releaseLine
$requiredDirectories = @(
    (Join-Path $projectRoot 'docs'),
    (Join-Path $projectRoot 'source-assets'),
    (Join-Path $versionRoot 'media')
)
foreach ($path in $requiredDirectories) {
    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        throw "Missing required mod directory: $path"
    }
}

$versionPath = Join-Path $projectRoot 'VERSION'
$workshopMetadataPath = Join-Path $projectRoot 'workshop\workshop.txt'
$modMetadataPaths = @((Join-Path $modRoot 'mod.info'), (Join-Path $versionRoot 'mod.info'))
$requiredFiles = @(
    (Join-Path $projectRoot 'README.md'),
    (Join-Path $projectRoot 'CHANGELOG.md'),
    $versionPath,
    $workshopMetadataPath,
    (Join-Path $projectRoot 'workshop\preview.png'),
    (Join-Path $modRoot 'icon.png'),
    (Join-Path $modRoot 'poster.png'),
    (Join-Path $versionRoot 'icon.png'),
    (Join-Path $versionRoot 'poster.png')
) + $modMetadataPaths
foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Missing required mod file: $path"
    }
}

$version = (Get-Content -LiteralPath $versionPath -Raw -Encoding UTF8).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Invalid VERSION: $version"
}
$workshopMetadata = Get-Content -LiteralPath $workshopMetadataPath -Raw -Encoding UTF8
if ($workshopMetadata -notmatch [regex]::Escape("Version $version")) {
    throw "Workshop metadata does not contain Version ${version}: $workshopMetadataPath"
}
if ($workshopMetadata -notmatch "(?m)^title=$([regex]::Escape($project.displayName))\r?$") {
    throw "Workshop title does not match config/mods.json: $workshopMetadataPath"
}

foreach ($metadataPath in $modMetadataPaths) {
    $metadata = Get-Content -LiteralPath $metadataPath -Raw -Encoding UTF8
    if ($metadata -notmatch '(?m)^id=AuxiliasQoL\r?$' -or
        $metadata -notmatch "(?m)^name=$([regex]::Escape($project.displayName))\r?$") {
        throw "Mod identity does not match config/mods.json: $metadataPath"
    }
    if ($metadata -notmatch "(?m)^versionMin=$([regex]::Escape($releaseLine))\r?$") {
        throw "Mod minimum game version does not match the central release line: $metadataPath"
    }
    if ($metadata -notmatch [regex]::Escape("Version $version")) {
        throw "Mod metadata does not contain Version ${version}: $metadataPath"
    }
    foreach ($imageName in @('icon.png', 'poster.png')) {
        if ($metadata -notmatch "(?m)^$([regex]::Escape($imageName.Split('.')[0]))=$([regex]::Escape($imageName))\r?$") {
            throw "Mod metadata is missing $imageName reference: $metadataPath"
        }
    }
}

Write-Host "AuxiliasQoL skeleton validation passed for Project Zomboid $releaseLine (mod $version)."

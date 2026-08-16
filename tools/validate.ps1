$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$modRoot = Join-Path $repoRoot 'workshop\Contents\mods\AuxiliasCrossbow'
$versionRoot = Join-Path $modRoot '42.20'

$requiredFiles = @(
    (Join-Path $modRoot 'mod.info'),
    (Join-Path $versionRoot 'mod.info'),
    (Join-Path $versionRoot 'media\registries.lua'),
    (Join-Path $versionRoot 'media\scripts\auxilia_items.txt'),
    (Join-Path $versionRoot 'media\scripts\auxilia_recipes.txt'),
    (Join-Path $versionRoot 'media\scripts\auxilia_models.txt'),
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaImprovisedCrossbow.fbx'),
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaReinforcedCrossbow.fbx'),
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaHeavyArbalest.fbx'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaImprovisedCrossbow.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaCrossbowBolt.png')
)

$missing = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
    throw "Missing required mod files:`n$($missing -join "`n")"
}

$jsonFiles = Get-ChildItem -LiteralPath (Join-Path $versionRoot 'media\lua\shared\Translate') -Recurse -Filter '*.json'
foreach ($jsonFile in $jsonFiles) {
    Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json | Out-Null
}

$itemsText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\scripts\auxilia_items.txt') -Raw
foreach ($itemName in @('ImprovisedCrossbow', 'ReinforcedCrossbow', 'HeavyArbalest', 'AuxiliasCrossbowBolt')) {
    if ($itemsText -notmatch [regex]::Escape($itemName)) {
        throw "Item definition not found: $itemName"
    }
}

$openBraces = ([regex]::Matches($itemsText, '\{')).Count
$closeBraces = ([regex]::Matches($itemsText, '\}')).Count
if ($openBraces -ne $closeBraces) {
    throw "Unbalanced braces in auxilia_items.txt"
}

Write-Host "Validation passed: $($requiredFiles.Count) required files, $($jsonFiles.Count) translation files."


$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$monorepoRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot '..\..'))
$gameConfigPath = Join-Path $monorepoRoot 'config\project-zomboid.json'
if (-not (Test-Path -LiteralPath $gameConfigPath -PathType Leaf)) {
    throw "Central Project Zomboid version configuration not found: $gameConfigPath"
}
$gameTarget = (Get-Content -LiteralPath $gameConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json).target
$gameReleaseLine = [string]$gameTarget.releaseLine
if ($gameReleaseLine -notmatch '^\d+\.\d+$') {
    throw "Invalid central Project Zomboid release line: $gameReleaseLine"
}
$modRoot = Join-Path $repoRoot 'workshop\Contents\mods\AuxiliasCrossbow'
$versionRoot = Join-Path $modRoot $gameReleaseLine

$requiredFiles = @(
    (Join-Path $modRoot 'mod.info'),
    (Join-Path $modRoot 'poster.png'),
    (Join-Path $modRoot 'icon.png'),
    (Join-Path $versionRoot 'mod.info'),
    (Join-Path $versionRoot 'poster.png'),
    (Join-Path $versionRoot 'icon.png'),
    (Join-Path $versionRoot 'media\registries.lua'),
    (Join-Path $versionRoot 'media\scripts\auxilia_items.txt'),
    (Join-Path $versionRoot 'media\scripts\auxilia_recipes.txt'),
    (Join-Path $versionRoot 'media\scripts\auxilia_models.txt'),
    (Join-Path $versionRoot 'media\lua\shared\AuxiliaCrossbow_Crafting.lua'),
    (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_AmmoSelection.lua'),
    (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_ModelState.lua'),
    (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_FirearmEffects.lua'),
    (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_TestKit.lua'),
    (Join-Path $versionRoot 'media\lua\server\AuxiliaCrossbow_Loot.lua'),
    (Join-Path $versionRoot 'media\lua\server\AuxiliaCrossbow_Recovery.lua'),
    (Join-Path $versionRoot 'media\lua\shared\AuxiliaCrossbow_Reload.lua'),
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaImprovisedCrossbow.fbx'),
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaReinforcedCrossbow.fbx'),
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaHeavyArbalest.fbx'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaImprovisedCrossbow.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaCrossbowBolt.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaStoneCrossbowBolt.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaBrokenBolt.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaBrokenStoneBolt.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaReinforcedCrossbow.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaHeavyArbalest.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaBoltShaft.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaBoltHead.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaStoneBoltHead.png'),
    (Join-Path $versionRoot 'media\textures\weapons\2handed\AuxiliaCrossbowAtlas.png'),
    (Join-Path $repoRoot 'docs\VANILLA-RECIPE-ALIGNMENT.md')
)

$modelNames = @(
    'AuxiliaImprovisedCrossbow',
    'AuxiliaImprovisedCrossbowCocked',
    'AuxiliaImprovisedCrossbowCockedStoneBolt',
    'AuxiliaReinforcedCrossbow',
    'AuxiliaReinforcedCrossbowCocked',
    'AuxiliaReinforcedCrossbowCockedStoneBolt',
    'AuxiliaHeavyArbalest',
    'AuxiliaHeavyArbalestCocked',
    'AuxiliaHeavyArbalestCockedStoneBolt',
    'AuxiliaCrossbowBolt',
    'AuxiliaStoneCrossbowBolt',
    'AuxiliaBrokenBolt',
    'AuxiliaBrokenStoneBolt',
    'AuxiliaBoltShaft',
    'AuxiliaBoltHead',
    'AuxiliaStoneBoltHead'
)

foreach ($modelName in $modelNames) {
    $requiredFiles += Join-Path $versionRoot "media\models_X\weapons\2handed\$modelName.fbx"
}

$missing = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
    throw "Missing required mod files:`n$($missing -join "`n")"
}

$obsoleteMuzzleFlashScript = Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_MuzzleFlash.lua'
if (Test-Path -LiteralPath $obsoleteMuzzleFlashScript) {
    throw "Obsolete aimed-hand ballistics workaround must be removed: $obsoleteMuzzleFlashScript"
}

$translationRoot = Join-Path $versionRoot 'media\lua\shared\Translate'
$translationFiles = @('ContextMenu.json', 'ItemName.json', 'Recipes.json')
foreach ($language in @('EN', 'KO')) {
    foreach ($translationFile in $translationFiles) {
        $requiredTranslation = Join-Path $translationRoot "$language\$translationFile"
        if (-not (Test-Path -LiteralPath $requiredTranslation -PathType Leaf)) {
            throw "Required translation file is missing: $requiredTranslation"
        }
    }
}

$jsonFiles = Get-ChildItem -LiteralPath $translationRoot -Recurse -Filter '*.json'
foreach ($jsonFile in $jsonFiles) {
    $translation = Get-Content -LiteralPath $jsonFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($property in $translation.PSObject.Properties) {
        if ($property.Value -isnot [string] -or [string]::IsNullOrWhiteSpace($property.Value)) {
            throw "Translation value must be a non-empty string: $($jsonFile.FullName) -> $($property.Name)"
        }
    }
}

foreach ($translationFile in $translationFiles) {
    $english = Get-Content -LiteralPath (Join-Path $translationRoot "EN\$translationFile") -Raw -Encoding UTF8 | ConvertFrom-Json
    $korean = Get-Content -LiteralPath (Join-Path $translationRoot "KO\$translationFile") -Raw -Encoding UTF8 | ConvertFrom-Json
    $keyDifference = @(Compare-Object $english.PSObject.Properties.Name $korean.PSObject.Properties.Name)
    if ($keyDifference.Count -gt 0) {
        throw "English/Korean translation keys differ in $translationFile`: $($keyDifference.InputObject -join ', ')"
    }
}

$englishRecipes = Get-Content -LiteralPath (Join-Path $translationRoot 'EN\Recipes.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$expectedEnglishRecipeNames = @{
    ShapeBoltHead = 'Shape Metal Crossbow Bolt Head from Nail'
    KnappBoltHeads = 'Knap Stone Crossbow Bolt Heads'
    CarveBoltShaftBatch = 'Carve 5 Crossbow Bolt Shafts'
    MakeStandardBoltsBatch = 'Assemble 5 Metal Crossbow Bolts'
    MakeStoneBoltBatch = 'Assemble 5 Stone Crossbow Bolts'
    RepairLightCrossbow = 'Repair Light Crossbow'
    RepairCrossbow = 'Repair Crossbow'
    RepairHeavyCrossbow = 'Repair Heavy Crossbow'
}
foreach ($recipeName in $expectedEnglishRecipeNames.Keys) {
    if ($englishRecipes.$recipeName -ne $expectedEnglishRecipeNames[$recipeName]) {
        throw "English recipe name is inconsistent: $recipeName -> $($englishRecipes.$recipeName)"
    }
}

$modelsText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\scripts\auxilia_models.txt') -Raw
if ($modelsText -notmatch '(?m)^\s*module\s+Base\s*$') {
    throw 'Weapon model scripts must be declared in module Base for WeaponSprite lookup.'
}

foreach ($removedEmbeddedToken in @(
    'AuxiliaCrossbowBoltEmbeddedAlt',
    'AuxiliaStoneCrossbowBoltEmbeddedAlt',
    'AuxiliaBrokenBoltEmbeddedAlt',
    'AuxiliaBrokenStoneBoltEmbeddedAlt',
    'attachment knife_head',
    'attachment knife_shoulder',
    'attachment knife_stomach',
    'attachment stomach',
    'attachment knife_in_back',
    'attachment meatcleaver_in_back'
)) {
    if ($modelsText.Contains($removedEmbeddedToken)) {
        throw "Removed live-zombie Bolt attachment remains in model scripts: $removedEmbeddedToken"
    }
}

foreach ($modelName in $modelNames) {
    $modelBlockPattern = "(?s)model\s+$([regex]::Escape($modelName))\s*\{.*?mesh\s*=\s*weapons/2handed/$([regex]::Escape($modelName)),.*?texture\s*=\s*weapons/2handed/AuxiliaCrossbowAtlas,.*?scale\s*=\s*0\.01,"
    if ($modelsText -notmatch $modelBlockPattern) {
        throw "Mesh/texture/scale model definition is incomplete: $modelName"
    }

    $fbxFile = Get-Item -LiteralPath (Join-Path $versionRoot "media\models_X\weapons\2handed\$modelName.fbx")
    if ($fbxFile.Length -lt 20000) {
        throw "FBX is unexpectedly small: $($fbxFile.FullName)"
    }
}

$crossbowModelNames = @(
    'AuxiliaImprovisedCrossbow',
    'AuxiliaImprovisedCrossbowCocked',
    'AuxiliaImprovisedCrossbowCockedStoneBolt',
    'AuxiliaReinforcedCrossbow',
    'AuxiliaReinforcedCrossbowCocked',
    'AuxiliaReinforcedCrossbowCockedStoneBolt',
    'AuxiliaHeavyArbalest',
    'AuxiliaHeavyArbalestCocked',
    'AuxiliaHeavyArbalestCockedStoneBolt'
)
foreach ($crossbowModelName in $crossbowModelNames) {
    $crossbowModelBlockPattern = "(?s)model\s+$([regex]::Escape($crossbowModelName))\s*\{.*?(?=\s*model\s+\w+\s*\{|\s*\}\s*\z)"
    $crossbowModelBlock = [regex]::Match($modelsText, $crossbowModelBlockPattern).Value
    if (-not $crossbowModelBlock -or $crossbowModelBlock -notmatch '(?s)attachment\s+world\s*\{.*?offset\s*=\s*0\.026\s+0\.10\s+0\.0,.*?rotate\s*=\s*0\.0\s+-90\.0\s+0\.0,') {
        throw "$crossbowModelName must lie top-side-up with enough world height to keep its prod above the ground."
    }
}

$modelTextureRoot = Join-Path $versionRoot 'media\textures\weapons\2handed'
$modelTextures = @(Get-ChildItem -LiteralPath $modelTextureRoot -Filter '*.png' -File)
if ($modelTextures.Count -ne 1 -or $modelTextures[0].Name -ne 'AuxiliaCrossbowAtlas.png') {
    throw 'Crossbow models must share the single AuxiliaCrossbowAtlas.png texture.'
}
if ($modelTextures[0].Length -lt 4096) {
    throw "Model texture is unexpectedly small or flat: $($modelTextures[0].FullName)"
}

$modelOpenBraces = ([regex]::Matches($modelsText, '\{')).Count
$modelCloseBraces = ([regex]::Matches($modelsText, '\}')).Count
if ($modelOpenBraces -ne $modelCloseBraces) {
    throw 'Unbalanced braces in auxilia_models.txt'
}

$blendSource = Join-Path $repoRoot 'source-assets\blender\AuxiliasCrossbowAssets.blend'
foreach ($authoringFile in @($blendSource,
    (Join-Path $repoRoot 'source-assets\blender\textures\AuxiliaCrossbowAtlas.png'),
    (Join-Path $repoRoot 'tools\export_assets.py'))) {
    if (-not (Test-Path -LiteralPath $authoringFile -PathType Leaf)) {
        throw "Editable Blender authoring file is missing: $authoringFile"
    }
}

$physicsReportPath = Join-Path $repoRoot 'work\model-validation\report.json'
if (Test-Path -LiteralPath $physicsReportPath) {
    $physicsReport = Get-Content -LiteralPath $physicsReportPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($physicsReport.authoring_schema -ne 2 -or -not $physicsReport.source_unchanged_by_export) {
        throw 'Model audit must come from the editable-source exporter.'
    }
    if ($physicsReport.source_sha256 -ne (Get-FileHash -LiteralPath $blendSource -Algorithm SHA256).Hash) {
        throw 'Blender source changed since its last export audit. Run tools/export_assets.py with Blender.'
    }
    foreach ($modelName in $modelNames) {
        $asset = $physicsReport.assets.$modelName
        $fbxPath = Join-Path $versionRoot "media\models_X\weapons\2handed\$modelName.fbx"
        if ($null -eq $asset -or -not $asset.fbx_geometry_and_uv_match -or $asset.collapsed_uv_triangles -ne 0) {
            throw "Model geometry/UV audit is missing or failed: $modelName"
        }
        if ($asset.fbx_sha256 -ne (Get-FileHash -LiteralPath $fbxPath -Algorithm SHA256).Hash) {
            throw "FBX differs from its source audit: $modelName"
        }
    }
    foreach ($componentName in @('AuxiliaBrokenBolt', 'AuxiliaBrokenStoneBolt', 'AuxiliaBoltShaft', 'AuxiliaBoltHead', 'AuxiliaStoneBoltHead')) {
        $component = $physicsReport.bolt_family.$componentName
        if ($null -eq $component -or -not $component.translation_only -or $component.shared_parts.Count -lt 1) {
            throw "Canonical bolt-family audit is missing: $componentName"
        }
    }
    $atlasPath = Join-Path $versionRoot 'media\textures\weapons\2handed\AuxiliaCrossbowAtlas.png'
    if ($physicsReport.atlas_sha256 -ne (Get-FileHash -LiteralPath $atlasPath -Algorithm SHA256).Hash) {
        throw 'Installed atlas differs from its source audit.'
    }
    foreach ($crossbowName in @('AuxiliaImprovisedCrossbow', 'AuxiliaReinforcedCrossbow', 'AuxiliaHeavyArbalest')) {
        $physics = $physicsReport.crossbow_physics.$crossbowName
        if ($null -eq $physics) {
            throw "Generated physics report is missing: $crossbowName"
        }
        if ([math]::Abs([double]$physics.string_length_delta) -gt 0.00001) {
            throw "Cocked string length changed for $crossbowName"
        }
        if ([math]::Abs([double]$physics.sampled_limb_length_delta) -gt 0.0002) {
            throw "Cocked limb arc length changed for $crossbowName"
        }
        if ([double]$physics.cocked_tip_y -ge [double]$physics.relaxed_tip_y) {
            throw "Cocked limbs do not bend rearward for $crossbowName"
        }
        if ([double]$physics.catch_y -ge [double]$physics.cocked_tip_y) {
            throw "Cocked string catch is not behind the limb tips for $crossbowName"
        }
        if ([math]::Abs([double]$physics.maximum_string_tip_center_offset) -gt 0.000001 -or [double]$physics.minimum_string_tip_vertical_clearance -lt 0.0005) {
            throw "String does not pass through the limb-tip nocks for $crossbowName"
        }
        if ([math]::Abs([double]$physics.loaded_bolt_axis_offset) -gt 0.000001) {
            throw "Loaded bolt leaves the prod/string power axis for $crossbowName"
        }
        if ([math]::Abs([double]$physics.string_nock_contact_gap) -gt 0.000001) {
            throw "Drawn string does not meet the rear nock face for $crossbowName"
        }
        foreach ($material in @('metal', 'stone')) {
            $clearance = $physics."${material}_bolt_channel_clearance"
            if ($null -eq $clearance -or [double]$clearance -lt 0.00015) {
                throw "$material bolt does not clear the tiller/groove for $crossbowName"
            }
        }
        if ([math]::Abs([double]$physics.metal_loaded_bolt_scale - 1.0) -gt 0.000001 -or [math]::Abs([double]$physics.stone_loaded_bolt_scale - 1.0) -gt 0.000001) {
            throw "Loaded bolts must retain the canonical loose-world scale for $crossbowName"
        }
        if ([math]::Abs([double]$physics.metal_world_loaded_dimension_delta) -gt 0.000001 -or [math]::Abs([double]$physics.stone_world_loaded_dimension_delta) -gt 0.000001) {
            throw "Loaded and loose-world bolt dimensions differ for $crossbowName"
        }
        if ([double]$physics.metal_loaded_point_overhang -lt 0.027 -or [double]$physics.metal_loaded_point_overhang -gt 0.033 -or [double]$physics.stone_loaded_point_overhang -lt 0.027 -or [double]$physics.stone_loaded_point_overhang -gt 0.033) {
            throw "Loaded bolt point overhang is outside the 27-33 mm target for $crossbowName"
        }
        if ([double]$physics.prod_tip_rise -lt 0.010 -or [double]$physics.prod_tip_rise -gt 0.020) {
            throw "Prod nocks do not rise gently from the embedded fore-end root for $crossbowName"
        }
        if ([double]$physics.fore_end_overhang -lt 0.004 -or [double]$physics.fore_end_overhang -gt 0.010) {
            throw "Tiller continues too far past the prod root for $crossbowName"
        }
        if ([double]$physics.power_axis_above_fore_end -lt 0.002 -or [double]$physics.power_axis_above_fore_end -gt 0.008) {
            throw "Bolt/string power axis is not just above the tiller fore-end for $crossbowName"
        }
    }
}

foreach ($boltModelName in @('AuxiliaCrossbowBolt', 'AuxiliaStoneCrossbowBolt', 'AuxiliaBrokenBolt', 'AuxiliaBrokenStoneBolt')) {
    $boltModelBlockPattern = "(?s)model\s+$([regex]::Escape($boltModelName))\s*\{.*?(?=\s*model\s+\w+\s*\{|\s*\}\s*\z)"
    $boltModelBlock = [regex]::Match($modelsText, $boltModelBlockPattern).Value
    if (-not $boltModelBlock -or $boltModelBlock -notmatch '(?s)attachment\s+world\s*\{.*?rotate\s*=\s*90\.0\s+0\.0\s+0\.0') {
        throw "$boltModelName must retain its 90-degree world attachment so its weapon-axis FBX rests flat."
    }
}

$itemsText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\scripts\auxilia_items.txt') -Raw
foreach ($componentCheck in @(
    @{ Item = 'BoltShaft'; Model = 'AuxiliaBoltShaft'; Height = '0.003' },
    @{ Item = 'BoltHead'; Model = 'AuxiliaBoltHead'; Height = '0.005' },
    @{ Item = 'StoneBoltHead'; Model = 'AuxiliaStoneBoltHead'; Height = '0.007' }
)) {
    $itemPattern = "(?s)item\s+$($componentCheck.Item)\s*\{[^}]*StaticModel\s*=\s*Base\.$($componentCheck.Model),[^}]*WorldStaticModel\s*=\s*Base\.$($componentCheck.Model),"
    if ($itemsText -notmatch $itemPattern) {
        throw "Crafting component must use its canonical static/world model: $($componentCheck.Item)"
    }
    $modelPattern = "(?s)model\s+$($componentCheck.Model)\s*\{.*?attachment\s+world\s*\{\s*offset\s*=\s*$([regex]::Escape($componentCheck.Height))\s+0\.0\s+0\.0,\s*rotate\s*=\s*0\.0\s+-90\.0\s+0\.0,"
    if ($modelsText -notmatch $modelPattern) {
        throw "Crafting component must retain its centered ground-contact attachment: $($componentCheck.Model)"
    }
}
foreach ($itemName in @('ImprovisedCrossbow', 'ReinforcedCrossbow', 'HeavyArbalest', 'AuxiliasCrossbowBolt', 'AuxiliasStoneCrossbowBolt', 'BoltShaft', 'BoltHead', 'StoneBoltHead', 'BrokenBolt', 'BrokenStoneBolt')) {
    if ($itemsText -notmatch [regex]::Escape($itemName)) {
        throw "Item definition not found: $itemName"
    }
}

$weaponModelChecks = @(
    @{ Item = 'ImprovisedCrossbow'; Model = 'AuxiliaImprovisedCrossbow' },
    @{ Item = 'ReinforcedCrossbow'; Model = 'AuxiliaReinforcedCrossbow' },
    @{ Item = 'HeavyArbalest'; Model = 'AuxiliaHeavyArbalest' }
)
foreach ($weaponCheck in $weaponModelChecks) {
    $itemBlockPattern = "(?s)item\s+$($weaponCheck.Item)\s*\{.*?AttachmentType\s*=\s*Shovel,.*?IsAimedFirearm\s*=\s*true,.*?IsAimedHandWeapon\s*=\s*true,.*?Ranged\s*=\s*true,.*?WeaponSprite\s*=\s*$($weaponCheck.Model),"
    if ($itemsText -notmatch $itemBlockPattern) {
        throw "Equipped model integration is incomplete: $($weaponCheck.Item)"
    }
}
if ($itemsText -match 'WeaponSprite\s*=\s*AuxiliasCrossbow\.') {
    throw 'WeaponSprite model names must be unqualified; model scripts are resolved from module Base.'
}
if ($itemsText -match 'MuzzleFlashModelKey') {
    throw 'Crossbows must not define a firearm muzzle-flash model.'
}
foreach ($iconCheck in @(
    @{ Item = 'ImprovisedCrossbow'; Icon = 'AuxiliaImprovisedCrossbow' },
    @{ Item = 'ReinforcedCrossbow'; Icon = 'AuxiliaReinforcedCrossbow' },
    @{ Item = 'HeavyArbalest'; Icon = 'AuxiliaHeavyArbalest' },
    @{ Item = 'AuxiliasCrossbowBolt'; Icon = 'AuxiliaCrossbowBolt' },
    @{ Item = 'BoltShaft'; Icon = 'AuxiliaBoltShaft' },
    @{ Item = 'BoltHead'; Icon = 'AuxiliaBoltHead' },
    @{ Item = 'StoneBoltHead'; Icon = 'AuxiliaStoneBoltHead' },
    @{ Item = 'AuxiliasStoneCrossbowBolt'; Icon = 'AuxiliaStoneCrossbowBolt' },
    @{ Item = 'BrokenBolt'; Icon = 'AuxiliaBrokenBolt' },
    @{ Item = 'BrokenStoneBolt'; Icon = 'AuxiliaBrokenStoneBolt' }
)) {
    $iconPattern = "(?s)item\s+$($iconCheck.Item)\s*\{.*?Icon\s*=\s*$($iconCheck.Icon),"
    if ($itemsText -notmatch $iconPattern) {
        throw "Dedicated crafting-component icon is not assigned: $($iconCheck.Item)"
    }
}

$iconSourceRoot = Join-Path $repoRoot 'source-assets\icons'
$runtimeIconHashes = @{}
foreach ($iconName in @(
    'AuxiliaImprovisedCrossbow',
    'AuxiliaReinforcedCrossbow',
    'AuxiliaHeavyArbalest',
    'AuxiliaCrossbowBolt',
    'AuxiliaStoneCrossbowBolt',
    'AuxiliaBrokenBolt',
    'AuxiliaBrokenStoneBolt',
    'AuxiliaBoltShaft',
    'AuxiliaBoltHead',
    'AuxiliaStoneBoltHead'
)) {
    $sourceIcon = Join-Path $iconSourceRoot "Item_$iconName.png"
    $runtimeIcon = Join-Path $versionRoot "media\textures\Item_$iconName.png"
    if (-not (Test-Path -LiteralPath $sourceIcon -PathType Leaf)) {
        throw "Dedicated source icon is missing: $sourceIcon"
    }
    $iconBytes = [System.IO.File]::ReadAllBytes($sourceIcon)
    if ($iconBytes.Length -lt 26 -or $iconBytes[0] -ne 137 -or $iconBytes[1] -ne 80 -or $iconBytes[2] -ne 78 -or $iconBytes[3] -ne 71) {
        throw "Dedicated source icon is not a valid PNG: $sourceIcon"
    }
    $iconWidth = ($iconBytes[16] -shl 24) -bor ($iconBytes[17] -shl 16) -bor ($iconBytes[18] -shl 8) -bor $iconBytes[19]
    $iconHeight = ($iconBytes[20] -shl 24) -bor ($iconBytes[21] -shl 16) -bor ($iconBytes[22] -shl 8) -bor $iconBytes[23]
    if ($iconWidth -ne 128 -or $iconHeight -ne 128) {
        throw "Dedicated source icon must be 128x128: $sourceIcon is ${iconWidth}x${iconHeight}"
    }
    if ($iconBytes[25] -notin @(4, 6)) {
        throw "Dedicated source icon must contain an alpha channel: $sourceIcon"
    }
    $runtimeIconBytes = [System.IO.File]::ReadAllBytes($runtimeIcon)
    $runtimeIconWidth = ($runtimeIconBytes[16] -shl 24) -bor ($runtimeIconBytes[17] -shl 16) -bor ($runtimeIconBytes[18] -shl 8) -bor $runtimeIconBytes[19]
    $runtimeIconHeight = ($runtimeIconBytes[20] -shl 24) -bor ($runtimeIconBytes[21] -shl 16) -bor ($runtimeIconBytes[22] -shl 8) -bor $runtimeIconBytes[23]
    if ($runtimeIconWidth -ne 32 -or $runtimeIconHeight -ne 32) {
        throw "Runtime icon must be 32x32 so it stays inside one hotbar slot: $runtimeIcon is ${runtimeIconWidth}x${runtimeIconHeight}"
    }
    if ($runtimeIconBytes[25] -notin @(4, 6)) {
        throw "Runtime icon must contain an alpha channel: $runtimeIcon"
    }
    $runtimeIconHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $runtimeIcon).Hash
    if ($runtimeIconHashes.ContainsKey($runtimeIconHash)) {
        throw "Dedicated runtime icons must remain distinct: $iconName duplicates $($runtimeIconHashes[$runtimeIconHash])"
    }
    $runtimeIconHashes[$runtimeIconHash] = $iconName
}

foreach ($boltAmmoCheck in @(
    @{ Item = 'AuxiliasCrossbowBolt'; AmmoType = 'auxiliascrossbow:bolt' },
    @{ Item = 'AuxiliasStoneCrossbowBolt'; AmmoType = 'auxiliascrossbow:stonebolt' }
)) {
    $boltItemName = $boltAmmoCheck.Item
    $boltItemPattern = "(?s)item\s+$boltItemName\s*\{.*?\}"
    $boltItemBlock = [regex]::Match($itemsText, $boltItemPattern).Value
    if (-not $boltItemBlock) {
        throw "Bolt item definition not found: $boltItemName"
    }
    if ($boltItemBlock -match 'base:ammo') {
        throw "$boltItemName must not use base:ammo; vanilla GatherGunpowder accepts every item with that tag."
    }
    if ($boltItemBlock -notmatch "AmmoType\s*=\s*$([regex]::Escape($boltAmmoCheck.AmmoType)),") {
        throw "$boltItemName must self-reference $($boltAmmoCheck.AmmoType) so Build 42 initializes its bullet-tracer configuration."
    }
}
foreach ($worldModelCheck in @(
    @{ Item = 'AuxiliasCrossbowBolt'; Model = 'AuxiliaCrossbowBolt' },
    @{ Item = 'AuxiliasStoneCrossbowBolt'; Model = 'AuxiliaStoneCrossbowBolt' },
    @{ Item = 'BrokenBolt'; Model = 'Base.AuxiliaBrokenBolt' },
    @{ Item = 'BrokenStoneBolt'; Model = 'Base.AuxiliaBrokenStoneBolt' }
)) {
    $worldModelPattern = "(?s)item\s+$($worldModelCheck.Item)\s*\{.*?WorldStaticModel\s*=\s*$([regex]::Escape($worldModelCheck.Model)),"
    if ($itemsText -notmatch $worldModelPattern) {
        throw "Material-specific world model is not assigned: $($worldModelCheck.Item) -> $($worldModelCheck.Model)"
    }
}

$recipesText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\scripts\auxilia_recipes.txt') -Raw

function Get-CraftRecipeBlock {
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [string] $Name
    )

    $nameMatch = [regex]::Match($Text, "\bcraftRecipe\s+$([regex]::Escape($Name))\b")
    if (-not $nameMatch.Success) {
        throw "Recipe definition not found: $Name"
    }

    $openBrace = $Text.IndexOf('{', $nameMatch.Index)
    if ($openBrace -lt 0) {
        throw "Recipe opening brace not found: $Name"
    }

    $depth = 0
    for ($index = $openBrace; $index -lt $Text.Length; $index++) {
        if ($Text[$index] -eq '{') {
            $depth++
        }
        elseif ($Text[$index] -eq '}') {
            $depth--
            if ($depth -eq 0) {
                return $Text.Substring($nameMatch.Index, $index - $nameMatch.Index + 1)
            }
        }
    }

    throw "Recipe closing brace not found: $Name"
}

foreach ($recipeName in @('MakeLightCrossbow', 'MakeCrossbow', 'MakeHeavyCrossbow', 'RepairLightCrossbow', 'RepairCrossbow', 'RepairHeavyCrossbow', 'CarveBoltShaft', 'CarveBoltShaftBatch', 'ShapeBoltHead', 'KnappBoltHeads', 'ForgeBoltHeads', 'MakeStandardBolts', 'MakeStandardBoltsBatch', 'MakeStoneBolt', 'MakeStoneBoltBatch', 'SalvageBrokenBolts', 'SalvageBrokenStoneBolt')) {
    if ($recipesText -notmatch [regex]::Escape("craftRecipe $recipeName")) {
        throw "Recipe definition not found: $recipeName"
    }
}

foreach ($recoveryRecipeName in @('SalvageBrokenBolts', 'SalvageBrokenStoneBolt')) {
    $recoveryRecipeBlock = Get-CraftRecipeBlock -Text $recipesText -Name $recoveryRecipeName
    if ($recoveryRecipeBlock -match 'timedAction\s*=\s*CraftKnifeSpear,') {
        throw "$recoveryRecipeName must not display Base.SpearKnife at full size."
    }
    if ($recoveryRecipeBlock -notmatch 'Broken(?:Stone)?Bolt\]\s+flags\[Prop2\]') {
        throw "$recoveryRecipeName must show its actual compact broken bolt as Prop2."
    }
    if ($recoveryRecipeBlock -notmatch 'mode:keep\s+flags\[[^\]]*Prop1[^\]]*MayDegradeVeryLight[^\]]*\]') {
        throw "$recoveryRecipeName must show its selected recovery tool as Prop1."
    }
}

$metalRecoveryRecipe = Get-CraftRecipeBlock -Text $recipesText -Name 'SalvageBrokenBolts'
if ($metalRecoveryRecipe -notmatch 'timedAction\s*=\s*MakingJewellery,') {
    throw 'Metal-head recovery must use the small-part MakingJewellery animation.'
}
$stoneRecoveryRecipe = Get-CraftRecipeBlock -Text $recipesText -Name 'SalvageBrokenStoneBolt'
if ($stoneRecoveryRecipe -notmatch 'timedAction\s*=\s*MakingJewellery,') {
    throw 'Stone-head recovery must use the compact MakingJewellery animation.'
}
if ($stoneRecoveryRecipe -notmatch 'tags\[base:sharpknife\]\s+mode:keep\s+flags\[Prop1;IsNotDull;MayDegradeVeryLight\]') {
    throw 'Stone-head recovery must cut away bindings with a non-dull sharp knife.'
}
if ($stoneRecoveryRecipe -match 'base:(?:hammerstone|mallet|knappingtool)') {
    throw 'Stone-head recovery must not strike the intact head with a knapping or hammering tool.'
}

foreach ($assemblyRecipeName in @('MakeStandardBolts', 'MakeStoneBolt')) {
    $assemblyRecipeBlock = Get-CraftRecipeBlock -Text $recipesText -Name $assemblyRecipeName
    if ($assemblyRecipeBlock -notmatch 'timedAction\s*=\s*MakingJewellery,') {
        throw "$assemblyRecipeName must use the small-part assembly animation."
    }
    if ($assemblyRecipeBlock -notmatch 'BoltShaft\]\s+flags\[Prop2\]') {
        throw "$assemblyRecipeName must show the compact bolt shaft rather than a spear."
    }
}

if ($recipesText -match 'CraftKnifeSpear') {
    throw 'Crossbow recipes must never invoke the spear-and-knife animation.'
}

$vanillaAlignedRecipeChecks = @(
    @{ Recipe = 'MakeLightCrossbow'; Patterns = @('time\s*=\s*600', 'xpAward\s*=\s*Woodwork:20;Carving:10;Maintenance:5', 'item\s+1\s+\[Base\.Plank\]') },
    @{ Recipe = 'MakeCrossbow'; Patterns = @('time\s*=\s*600', 'xpAward\s*=\s*Woodwork:40;Carving:15;Maintenance:10', 'OnTest\s*=\s*AuxiliaCrossbowCrafting\.canUseUpgradeItem', 'OnCreate\s*=\s*AuxiliaCrossbowCrafting\.finishUpgrade', 'item\s+1\s+\[AuxiliasCrossbow\.ImprovisedCrossbow\]\s+flags\[Prop2;InheritCondition\]', 'item\s+1\s+\[Base\.MetalBar\]', 'item\s+1\s+\[Base\.HandDrill;Base\.StoneDrill\]', 'tags\[base:screwdriver\]', 'tags\[base:pliers\]') },
    @{ Recipe = 'MakeHeavyCrossbow'; Patterns = @('time\s*=\s*900', 'Tags\s*=\s*AdvancedForge', 'NeedToBeLearn\s*=\s*true', 'AutoLearnAll\s*=\s*Maintenance:4;Blacksmith:6', 'timedAction\s*=\s*HammerMetalStanding', 'xpAward\s*=\s*Maintenance:10;Blacksmith:45', 'OnTest\s*=\s*AuxiliaCrossbowCrafting\.canUseUpgradeItem', 'OnCreate\s*=\s*AuxiliaCrossbowCrafting\.finishUpgrade', 'item\s+4\s+tags\[base:charcoal\]', 'item\s+1\s+\[AuxiliasCrossbow\.ReinforcedCrossbow\]\s+flags\[InheritCondition\]', 'item\s+1\s+\[Base\.SteelBarHalf\]', 'item\s+1\s+\[Base\.HandDrill;Base\.StoneDrill\]', 'tags\[base:ballpeenhammer\]', 'tags\[base:tongs\]') },
    @{ Recipe = 'RepairLightCrossbow'; Patterns = @('time\s*=\s*300', 'AllowBatchCraft\s*=\s*false', 'Tags\s*=\s*AnySurfaceCraft', 'category\s*=\s*Repair', 'SkillRequired\s*=\s*Woodwork:2;Carving:2;Maintenance:1', 'xpAward\s*=\s*Woodwork:10;Carving:5;Maintenance:5', 'OnTest\s*=\s*AuxiliaCrossbowCrafting\.canRepairItem', 'OnCreate\s*=\s*RecipeCodeOnCreate\.genericBetterFixing', 'Tooltip\s*=\s*Tooltip_Recipe_CanFailAndDamage', 'item\s+1\s+\[AuxiliasCrossbow\.ImprovisedCrossbow\]\s+mode:keep\s+flags\[Prop2;IsDamaged\]', 'item\s+1\s+\[Base\.WoodenStick2\]', 'item\s+1\s+\[Base\.Twine\]', 'item\s+2\s+\[Base\.Nails\]') },
    @{ Recipe = 'RepairCrossbow'; Patterns = @('time\s*=\s*450', 'AllowBatchCraft\s*=\s*false', 'Tags\s*=\s*AnySurfaceCraft', 'category\s*=\s*Repair', 'SkillRequired\s*=\s*Woodwork:4;Carving:3;Maintenance:3', 'xpAward\s*=\s*Woodwork:10;Carving:5;Maintenance:10', 'OnTest\s*=\s*AuxiliaCrossbowCrafting\.canRepairItem', 'OnCreate\s*=\s*RecipeCodeOnCreate\.genericBetterFixing', 'item\s+1\s+\[AuxiliasCrossbow\.ReinforcedCrossbow\]\s+mode:keep\s+flags\[Prop2;IsDamaged\]', 'item\s+1\s+\[Base\.WoodenStick2\]', 'item\s+1\s+\[Base\.IronPiece\]', 'item\s+1\s+\[Base\.Wire\]', 'item\s+2\s+\[Base\.Screws\]') },
    @{ Recipe = 'RepairHeavyCrossbow'; Patterns = @('time\s*=\s*600', 'AllowBatchCraft\s*=\s*false', 'Tags\s*=\s*AdvancedForge', 'category\s*=\s*Repair', 'SkillRequired\s*=\s*Maintenance:4;Blacksmith:4', 'xpAward\s*=\s*Maintenance:10;Blacksmith:20', 'OnTest\s*=\s*AuxiliaCrossbowCrafting\.canRepairItem', 'OnCreate\s*=\s*RecipeCodeOnCreate\.genericEvenBetterFixing', 'item\s+2\s+tags\[base:charcoal\]', 'item\s+1\s+\[AuxiliasCrossbow\.HeavyArbalest\]\s+mode:keep\s+flags\[IsDamaged\]', 'item\s+1\s+\[Base\.SteelPiece\]', 'item\s+1\s+\[Base\.NutsBolts\]', 'item\s+2\s+\[Base\.Screws\]') },
    @{ Recipe = 'CarveBoltShaft'; Patterns = @('time\s*=\s*100', 'xpAward\s*=\s*Carving:10') },
    @{ Recipe = 'CarveBoltShaftBatch'; Patterns = @('time\s*=\s*450', 'SkillRequired\s*=\s*Carving:2', 'xpAward\s*=\s*Carving:40', 'item\s+5\s+\[Base\.SmallHandle\]', 'item\s+5\s+AuxiliasCrossbow\.BoltShaft') },
    @{ Recipe = 'ShapeBoltHead'; Patterns = @('time\s*=\s*100', 'xpAward\s*=\s*Maintenance:5') },
    @{ Recipe = 'KnappBoltHeads'; Patterns = @('time\s*=\s*230', 'xpAward\s*=\s*FlintKnapping:20', 'item\s+1\s+\[Base\.SharpedStone\]', 'item\s+4\s+AuxiliasCrossbow\.StoneBoltHead') },
    @{ Recipe = 'ForgeBoltHeads'; Patterns = @('time\s*=\s*200', 'xpAward\s*=\s*Blacksmith:20') },
    @{ Recipe = 'MakeStandardBolts'; Patterns = @('time\s*=\s*100', 'Tags\s*=\s*InHandCraft;Survivalist', 'SkillRequired\s*=\s*Maintenance:1', 'timedAction\s*=\s*MakingJewellery', 'xpAward\s*=\s*Maintenance:5') },
    @{ Recipe = 'MakeStandardBoltsBatch'; Patterns = @('time\s*=\s*450', 'SkillRequired\s*=\s*Maintenance:1', 'xpAward\s*=\s*Maintenance:20', 'item\s+5\s+\[AuxiliasCrossbow\.BoltShaft\]', 'item\s+5\s+\[AuxiliasCrossbow\.BoltHead\]', 'item\s+5\s+\[Base\.ChickenFeather;Base\.TurkeyFeather;Base\.DenimStrips;Base\.LeatherStrips\]', 'item\s+5\s+\[Base\.Twine\]', 'item\s+5\s+Base\.AuxiliasCrossbowBolt') },
    @{ Recipe = 'MakeStoneBolt'; Patterns = @('time\s*=\s*100', 'Tags\s*=\s*InHandCraft;Survivalist', 'SkillRequired\s*=\s*Maintenance:1', 'timedAction\s*=\s*MakingJewellery', 'xpAward\s*=\s*Maintenance:5') },
    @{ Recipe = 'MakeStoneBoltBatch'; Patterns = @('time\s*=\s*450', 'SkillRequired\s*=\s*Maintenance:1', 'xpAward\s*=\s*Maintenance:20', 'item\s+5\s+\[AuxiliasCrossbow\.BoltShaft\]', 'item\s+5\s+\[AuxiliasCrossbow\.StoneBoltHead\]', 'item\s+5\s+\[Base\.ChickenFeather;Base\.TurkeyFeather;Base\.DenimStrips;Base\.LeatherStrips\]', 'item\s+5\s+\[Base\.Twine\]', 'item\s+5\s+Base\.AuxiliasStoneCrossbowBolt') },
    @{ Recipe = 'SalvageBrokenBolts'; Patterns = @('time\s*=\s*60', 'category\s*=\s*Assembly'); Forbidden = @('SkillRequired\s*=', 'xpAward\s*=') },
    @{ Recipe = 'SalvageBrokenStoneBolt'; Patterns = @('time\s*=\s*60', 'category\s*=\s*Assembly'); Forbidden = @('SkillRequired\s*=', 'xpAward\s*=') }
)

foreach ($recipeSpec in $vanillaAlignedRecipeChecks) {
    $recipeBlock = Get-CraftRecipeBlock -Text $recipesText -Name $recipeSpec.Recipe
    foreach ($pattern in $recipeSpec.Patterns) {
        if ($recipeBlock -notmatch $pattern) {
            throw "Vanilla-alignment check failed for $($recipeSpec.Recipe): $pattern"
        }
    }
    foreach ($pattern in @($recipeSpec.Forbidden)) {
        if ($pattern -and $recipeBlock -match $pattern) {
            throw "Forbidden field found in $($recipeSpec.Recipe): $pattern"
        }
    }
}

if (([regex]::Matches($recipesText, 'item\s+1\s+\[Base\.ChickenFeather;Base\.TurkeyFeather;Base\.DenimStrips;Base\.LeatherStrips\]')).Count -ne 2 -or
    ([regex]::Matches($recipesText, 'item\s+5\s+\[Base\.ChickenFeather;Base\.TurkeyFeather;Base\.DenimStrips;Base\.LeatherStrips\]')).Count -ne 2) {
    throw 'Each Metal and Stone Bolt assembly recipe must accept feathers, clean denim, or clean leather in the same fletching input.'
}

if ($recipesText -match 'Base\.DuctTape') {
    throw 'Feather fletching must not be bypassed with Duct Tape.'
}

foreach ($recipeCheck in @(
    @{ Name = 'Knapping skill requirement'; Pattern = 'SkillRequired\s*=\s*FlintKnapping:2' },
    @{ Name = 'Blacksmith skill requirement'; Pattern = 'SkillRequired\s*=\s*Blacksmith:2' },
    @{ Name = 'Primitive Forge requirement'; Pattern = 'Tags\s*=\s*PrimitiveForge' }
)) {
    if ($recipesText -notmatch $recipeCheck.Pattern) {
        throw "Recipe check is missing: $($recipeCheck.Name)"
    }
}

if ($recipesText -match 'item\s+2\s+\[AuxiliasCrossbow\.BrokenBolt\]') {
    throw 'Broken bolts must be salvaged one at a time.'
}

if (([regex]::Matches($recipesText, 'NeedToBeLearn\s*=\s*true')).Count -ne 1) {
    throw 'Only the Heavy Crossbow may require advanced recipe learning.'
}

if (([regex]::Matches($recipesText, '\bcraftRecipe\s+')).Count -ne 17) {
    throw 'Auxilia Crossbow must define exactly seventeen crafting and repair recipes.'
}

if ($itemsText -match 'base:repairwith(?:tape|glue|epoxy)') {
    throw 'Crossbows must use their tier-specific repair recipes rather than vanilla catch-all repair tags.'
}

$craftingLuaText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\shared\AuxiliaCrossbow_Crafting.lua') -Raw
foreach ($stateCheck in @('function AuxiliaCrossbowCrafting.canUseUpgradeItem', 'function AuxiliaCrossbowCrafting.canRepairItem', '["AuxiliasCrossbow.HeavyArbalest"] = true', 'getCurrentAmmoCount() == 0', 'function AuxiliaCrossbowCrafting.finishUpgrade', 'getAllConsumedItems()', 'getFirstCreatedItem()', 'setAmmoType(ammoType)', 'syncItemFields()')) {
    if ($craftingLuaText -notmatch [regex]::Escape($stateCheck)) {
        throw "Crossbow upgrade state handling is missing: $stateCheck"
    }
}

$registriesText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\registries.lua') -Raw
foreach ($ammoRegistry in @('auxiliascrossbow:bolt', 'auxiliascrossbow:stonebolt', 'AuxiliasCrossbowBolt', 'AuxiliasStoneCrossbowBolt')) {
    if ($registriesText -notmatch [regex]::Escape($ammoRegistry)) {
        throw "Ammo registry entry is missing: $ammoRegistry"
    }
}

$ammoSelectionText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_AmmoSelection.lua') -Raw
foreach ($selectionCheck in @('setAmmoType', 'syncItemFields', 'ContextMenu_AuxiliaCrossbow_CurrentMetalBolts', 'ContextMenu_AuxiliaCrossbow_CurrentStoneBolts', 'ContextMenu_AuxiliaCrossbow_SelectMetalBolts', 'ContextMenu_AuxiliaCrossbow_SelectStoneBolts', 'statusOption.notAvailable')) {
    if ($ammoSelectionText -notmatch [regex]::Escape($selectionCheck)) {
        throw "Bolt ammo-selection integration is missing: $selectionCheck"
    }
}

$recoveryText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\server\AuxiliaCrossbow_Recovery.lua') -Raw
foreach ($recoveryCheck in @(
    '["auxiliascrossbow:bolt"]',
    '["auxiliascrossbow:stonebolt"]',
    'intactChance = 70',
    'intactChance = 45',
    'AuxiliasStoneCrossbowBolt',
    'BrokenStoneBolt',
    'zombie:addItemToSpawnAtDeath',
    'PENDING_RECOVERY_KEY',
    'square:AddWorldInventoryItem',
    'Events.OnHitZombie.Add',
    'Events.OnWeaponHitCharacter.Add',
    'Events.OnCharacterDeath.Add'
)) {
    if ($recoveryText -notmatch [regex]::Escape($recoveryCheck)) {
        throw "Material-specific bolt recovery is missing: $recoveryCheck"
    }
}
foreach ($removedRecoveryToken in @(
    'zombie:setAttachedItem',
    'sendAttachedItem',
    'setStaticModel',
    'attachmentSlotsByBodyPart',
    'EmbeddedAlt',
    'EventAttachItem'
)) {
    if ($recoveryText.Contains($removedRecoveryToken)) {
        throw "Removed live-zombie Bolt attachment remains in recovery code: $removedRecoveryToken"
    }
}
if ($recoveryText -match [regex]::Escape('Events.OnWeaponHitXp.Add')) {
    throw 'Bolt recovery must not use the single-player-only OnWeaponHitXp callback.'
}

$reloadText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\shared\AuxiliaCrossbow_Reload.lua') -Raw
foreach ($reloadCheck in @('ISReloadWeaponAction.setReloadSpeed', 'AuxiliasCrossbow.ImprovisedCrossbow', 'AuxiliasCrossbow.ReinforcedCrossbow', 'AuxiliasCrossbow.HeavyArbalest')) {
    if ($reloadText -notmatch [regex]::Escape($reloadCheck)) {
        throw "Tier-specific reload integration is missing: $reloadCheck"
    }
}

$modelStateText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_ModelState.lua') -Raw
foreach ($modelStateCheck in @(
    'AuxiliaImprovisedCrossbowCocked',
    'AuxiliaImprovisedCrossbowCockedStoneBolt',
    'AuxiliaReinforcedCrossbowCocked',
    'AuxiliaReinforcedCrossbowCockedStoneBolt',
    'AuxiliaHeavyArbalestCocked',
    'AuxiliaHeavyArbalestCockedStoneBolt',
    'local STONE_AMMO_TYPE = "auxiliascrossbow:stonebolt"',
    'weapon:getAmmoType()',
    'return profile.cockedStone',
    'local ammoCount = weapon:getCurrentAmmoCount()',
    'setWeaponSprite',
    'resetEquippedHandsModels',
    'releasedWeapons',
    'Events.OnPlayerUpdate.Add',
    'Events.OnWeaponSwingHitPoint.Add',
    'Events.OnPlayerAttackFinished.Add'
)) {
    if ($modelStateText -notmatch [regex]::Escape($modelStateCheck)) {
        throw "Crossbow model-state integration is missing: $modelStateCheck"
    }
}

$firearmEffectsText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_FirearmEffects.lua') -Raw
foreach ($firearmEffectsCheck in @(
    'AuxiliasCrossbow.ImprovisedCrossbow',
    'AuxiliasCrossbow.ReinforcedCrossbow',
    'AuxiliasCrossbow.HeavyArbalest',
    'getLamppostPositions',
    'light:getRadius() == 18',
    'removeLamppost',
    'Events.OnWeaponSwingHitPoint.Add',
    'Events.OnTick.Add'
)) {
    if ($firearmEffectsText -notmatch [regex]::Escape($firearmEffectsCheck)) {
        throw "Crossbow firearm-effect suppression is missing: $firearmEffectsCheck"
    }
}
foreach ($removedBallisticsWorkaround in @('IsoBulletTracerEffects', 'setMuzzleFlashModelKey', 'player:updateBallistics()', 'player:setAngleFromAim()', 'Events.OnPlayerUpdate.Add')) {
    if ($firearmEffectsText -match [regex]::Escape($removedBallisticsWorkaround)) {
        throw "Obsolete aimed-hand ballistics workaround must not return: $removedBallisticsWorkaround"
    }
}

$lootText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\server\AuxiliaCrossbow_Loot.lua') -Raw
foreach ($lootCheck in @('OnPreDistributionMerge', 'SafehouseArmor', 'BagsAndContainers.SurvivorItems', 'lootInjected')) {
    if ($lootText -notmatch [regex]::Escape($lootCheck)) {
        throw "Loot integration is missing: $lootCheck"
    }
}

$testKitText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_TestKit.lua') -Raw
foreach ($testKitCheck in @('isDebugEnabled', 'AuxiliasStoneCrossbowBolt', 'ContextMenu_AuxiliaCrossbow_TestKit', 'condition = 2', 'condition = 3', 'condition = 4', 'item:setCondition(sample.condition)', 'item:syncItemFields()')) {
    if ($testKitText -notmatch [regex]::Escape($testKitCheck)) {
        throw "Debug test-kit integration is missing: $testKitCheck"
    }
}

$alignmentDocText = Get-Content -LiteralPath (Join-Path $repoRoot 'docs\VANILLA-RECIPE-ALIGNMENT.md') -Raw
foreach ($documentationCheck in @('Build 42.20.2 vanilla recipe alignment', 'Vanilla anchors', 'Earlier Auxilia calibration', 'Build 42.20.4 follow-up', 'Material and workstation corrections', 'ReclaimFromSpear', 'Forge_Nails_From_Piece')) {
    if ($alignmentDocText -notmatch [regex]::Escape($documentationCheck)) {
        throw "Vanilla recipe-alignment documentation is incomplete: $documentationCheck"
    }
}

$readmeText = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw
if ($readmeText -notmatch [regex]::Escape('docs/VANILLA-RECIPE-ALIGNMENT.md')) {
    throw 'README must link to the vanilla recipe-alignment report.'
}

$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') {
    throw "VERSION must use semantic version format: $version"
}
if ($readmeText -notmatch [regex]::Escape("Current version: **$version**")) {
    throw "README current version does not match VERSION $version."
}
foreach ($metadataPath in @(
    (Join-Path $repoRoot 'workshop\workshop.txt'),
    (Join-Path $repoRoot 'workshop\Contents\mods\AuxiliasCrossbow\mod.info'),
    (Join-Path $versionRoot 'mod.info')
)) {
    $metadataText = Get-Content -LiteralPath $metadataPath -Raw
    if ($metadataText -notmatch [regex]::Escape("Version $version")) {
        throw "Metadata version does not match VERSION $version`: $metadataPath"
    }
}

$recipeOpenBraces = ([regex]::Matches($recipesText, '\{')).Count
$recipeCloseBraces = ([regex]::Matches($recipesText, '\}')).Count
if ($recipeOpenBraces -ne $recipeCloseBraces) {
    throw "Unbalanced braces in auxilia_recipes.txt"
}

$openBraces = ([regex]::Matches($itemsText, '\{')).Count
$closeBraces = ([regex]::Matches($itemsText, '\}')).Count
if ($openBraces -ne $closeBraces) {
    throw "Unbalanced braces in auxilia_items.txt"
}

Write-Host "Validation passed: $($requiredFiles.Count) required files, $($jsonFiles.Count) translation files."

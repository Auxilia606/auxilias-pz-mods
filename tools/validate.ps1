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
    (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_AmmoSelection.lua'),
    (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_ModelState.lua'),
    (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_MuzzleFlash.lua'),
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
    (Join-Path $repoRoot 'docs\VANILLA-RECIPE-ALIGNMENT.md')
)

$modelNames = @(
    'AuxiliaImprovisedCrossbow',
    'AuxiliaImprovisedCrossbowCocked',
    'AuxiliaReinforcedCrossbow',
    'AuxiliaReinforcedCrossbowCocked',
    'AuxiliaHeavyArbalest',
    'AuxiliaHeavyArbalestCocked',
    'AuxiliaCrossbowBolt',
    'AuxiliaStoneCrossbowBolt',
    'AuxiliaBrokenBolt',
    'AuxiliaBrokenStoneBolt'
)

foreach ($modelName in $modelNames) {
    $requiredFiles += Join-Path $versionRoot "media\models_X\weapons\2handed\$modelName.fbx"
    $requiredFiles += Join-Path $versionRoot "media\textures\weapons\2handed\$modelName.png"
}

$missing = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
    throw "Missing required mod files:`n$($missing -join "`n")"
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
    $translation = Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json
    foreach ($property in $translation.PSObject.Properties) {
        if ($property.Value -isnot [string] -or [string]::IsNullOrWhiteSpace($property.Value)) {
            throw "Translation value must be a non-empty string: $($jsonFile.FullName) -> $($property.Name)"
        }
    }
}

foreach ($translationFile in $translationFiles) {
    $english = Get-Content -LiteralPath (Join-Path $translationRoot "EN\$translationFile") -Raw | ConvertFrom-Json
    $korean = Get-Content -LiteralPath (Join-Path $translationRoot "KO\$translationFile") -Raw | ConvertFrom-Json
    $keyDifference = @(Compare-Object $english.PSObject.Properties.Name $korean.PSObject.Properties.Name)
    if ($keyDifference.Count -gt 0) {
        throw "English/Korean translation keys differ in $translationFile`: $($keyDifference.InputObject -join ', ')"
    }
}

$modelsText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\scripts\auxilia_models.txt') -Raw
if ($modelsText -notmatch '(?m)^\s*module\s+Base\s*$') {
    throw 'Weapon model scripts must be declared in module Base for WeaponSprite lookup.'
}

foreach ($modelName in $modelNames) {
    $modelBlockPattern = "(?s)model\s+$([regex]::Escape($modelName))\s*\{.*?mesh\s*=\s*weapons/2handed/$([regex]::Escape($modelName)),.*?texture\s*=\s*weapons/2handed/$([regex]::Escape($modelName)),.*?scale\s*=\s*0\.01,"
    if ($modelsText -notmatch $modelBlockPattern) {
        throw "Mesh/texture/scale model definition is incomplete: $modelName"
    }

    $fbxFile = Get-Item -LiteralPath (Join-Path $versionRoot "media\models_X\weapons\2handed\$modelName.fbx")
    $textureFile = Get-Item -LiteralPath (Join-Path $versionRoot "media\textures\weapons\2handed\$modelName.png")
    if ($fbxFile.Length -lt 20000) {
        throw "FBX is unexpectedly small: $($fbxFile.FullName)"
    }
    if ($textureFile.Length -lt 4096) {
        throw "Model texture is unexpectedly small or flat: $($textureFile.FullName)"
    }
}

$modelOpenBraces = ([regex]::Matches($modelsText, '\{')).Count
$modelCloseBraces = ([regex]::Matches($modelsText, '\}')).Count
if ($modelOpenBraces -ne $modelCloseBraces) {
    throw 'Unbalanced braces in auxilia_models.txt'
}

$generatorPath = Join-Path $repoRoot 'source-assets\blender\generate_assets.py'
$generatorText = Get-Content -LiteralPath $generatorPath -Raw
foreach ($pipelineCheck in @('finalize_collection', 'assign_palette_uv', 'collapse_game_materials', 'circular_limb_points', 'fixed_string_length', 'crossbow_physics', 'validate_exports', 'render_validation', 'render_bolt_placement', 'AuxiliaStoneCrossbowBolt', 'AuxiliaBrokenStoneBolt')) {
    if ($generatorText -notmatch [regex]::Escape($pipelineCheck)) {
        throw "Blender model pipeline check is missing: $pipelineCheck"
    }
}

$physicsReportPath = Join-Path $repoRoot 'work\model-validation\report.json'
if (Test-Path -LiteralPath $physicsReportPath) {
    $physicsReport = Get-Content -LiteralPath $physicsReportPath -Raw | ConvertFrom-Json
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
    }
}
if ($generatorText -notmatch 'axis_forward\s*=\s*"-Y"' -or $generatorText -notmatch 'axis_up\s*=\s*"Z"') {
    throw 'Blender FBX export axes must remain -Y forward and Z up for Project Zomboid.'
}
if ($generatorText -notmatch 'game_obj\.rotation_euler\.x\s*\+=\s*math\.pi') {
    throw 'Project Zomboid FBX exports must retain the tested 180-degree X-axis correction.'
}

foreach ($boltModelName in @('AuxiliaCrossbowBolt', 'AuxiliaStoneCrossbowBolt', 'AuxiliaBrokenBolt', 'AuxiliaBrokenStoneBolt')) {
    $boltModelBlockPattern = "(?s)model\s+$([regex]::Escape($boltModelName))\s*\{.*?(?=\s*model\s+\w+\s*\{|\s*\}\s*\z)"
    $boltModelBlock = [regex]::Match($modelsText, $boltModelBlockPattern).Value
    if (-not $boltModelBlock -or $boltModelBlock -notmatch '(?s)attachment\s+world\s*\{.*?rotate\s*=\s*90\.0\s+0\.0\s+0\.0') {
        throw "$boltModelName must retain its 90-degree world attachment so its weapon-axis FBX rests flat."
    }
}

$itemsText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\scripts\auxilia_items.txt') -Raw
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
    $itemBlockPattern = "(?s)item\s+$($weaponCheck.Item)\s*\{.*?AttachmentType\s*=\s*Rifle,.*?IsAimedFirearm\s*=\s*false,.*?IsAimedHandWeapon\s*=\s*true,.*?Ranged\s*=\s*true,.*?WeaponSprite\s*=\s*$($weaponCheck.Model),"
    if ($itemsText -notmatch $itemBlockPattern) {
        throw "Equipped model integration is incomplete: $($weaponCheck.Item)"
    }
}
if ($itemsText -match 'WeaponSprite\s*=\s*AuxiliasCrossbow\.') {
    throw 'WeaponSprite model names must be unqualified; model scripts are resolved from module Base.'
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

foreach ($recipeName in @('MakeLightCrossbow', 'MakeCrossbow', 'MakeHeavyCrossbow', 'CarveBoltShaft', 'ShapeBoltHead', 'KnappBoltHeads', 'ForgeBoltHeads', 'MakeStandardBolts', 'MakeStoneBolt', 'SalvageBrokenBolts', 'SalvageBrokenStoneBolt')) {
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
    if ($recoveryRecipeBlock -notmatch 'mode:keep\s+flags\[Prop1;MayDegradeVeryLight\]') {
        throw "$recoveryRecipeName must show its selected recovery tool as Prop1."
    }
}

$metalRecoveryRecipe = Get-CraftRecipeBlock -Text $recipesText -Name 'SalvageBrokenBolts'
if ($metalRecoveryRecipe -notmatch 'timedAction\s*=\s*MakingJewellery,') {
    throw 'Metal-head recovery must use the small-part MakingJewellery animation.'
}
$stoneRecoveryRecipe = Get-CraftRecipeBlock -Text $recipesText -Name 'SalvageBrokenStoneBolt'
if ($stoneRecoveryRecipe -notmatch 'timedAction\s*=\s*HammerStoneStanding,') {
    throw 'Stone-head recovery must use the stone-working HammerStoneStanding animation.'
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
    @{ Recipe = 'MakeLightCrossbow'; Patterns = @('time\s*=\s*600', 'xpAward\s*=\s*Woodwork:20;Carving:20;Maintenance:10', 'item\s+1\s+\[Base\.Plank\]') },
    @{ Recipe = 'MakeCrossbow'; Patterns = @('time\s*=\s*600', 'xpAward\s*=\s*Woodwork:40;Carving:30;Maintenance:30', 'item\s+1\s+\[AuxiliasCrossbow\.ImprovisedCrossbow\]', 'item\s+1\s+\[Base\.MetalBar\]', 'tags\[base:screwdriver\]', 'tags\[base:pliers\]') },
    @{ Recipe = 'MakeHeavyCrossbow'; Patterns = @('time\s*=\s*900', 'Tags\s*=\s*AdvancedForge', 'timedAction\s*=\s*HammerMetalStanding', 'xpAward\s*=\s*Maintenance:40;Blacksmith:45', 'item\s+4\s+tags\[base:charcoal\]', 'item\s+1\s+\[AuxiliasCrossbow\.ReinforcedCrossbow\]', 'item\s+1\s+\[Base\.SteelBarHalf\]', 'tags\[base:ballpeenhammer\]', 'tags\[base:tongs\]') },
    @{ Recipe = 'CarveBoltShaft'; Patterns = @('time\s*=\s*100', 'xpAward\s*=\s*Carving:10') },
    @{ Recipe = 'ShapeBoltHead'; Patterns = @('time\s*=\s*100', 'xpAward\s*=\s*Maintenance:5') },
    @{ Recipe = 'KnappBoltHeads'; Patterns = @('time\s*=\s*230', 'xpAward\s*=\s*FlintKnapping:20') },
    @{ Recipe = 'ForgeBoltHeads'; Patterns = @('time\s*=\s*200', 'xpAward\s*=\s*Blacksmith:20') },
    @{ Recipe = 'MakeStandardBolts'; Patterns = @('time\s*=\s*100', 'Tags\s*=\s*InHandCraft;Survivalist', 'SkillRequired\s*=\s*Maintenance:1', 'timedAction\s*=\s*MakingJewellery', 'xpAward\s*=\s*Maintenance:5') },
    @{ Recipe = 'MakeStoneBolt'; Patterns = @('time\s*=\s*100', 'Tags\s*=\s*InHandCraft;Survivalist', 'SkillRequired\s*=\s*Maintenance:1', 'timedAction\s*=\s*MakingJewellery', 'xpAward\s*=\s*Maintenance:5') },
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

if (([regex]::Matches($recipesText, 'item\s+1\s+tags\[base:feather\]')).Count -ne 2) {
    throw 'Both bolt assembly recipes must require one vanilla-compatible feather.'
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

if ($recipesText -match 'item\s+5\s+Base\.AuxiliasCrossbowBolt') {
    throw 'Standard bolts must be assembled one at a time.'
}

if ($recipesText -match 'item\s+2\s+\[AuxiliasCrossbow\.BrokenBolt\]') {
    throw 'Broken bolts must be salvaged one at a time.'
}

if ($recipesText -match 'NeedToBeLearn\s*=\s*true') {
    throw 'Auxilia recipes must remain skill-gated without a separate recipe unlock.'
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
foreach ($recoveryCheck in @('AuxiliasStoneCrossbowBolt', 'BrokenStoneBolt', 'intactChance = isStoneBolt and 45 or 70')) {
    if ($recoveryText -notmatch [regex]::Escape($recoveryCheck)) {
        throw "Material-specific bolt recovery is missing: $recoveryCheck"
    }
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
    'AuxiliaReinforcedCrossbowCocked',
    'AuxiliaHeavyArbalestCocked',
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

$muzzleFlashText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_MuzzleFlash.lua') -Raw
foreach ($muzzleFlashCheck in @(
    'AuxiliasCrossbow.ImprovisedCrossbow',
    'AuxiliasCrossbow.ReinforcedCrossbow',
    'AuxiliasCrossbow.HeavyArbalest',
    'player:isDead()',
    'player:isAiming()',
    'player:getPrimaryHandItem()',
    'player:setAngleFromAim()',
    'player:updateBallistics()',
    'Events.OnEquipPrimary.Add',
    'Events.OnGameStart.Add',
    'Events.OnPlayerUpdate.Add'
)) {
    if ($muzzleFlashText -notmatch [regex]::Escape($muzzleFlashCheck)) {
        throw "Crossbow muzzle-flash suppression is missing: $muzzleFlashCheck"
    }
}

$lootText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\server\AuxiliaCrossbow_Loot.lua') -Raw
foreach ($lootCheck in @('OnPreDistributionMerge', 'SafehouseArmor', 'BagsAndContainers.SurvivorItems', 'lootInjected')) {
    if ($lootText -notmatch [regex]::Escape($lootCheck)) {
        throw "Loot integration is missing: $lootCheck"
    }
}

$testKitText = Get-Content -LiteralPath (Join-Path $versionRoot 'media\lua\client\AuxiliaCrossbow_TestKit.lua') -Raw
foreach ($testKitCheck in @('isDebugEnabled', 'AuxiliasStoneCrossbowBolt', 'ContextMenu_AuxiliaCrossbow_TestKit')) {
    if ($testKitText -notmatch [regex]::Escape($testKitCheck)) {
        throw "Debug test-kit integration is missing: $testKitCheck"
    }
}

$alignmentDocText = Get-Content -LiteralPath (Join-Path $repoRoot 'docs\VANILLA-RECIPE-ALIGNMENT.md') -Raw
foreach ($documentationCheck in @('Build 42.20.2 vanilla recipe alignment', 'Vanilla anchors', 'Auxilia changes', 'Material and workstation corrections', 'ReclaimFromSpear', 'Forge_Nails_From_Piece')) {
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

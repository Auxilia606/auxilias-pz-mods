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
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaImprovisedCrossbow.fbx'),
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaReinforcedCrossbow.fbx'),
    (Join-Path $versionRoot 'media\models_X\weapons\2handed\AuxiliaHeavyArbalest.fbx'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaImprovisedCrossbow.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaCrossbowBolt.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaBrokenBolt.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaReinforcedCrossbow.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaHeavyArbalest.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaBoltShaft.png'),
    (Join-Path $versionRoot 'media\textures\Item_AuxiliaBoltHead.png'),
    (Join-Path $repoRoot 'docs\VANILLA-RECIPE-ALIGNMENT.md')
)

$modelNames = @(
    'AuxiliaImprovisedCrossbow',
    'AuxiliaReinforcedCrossbow',
    'AuxiliaHeavyArbalest',
    'AuxiliaCrossbowBolt',
    'AuxiliaBrokenBolt'
)

foreach ($modelName in $modelNames) {
    $requiredFiles += Join-Path $versionRoot "media\models_X\weapons\2handed\$modelName.fbx"
    $requiredFiles += Join-Path $versionRoot "media\textures\weapons\2handed\$modelName.png"
}

$missing = @($requiredFiles | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
    throw "Missing required mod files:`n$($missing -join "`n")"
}

$jsonFiles = Get-ChildItem -LiteralPath (Join-Path $versionRoot 'media\lua\shared\Translate') -Recurse -Filter '*.json'
foreach ($jsonFile in $jsonFiles) {
    Get-Content -LiteralPath $jsonFile.FullName -Raw | ConvertFrom-Json | Out-Null
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
foreach ($pipelineCheck in @('finalize_collection', 'assign_palette_uv', 'collapse_game_materials', 'validate_exports', 'render_validation', 'render_bolt_placement')) {
    if ($generatorText -notmatch [regex]::Escape($pipelineCheck)) {
        throw "Blender model pipeline check is missing: $pipelineCheck"
    }
}
if ($generatorText -notmatch 'axis_forward\s*=\s*"-Y"' -or $generatorText -notmatch 'axis_up\s*=\s*"Z"') {
    throw 'Blender FBX export axes must remain -Y forward and Z up for Project Zomboid.'
}
if ($generatorText -notmatch 'game_obj\.rotation_euler\.x\s*\+=\s*math\.pi') {
    throw 'Project Zomboid FBX exports must retain the tested 180-degree X-axis correction.'
}

$boltModelBlockPattern = '(?s)model\s+AuxiliaCrossbowBolt\s*\{.*?(?=\s*model\s+AuxiliaBrokenBolt\b)'
$boltModelBlock = [regex]::Match($modelsText, $boltModelBlockPattern).Value
if (-not $boltModelBlock -or $boltModelBlock -notmatch '(?s)attachment\s+world\s*\{.*?rotate\s*=\s*90\.0\s+0\.0\s+0\.0') {
    throw 'The intact bolt must retain its 90-degree world attachment so its weapon-axis FBX rests flat.'
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
    $itemBlockPattern = "(?s)item\s+$($weaponCheck.Item)\s*\{.*?AttachmentType\s*=\s*Rifle,.*?IsAimedHandWeapon\s*=\s*true,.*?WeaponSprite\s*=\s*$($weaponCheck.Model),"
    if ($itemsText -notmatch $itemBlockPattern) {
        throw "Equipped model integration is incomplete: $($weaponCheck.Item)"
    }
}
if ($itemsText -match 'WeaponSprite\s*=\s*AuxiliasCrossbow\.') {
    throw 'WeaponSprite model names must be unqualified; model scripts are resolved from module Base.'
}
foreach ($iconCheck in @(
    @{ Item = 'BoltShaft'; Icon = 'AuxiliaBoltShaft' },
    @{ Item = 'BoltHead'; Icon = 'AuxiliaBoltHead' }
)) {
    $iconPattern = "(?s)item\s+$($iconCheck.Item)\s*\{.*?Icon\s*=\s*$($iconCheck.Icon),"
    if ($itemsText -notmatch $iconPattern) {
        throw "Dedicated crafting-component icon is not assigned: $($iconCheck.Item)"
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

$vanillaAlignedRecipeChecks = @(
    @{ Recipe = 'MakeLightCrossbow'; Patterns = @('time\s*=\s*600', 'xpAward\s*=\s*Woodwork:20;Carving:20;Maintenance:10', 'item\s+1\s+\[Base\.Plank\]') },
    @{ Recipe = 'MakeCrossbow'; Patterns = @('time\s*=\s*600', 'xpAward\s*=\s*Woodwork:40;Carving:30;Maintenance:30', 'item\s+1\s+\[AuxiliasCrossbow\.ImprovisedCrossbow\]', 'item\s+1\s+\[Base\.MetalBar\]', 'tags\[base:screwdriver\]', 'tags\[base:pliers\]') },
    @{ Recipe = 'MakeHeavyCrossbow'; Patterns = @('time\s*=\s*900', 'Tags\s*=\s*AdvancedForge', 'timedAction\s*=\s*HammerMetalStanding', 'xpAward\s*=\s*Maintenance:40;Blacksmith:45', 'item\s+4\s+tags\[base:charcoal\]', 'item\s+1\s+\[AuxiliasCrossbow\.ReinforcedCrossbow\]', 'item\s+1\s+\[Base\.SteelBarHalf\]', 'tags\[base:ballpeenhammer\]', 'tags\[base:tongs\]') },
    @{ Recipe = 'CarveBoltShaft'; Patterns = @('time\s*=\s*100', 'xpAward\s*=\s*Carving:10') },
    @{ Recipe = 'ShapeBoltHead'; Patterns = @('time\s*=\s*100', 'xpAward\s*=\s*Maintenance:5') },
    @{ Recipe = 'KnappBoltHeads'; Patterns = @('time\s*=\s*230', 'xpAward\s*=\s*FlintKnapping:20') },
    @{ Recipe = 'ForgeBoltHeads'; Patterns = @('time\s*=\s*200', 'xpAward\s*=\s*Blacksmith:20') },
    @{ Recipe = 'MakeStandardBolts'; Patterns = @('time\s*=\s*100', 'Tags\s*=\s*InHandCraft;Survivalist', 'SkillRequired\s*=\s*Maintenance:1', 'timedAction\s*=\s*CraftKnifeSpear', 'xpAward\s*=\s*Maintenance:5') },
    @{ Recipe = 'MakeStoneBolt'; Patterns = @('time\s*=\s*100', 'Tags\s*=\s*InHandCraft;Survivalist', 'SkillRequired\s*=\s*Maintenance:1', 'timedAction\s*=\s*CraftKnifeSpear', 'xpAward\s*=\s*Maintenance:5') },
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
foreach ($selectionCheck in @('setAmmoType', 'syncItemFields', 'ContextMenu_AuxiliaCrossbow_SelectMetalBolts', 'ContextMenu_AuxiliaCrossbow_SelectStoneBolts')) {
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

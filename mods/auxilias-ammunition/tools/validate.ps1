param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$monorepoRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot '..\..'))
$target = (Get-Content -LiteralPath (Join-Path $monorepoRoot 'config\project-zomboid.json') -Raw -Encoding UTF8 | ConvertFrom-Json).target
$releaseLine = [string]$target.releaseLine
$modRoot = Join-Path $repoRoot 'workshop\Contents\mods\AuxiliasAmmunition'
$versionRoot = Join-Path $modRoot $releaseLine
$scriptRoot = Join-Path $versionRoot 'media\scripts'
$translationRoot = Join-Path $versionRoot 'media\lua\shared\Translate'
$itemsPath = Join-Path $scriptRoot 'auxilias_ammunition_items.txt'
$recipesPath = Join-Path $scriptRoot 'auxilias_ammunition_recipes.txt'
$pressPath = Join-Path $scriptRoot 'auxilias_ammunition_press.txt'
$pressSkinPath = Join-Path $scriptRoot 'auxilias_ammunition_press_xuiSkin.txt'
$pressTilePath = Join-Path $versionRoot 'media\auxammo_press_01.tiles'
$pressTileTextPath = Join-Path $versionRoot 'media\auxammo_press_01.tiles.txt'
$pressPackPath = Join-Path $versionRoot 'media\texturepacks\auxammo_press_01.pack'
$lootPath = Join-Path $versionRoot 'media\lua\server\AuxiliasAmmunition_Loot.lua'
$pressWorldPath = Join-Path $versionRoot 'media\lua\shared\AuxiliasAmmunition_PressWorld.lua'
$pressContextIconPath = Join-Path $versionRoot 'media\lua\client\AuxiliasAmmunition_PressContextIcon.lua'
$pressLeftClickPath = Join-Path $versionRoot 'media\lua\client\AuxiliasAmmunition_PressLeftClick.lua'
function Get-PngSize([string]$Path) {
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 24 -or $bytes[0] -ne 137 -or $bytes[1] -ne 80 -or $bytes[2] -ne 78 -or $bytes[3] -ne 71) {
        throw "Invalid PNG: $Path"
    }
    [pscustomobject]@{
        Width = ([int]$bytes[16] -shl 24) -bor ([int]$bytes[17] -shl 16) -bor ([int]$bytes[18] -shl 8) -bor [int]$bytes[19]
        Height = ([int]$bytes[20] -shl 24) -bor ([int]$bytes[21] -shl 16) -bor ([int]$bytes[22] -shl 8) -bor [int]$bytes[23]
    }
}

function Get-PngAlphaRange([string]$Path) {
    $bitmap = [System.Drawing.Bitmap]::new($Path)
    try {
        $minimum = 255
        $maximum = 0
        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                $alpha = $bitmap.GetPixel($x, $y).A
                if ($alpha -lt $minimum) { $minimum = $alpha }
                if ($alpha -gt $maximum) { $maximum = $alpha }
            }
        }
        [pscustomobject]@{ Minimum = $minimum; Maximum = $maximum }
    }
    finally {
        $bitmap.Dispose()
    }
}

$requiredFiles = @(
    (Join-Path $repoRoot 'VERSION'), (Join-Path $repoRoot 'README.md'), (Join-Path $repoRoot 'CHANGELOG.md'),
    (Join-Path $repoRoot 'docs\VANILLA-AMMO-AUDIT.md'), (Join-Path $repoRoot 'docs\DESIGN.md'),
    (Join-Path $repoRoot 'docs\BALANCE.md'), (Join-Path $repoRoot 'docs\TESTING.md'),
    (Join-Path $repoRoot 'docs\reports\RELEASE-VALIDATION-1.0.0.md'),
    (Join-Path $repoRoot 'workshop\workshop.txt'), (Join-Path $repoRoot 'workshop\preview.png'),
    (Join-Path $modRoot 'mod.info'), (Join-Path $modRoot 'poster.png'), (Join-Path $modRoot 'icon.png'),
    (Join-Path $versionRoot 'mod.info'), (Join-Path $versionRoot 'poster.png'), (Join-Path $versionRoot 'icon.png'),
    $itemsPath, $recipesPath, $pressPath, $pressSkinPath, $pressTilePath, $pressTileTextPath, $pressPackPath, $lootPath, $pressWorldPath, $pressContextIconPath, $pressLeftClickPath,
    (Join-Path $repoRoot 'tools\sync-icons.ps1'),
    (Join-Path $repoRoot 'source-assets\workshop\AuxiliasAmmunition-cover-source.png'),
    (Join-Path $repoRoot 'source-assets\icons\generate_body_icons.py')
)
foreach ($path in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing required file: $path" }
}

$version = (Get-Content -LiteralPath (Join-Path $repoRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "Invalid VERSION: $version" }
foreach ($metadataPath in @((Join-Path $repoRoot 'workshop\workshop.txt'), (Join-Path $modRoot 'mod.info'), (Join-Path $versionRoot 'mod.info'))) {
    $metadata = Get-Content -LiteralPath $metadataPath -Raw
    if ($metadata -notmatch [regex]::Escape("Version $version")) { throw "Metadata version mismatch: $metadataPath" }
}
foreach ($metadataPath in @((Join-Path $modRoot 'mod.info'), (Join-Path $versionRoot 'mod.info'))) {
    $metadata = Get-Content -LiteralPath $metadataPath -Raw
    if ($metadata -notmatch '(?m)^id=AuxiliasAmmunition\r?$') { throw "Invalid mod ID: $metadataPath" }
    if ($metadata -notmatch "(?m)^versionMin=$([regex]::Escape($releaseLine))\r?$") { throw "Invalid versionMin: $metadataPath" }
    if ($metadata -notmatch '(?m)^pack=auxammo_press_01\r?$' -or
        $metadata -notmatch '(?m)^tiledef=auxammo_press_01 7713\r?$') {
        throw "Missing tabletop press pack/tiledef registration: $metadataPath"
    }
}

$itemsText = Get-Content -LiteralPath $itemsPath -Raw
$recipesText = Get-Content -LiteralPath $recipesPath -Raw
$pressText = Get-Content -LiteralPath $pressPath -Raw
$pressSkinText = Get-Content -LiteralPath $pressSkinPath -Raw
foreach ($entry in @(@($itemsPath, $itemsText), @($recipesPath, $recipesText), @($pressPath, $pressText), @($pressSkinPath, $pressSkinText))) {
    if (([regex]::Matches($entry[1], '\{')).Count -ne ([regex]::Matches($entry[1], '\}')).Count) { throw "Unbalanced braces: $($entry[0])" }
}
if ($itemsText -match '(?m)^\s*module\s+Base\s*$' -or $recipesText -match '(?m)^\s*module\s+Base\s*$') { throw 'Items and recipes may not override module Base.' }

if ($pressText -notmatch '(?ms)^\s*module\s+AuxiliasAmmunition\s*\{\s*entity\s+AmmoPress\s*\{' -or
    $pressText -notmatch '(?ms)component\s+CraftBench\s*\{\s*Recipes\s*=\s*AuxAmmoPress,' -or
    $pressText -notmatch '(?ms)component\s+SpriteConfig\s*\{.*?row\s*=\s*auxammo_press_01_0,') {
    throw 'Dedicated tabletop press entity does not expose the correct station tag or sprite.'
}
if ($pressSkinText -notmatch '(?ms)^\s*module\s+Base\s*\{\s*xuiSkin\s+default\s*\{\s*entity\s+ES_AmmoPress\s*\{' -or
    $pressSkinText -notmatch 'LuaWindowClass\s*=\s*ISEntityWindow,' -or
    $pressSkinText -notmatch 'Icon\s*=\s*Item_AuxAmmoPress,' -or
    $pressSkinText -notmatch '(?s)components\s*\{\s*CraftBench\s*\{\s*LuaPanelClass\s*=\s*ISCraftBenchPanel,.*?Enabled\s*=\s*true,') {
    throw 'The press UI skin must expose an enabled CraftBench panel in module Base.'
}
for ($direction = 0; $direction -lt 4; $direction++) {
    if ($pressText -notmatch "row\s*=\s*auxammo_press_01_$direction,") {
        throw "Missing press entity sprite direction: $direction"
    }
}
$pressItem = [regex]::Match($itemsText, '(?ms)^    item\s+Mov_AmmoPress\s*\{(?<body>.*?)^    \}')
if (-not $pressItem.Success -or
    $pressItem.Groups['body'].Value -notmatch '(?m)^\s*ItemType\s*=\s*base:moveable,' -or
    $pressItem.Groups['body'].Value -notmatch '(?m)^\s*WorldObjectSprite\s*=\s*auxammo_press_01_0,' -or
    $pressItem.Groups['body'].Value -notmatch '(?m)^\s*Tooltip\s*=\s*Tooltip_item_AuxAmmo_Press,' -or
    $pressItem.Groups['body'].Value -notmatch '(?s)component\s+UiConfig\s*\{\s*xuiSkin\s*=\s*default,\s*entityStyle\s*=\s*ES_AmmoPress,\s*uiEnabled\s*=\s*true,' -or
    $pressItem.Groups['body'].Value -notmatch '(?s)component\s+CraftBench\s*\{\s*Recipes\s*=\s*AuxAmmoPress,') {
    throw 'Movable press item must carry UiConfig and CraftBench for its custom-item world object.'
}
if ((Get-Item -LiteralPath $pressTilePath).Length -lt 500 -or
    (Get-Item -LiteralPath $pressPackPath).Length -lt 10000) {
    throw 'Press tile metadata or texture pack is unexpectedly small.'
}
$pressTileText = Get-Content -LiteralPath $pressTileTextPath -Raw
$pressFaces = @('S', 'E', 'N', 'W')
for ($direction = 0; $direction -lt 4; $direction++) {
    $tileBlock = [regex]::Match($pressTileText, "(?ms)^\s*// auxammo_press_01_$direction\s*\r?\n\s*tile\s*\{(?<body>.*?)^\s*\}")
    if (-not $tileBlock.Success) { throw "Missing press tile metadata direction: $direction" }
    $tileBody = $tileBlock.Groups['body'].Value
    if ($tileBody -notmatch "(?m)^\s*Facing\s*=\s*$($pressFaces[$direction])\s*$") {
        throw "Incorrect press tile facing: $direction"
    }
    if ($tileBody -notmatch '(?m)^\s*IgnoreSurfaceSnap\s*=\s*$') {
        throw "Press tile $direction must keep its selected facing when placed on a table."
    }
    for ($target = 0; $target -lt 4; $target++) {
        if ($target -eq $direction) { continue }
        $offsetName = "$($pressFaces[$target])offset"
        $offset = $target - $direction
        if ($tileBody -notmatch "(?m)^\s*$offsetName\s*=\s*$offset\s*$") {
            throw "Press tile $direction cannot rotate to $($pressFaces[$target]) ($offsetName = $offset)."
        }
    }
}
if (([regex]::Matches($pressTileText, 'CustomItem\s*=\s*AuxiliasAmmunition\.Mov_AmmoPress')).Count -ne 4 -or
    ([regex]::Matches($pressTileText, 'IsTableTop\s*=')).Count -ne 4) {
    throw 'All four press tile directions must be recoverable tabletop moveables.'
}

$itemIds = @([regex]::Matches($itemsText, '(?m)^\s*item\s+([A-Za-z0-9_]+)\s*$') | ForEach-Object { $_.Groups[1].Value })
$recipeIds = @([regex]::Matches($recipesText, '(?m)^\s*craftRecipe\s+([A-Za-z0-9_]+)\s*$') | ForEach-Object { $_.Groups[1].Value })
if ($itemIds.Count -ne 12 -or @($itemIds | Select-Object -Unique).Count -ne 12) { throw "Expected 12 unique items; found $($itemIds.Count)." }
if ($recipeIds.Count -ne 19 -or @($recipeIds | Select-Object -Unique).Count -ne 19) { throw "Expected 19 unique craft recipes; found $($recipeIds.Count)." }
if (([regex]::Matches($recipesText, '(?m)^\s*NeedToBeLearn\s*=\s*true,')).Count -ne 16) { throw 'The 16 production recipes must require knowledge.' }
if (([regex]::Matches($recipesText, '(?m)^\s*NeedToBeLearn\s*=\s*false,')).Count -ne 3) { throw 'Only carbon grinding and two nitrogenous-mix recipes may be learned by default.' }

$expectedRecipeIds = @(
    'AuxAmmoCastSmallPistolProjectiles','AuxAmmoCastHeavyPistolProjectiles','AuxAmmoCastRifleProjectiles','AuxAmmoCastShotCharges',
    'AuxAmmoRefineMineralSalts','AuxAmmoGrindCarbonPowder','AuxAmmoPrepareNitrogenousMixFromCompost','AuxAmmoPrepareNitrogenousMixFromFertilizer',
    'AuxAmmoBlendSurvivalPropellant',
    'AuxAmmoAssemble9mm','AuxAmmoAssemble38','AuxAmmoAssemble357','AuxAmmoAssemble45','AuxAmmoAssemble44',
    'AuxAmmoAssemble556','AuxAmmoAssemble3030','AuxAmmoAssemble308','AuxAmmoAssembleShotgun',
    'CraftAmmoPress'
)
foreach ($recipeId in $expectedRecipeIds) {
    if ($recipeId -notin $recipeIds) { throw "Missing established or redesigned recipe ID: $recipeId" }
}

foreach ($newItemId in @('SmallPistolBody','HeavyPistolBody','RifleBody','ShotgunBody','CarbonPowder','NitrogenousMix','Mov_AmmoPress')) {
    if ($newItemId -notin $itemIds) { throw "Missing redesigned component item: $newItemId" }
    if ($recipesText -notmatch "AuxiliasAmmunition\.$([regex]::Escape($newItemId))\b") {
        throw "Redesigned component item is not referenced by a recipe: $newItemId"
    }
}

$bodyRecipes = @(
    @('AuxAmmoCastSmallPistolProjectiles','SmallPistolBody',30),
    @('AuxAmmoCastHeavyPistolProjectiles','HeavyPistolBody',20),
    @('AuxAmmoCastRifleProjectiles','RifleBody',15),
    @('AuxAmmoCastShotCharges','ShotgunBody',15)
)
$pressRecipeIds = @($bodyRecipes | ForEach-Object { $_[0] }) + @(
    'AuxAmmoAssemble9mm','AuxAmmoAssemble38',
    'AuxAmmoAssemble357','AuxAmmoAssemble45','AuxAmmoAssemble44',
    'AuxAmmoAssemble556','AuxAmmoAssemble3030','AuxAmmoAssemble308','AuxAmmoAssembleShotgun'
)
if ($pressRecipeIds.Count -ne 13) { throw 'Expected 13 press-based production recipes.' }
foreach ($pressRecipeId in $pressRecipeIds) {
    $pressRecipe = [regex]::Match($recipesText, "(?ms)^    craftRecipe\s+$([regex]::Escape($pressRecipeId))\s*\{(?<body>.*?)^    \}")
    if (-not $pressRecipe.Success -or $pressRecipe.Groups['body'].Value -notmatch '(?m)^\s*Tags\s*=\s*AuxAmmoPress,') {
        throw "Recipe must use the dedicated ammunition press: $pressRecipeId"
    }
}
if (([regex]::Matches($recipesText, '(?m)^\s*Tags\s*=\s*AuxAmmoPress,')).Count -ne 13) {
    throw 'Only the 13 intended recipes may use the ammunition press.'
}
if ($recipesText -match '(?m)^\s*Tags\s*=\s*(?:HandPress|Furnace|AdvancedFurnace|PotteryBench|KilnSmall|KilnLarge)\b') {
    throw 'The new workflow must not use former mold, furnace, or vanilla hand-press stations.'
}
foreach ($pair in $bodyRecipes) {
    $castRecipe = [regex]::Match($recipesText, "(?ms)^    craftRecipe\s+$([regex]::Escape($pair[0]))\s*\{(?<body>.*?)^    \}")
    if (-not $castRecipe.Success) { throw "Missing body recipe: $($pair[0])" }
    if ($castRecipe.Groups['body'].Value -notmatch "(?m)^\s*item\s+$($pair[2])\s+AuxiliasAmmunition\.$([regex]::Escape($pair[1])),") {
        throw "Pressing must produce $($pair[2]) bodies: $($pair[0]) -> $($pair[1])"
    }
    if ($castRecipe.Groups['body'].Value -notmatch '(?m)^\s*item\s+1\s+\[Base\.IronIngot\],') {
        throw "Body pressing must include one iron ingot: $($pair[0])"
    }
    if ($castRecipe.Groups['body'].Value -notmatch '(?m)^\s*item\s+1\s+\[Base\.CopperScrap\],') {
        throw "Body pressing must include one copper scrap: $($pair[0])"
    }
    if ($pair[1] -eq 'ShotgunBody' -and $castRecipe.Groups['body'].Value -notmatch '(?m)^\s*item\s+2\s+\[Base\.RippedSheets\],') {
        throw 'Shotgun body pressing must include two ripped sheets.'
    }
    if ($castRecipe.Groups['body'].Value -notmatch '(?m)^\s*Tags\s*=\s*AuxAmmoPress,') {
        throw "Body pressing must use the dedicated station: $($pair[0])"
    }
    if ($castRecipe.Groups['body'].Value -match 'AuxiliasAmmunition\.(?:BulletMold|ShotgunMold)' -or
        $castRecipe.Groups['body'].Value -match 'tags\[base:crudetongs;base:tongs\]' -or
        $castRecipe.Groups['body'].Value -match 'tags\[base:charcoal\]') {
        throw "Body pressing must not require a ceramic mold, furnace tongs, or fuel: $($pair[0])"
    }
}
if ($itemsText -notmatch '(?ms)item\s+ShotgunBody\s*\{[^}]*WorldStaticModel\s*=\s*Base\.ShotGunShells,') {
    throw 'Shotgun body must use the verified vanilla shotgun-shell ground model.'
}

$allowedTags = @('AuxAmmoPress','AnySurfaceCraft','CanBeDoneFromFloor')
foreach ($match in [regex]::Matches($recipesText, '(?m)^\s*Tags\s*=\s*([^,]+),')) {
    foreach ($tag in $match.Groups[1].Value.Split(';')) { if ($tag.Trim() -notin $allowedTags) { throw "Unknown workstation tag: $tag" } }
}
$allowedSkills = @('Pottery','Blacksmith','MetalWelding','Farming','PlantScavenging','Reloading','Woodwork')
foreach ($match in [regex]::Matches($recipesText, '(?m)^\s*(?:SkillRequired|xpAward|AutoLearnAll)\s*=\s*([^,]+),')) {
    foreach ($pair in $match.Groups[1].Value.Split(';')) {
        $skill = $pair.Split(':')[0].Trim()
        if ($skill -notin $allowedSkills) { throw "Unknown internal skill ID: $skill" }
    }
}

$expectedAmmo = @('Bullets9mm','Bullets45','Bullets44','Bullets38','Bullets357','556Bullets','3030Bullets','308Bullets','ShotgunShells')
foreach ($ammo in $expectedAmmo) {
    $matches = [regex]::Matches($recipesText, "(?m)^\s*item\s+10\s+Base\.$([regex]::Escape($ammo)),\s*$")
    if ($matches.Count -ne 1) { throw "Expected one ten-round output for Base.$ammo; found $($matches.Count)." }
}
if (([regex]::Matches($recipesText, '(?m)^\s*item\s+10\s+Base\.(?:Bullets|\d|Shotgun)')).Count -ne 9) { throw 'Unexpected final ammunition output count.' }
if ($recipesText -match 'Base\.GunPowder') { throw 'Renewable recipes must not produce or consume vanilla Base.GunPowder.' }

$assemblyBodies = [ordered]@{
    AuxAmmoAssemble9mm = 'SmallPistolBody'
    AuxAmmoAssemble38 = 'SmallPistolBody'
    AuxAmmoAssemble357 = 'SmallPistolBody'
    AuxAmmoAssemble45 = 'HeavyPistolBody'
    AuxAmmoAssemble44 = 'HeavyPistolBody'
    AuxAmmoAssemble556 = 'RifleBody'
    AuxAmmoAssemble3030 = 'RifleBody'
    AuxAmmoAssemble308 = 'RifleBody'
    AuxAmmoAssembleShotgun = 'ShotgunBody'
}
$assemblyPowder = @{
    AuxAmmoAssemble9mm = 10
    AuxAmmoAssemble38 = 10
    AuxAmmoAssemble357 = 15
    AuxAmmoAssemble45 = 12
    AuxAmmoAssemble44 = 16
    AuxAmmoAssemble556 = 16
    AuxAmmoAssemble3030 = 18
    AuxAmmoAssemble308 = 20
    AuxAmmoAssembleShotgun = 20
}
foreach ($assembly in $assemblyBodies.GetEnumerator()) {
    $recipe = [regex]::Match($recipesText, "(?ms)^    craftRecipe\s+$([regex]::Escape($assembly.Key))\s*\{(?<body>.*?)^    \}")
    if (-not $recipe.Success) { throw "Missing final ammunition recipe: $($assembly.Key)" }
    $inputSection = [regex]::Match($recipe.Groups['body'].Value, '(?ms)^\s{8}inputs\s*\{(?<lines>.*?)^\s{8}\}')
    if (-not $inputSection.Success) { throw "Missing final ammunition inputs: $($assembly.Key)" }
    $lines = $inputSection.Groups['lines'].Value
    if (([regex]::Matches($lines, '(?m)^\s*item\s+')).Count -ne 2 -or
        $lines -notmatch "(?m)^\s*item\s+10\s+\[AuxiliasAmmunition\.$([regex]::Escape($assembly.Value))\],\s*$" -or
        $lines -notmatch "(?m)^\s*item\s+$($assemblyPowder[$assembly.Key])\s+\[AuxiliasAmmunition\.SurvivalPropellant\],\s*$") {
        throw "Final ammunition must consume only 10 bodies and the intended field-powder amount: $($assembly.Key)"
    }
}

$carbonRecipe = [regex]::Match($recipesText, '(?ms)^    craftRecipe\s+AuxAmmoGrindCarbonPowder\s*\{(?<body>.*?)^    \}')
if (-not $carbonRecipe.Success -or
    $carbonRecipe.Groups['body'].Value -notmatch '\[Base\.CharcoalCrafted;Base\.Charcoal;Base\.Coke\]' -or
    $carbonRecipe.Groups['body'].Value -notmatch 'tags\[base:mortarpestle\] mode:keep' -or
    $carbonRecipe.Groups['body'].Value -notmatch '(?m)^\s*item\s+\d+\s+AuxiliasAmmunition\.CarbonPowder,') {
    throw 'Carbon-powder recipe must grind wood charcoal, charcoal, or coke into CarbonPowder.'
}
if ($carbonRecipe.Groups['body'].Value -notmatch '(?m)^\s*NeedToBeLearn\s*=\s*false,' -or
    $carbonRecipe.Groups['body'].Value -match '(?m)^\s*(?:SkillRequired|xpAward|AutoLearnAll)\s*=') {
    throw 'Carbon-powder grinding must require no manual or skill and award no Reloading XP.'
}
$propellantRecipe = [regex]::Match($recipesText, '(?ms)^    craftRecipe\s+AuxAmmoBlendSurvivalPropellant\s*\{(?<body>.*?)^    \}')
if (-not $propellantRecipe.Success -or
    $propellantRecipe.Groups['body'].Value -notmatch '\[AuxiliasAmmunition\.CarbonPowder\]' -or
    $propellantRecipe.Groups['body'].Value -notmatch '\[AuxiliasAmmunition\.NitrogenousMix\]') {
    throw 'Survival propellant must consume CarbonPowder and NitrogenousMix.'
}

function Assert-RecipeQuantities([string]$Id, [string[]]$Inputs, [string]$Output) {
    $recipe = [regex]::Match($recipesText, "(?ms)^    craftRecipe\s+$([regex]::Escape($Id))\s*\{(?<body>.*?)^    \}")
    if (-not $recipe.Success) { throw "Missing recipe quantity contract: $Id" }
    $inputSection = [regex]::Match($recipe.Groups['body'].Value, '(?ms)^\s{8}inputs\s*\{(?<lines>.*?)^\s{8}\}')
    $outputSection = [regex]::Match($recipe.Groups['body'].Value, '(?ms)^\s{8}outputs\s*\{(?<lines>.*?)^\s{8}\}')
    if (-not $inputSection.Success -or -not $outputSection.Success) { throw "Missing recipe input/output section: $Id" }
    foreach ($inputLine in $Inputs) {
        if ($inputSection.Groups['lines'].Value -notmatch "(?m)^\s*$([regex]::Escape($inputLine)),\s*$") {
            throw "Recipe input quantity changed: $Id -> $inputLine"
        }
    }
    if ($outputSection.Groups['lines'].Value -notmatch "(?m)^\s*$([regex]::Escape($Output)),\s*$") {
        throw "Recipe output quantity changed: $Id -> $Output"
    }
}
Assert-RecipeQuantities 'AuxAmmoRefineMineralSalts' @('item 2 [Base.Stone2;Base.Limestone]') 'item 40 AuxiliasAmmunition.MineralSalts'
Assert-RecipeQuantities 'CraftAmmoPress' @('item 3 [Base.Plank]','item 1 [Base.IronBar]','item 2 [Base.IronBand]','item 1 [Base.SmallSheetMetal]','item 6 [Base.Nails]') 'item 1 AuxiliasAmmunition.Mov_AmmoPress'
Assert-RecipeQuantities 'AuxAmmoGrindCarbonPowder' @('item 8 [Base.CharcoalCrafted;Base.Charcoal;Base.Coke]') 'item 40 AuxiliasAmmunition.CarbonPowder'
Assert-RecipeQuantities 'AuxAmmoPrepareNitrogenousMixFromCompost' @('item 2 [Base.CompostBag]') 'item 1 AuxiliasAmmunition.NitrogenousMix'
Assert-RecipeQuantities 'AuxAmmoPrepareNitrogenousMixFromFertilizer' @('item 2 [Base.Fertilizer]') 'item 1 AuxiliasAmmunition.NitrogenousMix'
Assert-RecipeQuantities 'AuxAmmoBlendSurvivalPropellant' @('item 40 [AuxiliasAmmunition.MineralSalts]','item 40 [AuxiliasAmmunition.CarbonPowder]','item 1 [AuxiliasAmmunition.NitrogenousMix]') 'item 40 AuxiliasAmmunition.SurvivalPropellant'

$customReferences = @([regex]::Matches($recipesText, 'AuxiliasAmmunition\.([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
foreach ($reference in $customReferences) { if ($reference -notin $itemIds) { throw "Undeclared custom item reference: $reference" } }
$manualCoverage = @([regex]::Matches($itemsText, '(?:AuxAmmo[A-Za-z0-9_]+|CraftAmmoPress)') | ForEach-Object { $_.Value } | Where-Object { $_ -in $recipeIds })
foreach ($recipeId in @($expectedRecipeIds | Where-Object { $_ -notin @('AuxAmmoGrindCarbonPowder','AuxAmmoPrepareNitrogenousMixFromCompost','AuxAmmoPrepareNitrogenousMixFromFertilizer') })) {
    if (($manualCoverage | Where-Object { $_ -eq $recipeId }).Count -ne 1) { throw "Established recipe must appear in exactly one manual: $recipeId" }
}
foreach ($recipeId in @('AuxAmmoGrindCarbonPowder','AuxAmmoPrepareNitrogenousMixFromCompost','AuxAmmoPrepareNitrogenousMixFromFertilizer')) {
    if ($recipeId -in $manualCoverage) { throw "Preparation recipe must not require a manual: $recipeId" }
    $recipe = [regex]::Match($recipesText, "(?ms)^    craftRecipe\s+$recipeId\s*\{(?<body>.*?)^    \}")
    if (-not $recipe.Success -or $recipe.Groups['body'].Value -notmatch '(?m)^\s*NeedToBeLearn\s*=\s*false,') {
        throw "Preparation recipe must be available without a manual: $recipeId"
    }
}

$customIconAssignments = [ordered]@{
    Mov_AmmoPress = 'AuxAmmoPress'
    SmallPistolBody = 'AuxAmmoSmallPistolBody'
    HeavyPistolBody = 'AuxAmmoHeavyPistolBody'
    RifleBody = 'AuxAmmoRifleBody'
    ShotgunBody = 'AuxAmmoShotgunBody'
    CarbonPowder = 'AuxAmmoCarbonPowder'
    NitrogenousMix = 'AuxAmmoNitrogenousMix'
}
$vanillaIcons = @('Limestone','GunpowderJar','Magazine_Armory1','Magazine_Armory2','Magazine_Metalworking2')
foreach ($icon in @([regex]::Matches($itemsText, '(?m)^\s*Icon\s*=\s*([^,]+),') | ForEach-Object { $_.Groups[1].Value.Trim() })) {
    if ($icon -in $vanillaIcons) { continue }
    $iconPath = Join-Path $versionRoot "media\textures\Item_$icon.png"
    if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) { throw "Missing custom icon: $iconPath" }
    $size = Get-PngSize $iconPath
    if ($size.Width -ne 32 -or $size.Height -ne 32) { throw "Inventory icon must be 32x32: $iconPath" }
}

$sourceIconHashes = @()
$runtimeIconHashes = @()
foreach ($assignment in $customIconAssignments.GetEnumerator()) {
    $itemPattern = "(?ms)^\s*item\s+$([regex]::Escape($assignment.Key))\s*\{.*?^\s*Icon\s*=\s*$([regex]::Escape($assignment.Value)),.*?^\s*\}"
    if ($itemsText -notmatch $itemPattern) {
        throw "Dedicated icon assignment is missing: $($assignment.Key) -> $($assignment.Value)"
    }

    $sourceIconPath = Join-Path $repoRoot "source-assets\icons\Item_$($assignment.Value).png"
    $runtimeIconPath = Join-Path $versionRoot "media\textures\Item_$($assignment.Value).png"
    foreach ($iconCheck in @(@($sourceIconPath, 128), @($runtimeIconPath, 32))) {
        if (-not (Test-Path -LiteralPath $iconCheck[0] -PathType Leaf)) {
            throw "Missing dedicated icon: $($iconCheck[0])"
        }
        $iconSize = Get-PngSize $iconCheck[0]
        if ($iconSize.Width -ne $iconCheck[1] -or $iconSize.Height -ne $iconCheck[1]) {
            throw "Dedicated icon must be $($iconCheck[1])x$($iconCheck[1]): $($iconCheck[0])"
        }
        $alphaRange = Get-PngAlphaRange $iconCheck[0]
        if ($alphaRange.Minimum -ne 0 -or $alphaRange.Maximum -ne 255) {
            throw "Dedicated icon must contain transparent background and opaque subject pixels: $($iconCheck[0])"
        }
    }
    $sourceIconHashes += (Get-FileHash -LiteralPath $sourceIconPath -Algorithm SHA256).Hash
    $runtimeIconHashes += (Get-FileHash -LiteralPath $runtimeIconPath -Algorithm SHA256).Hash
}
if (@($sourceIconHashes | Select-Object -Unique).Count -ne $customIconAssignments.Count) {
    throw 'Dedicated 128x128 icon masters must all be visually distinct files.'
}
if (@($runtimeIconHashes | Select-Object -Unique).Count -ne $customIconAssignments.Count) {
    throw 'Dedicated 32x32 runtime icons must all be visually distinct files.'
}

$translationFiles = @('IG_UI.json','ItemName.json','Moveables.json','Recipes.json','Tooltip.json')
$translations = @{}
foreach ($language in @('EN','KO')) {
    $translations[$language] = @{}
    foreach ($file in $translationFiles) {
        $path = Join-Path $translationRoot "$language\$file"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing translation: $path" }
        $json = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
        $keys = @($json.PSObject.Properties.Name | Sort-Object)
        foreach ($property in $json.PSObject.Properties) { if ($property.Value -isnot [string] -or [string]::IsNullOrWhiteSpace($property.Value)) { throw "Empty translation: $path -> $($property.Name)" } }
        $translations[$language][$file] = $keys
    }
}
foreach ($file in $translationFiles) {
    if (($translations.EN[$file] -join "`n") -ne ($translations.KO[$file] -join "`n")) { throw "EN/KO key mismatch: $file" }
}
if ('Ammo_Press' -notin $translations.EN['Moveables.json'] -or
    'Tooltip_item_AuxAmmo_Press' -notin $translations.EN['Tooltip.json']) {
    throw 'Tabletop press moveable name or item tooltip translation is missing.'
}
$itemTranslationKeys = $translations.EN['ItemName.json']
foreach ($id in $itemIds) { if ("AuxiliasAmmunition.$id" -notin $itemTranslationKeys) { throw "Missing item translation: $id" } }
$recipeTranslationKeys = $translations.EN['Recipes.json']
foreach ($id in $recipeIds) { if ($id -notin $recipeTranslationKeys) { throw "Missing recipe translation: $id" } }
if (@($recipeTranslationKeys | Where-Object { $_ -like 'Recipe_*' }).Count -gt 0) {
    throw 'Build 42 Recipes.json keys must match craftRecipe IDs without a Recipe_ prefix.'
}

$luaFiles = @(Get-ChildItem -LiteralPath (Join-Path $versionRoot 'media\lua') -Recurse -Filter '*.lua' -File)
if ($luaFiles.Count -ne 4 -or @($luaFiles | Where-Object { $_.FullName -notin @($lootPath, $pressWorldPath, $pressContextIconPath, $pressLeftClickPath) }).Count -gt 0) {
    throw 'The release may contain only the server loot, shared press-world, client press-icon, and client press-left-click Lua files.'
}
$lootText = Get-Content -LiteralPath $lootPath -Raw
$pressWorldText = Get-Content -LiteralPath $pressWorldPath -Raw
$pressContextIconText = Get-Content -LiteralPath $pressContextIconPath -Raw
$pressLeftClickText = Get-Content -LiteralPath $pressLeftClickPath -Raw
foreach ($requiredLootToken in @('Events.OnPreDistributionMerge.Add','lootInjected','GunStoreLiterature')) {
    if ($lootText -notmatch [regex]::Escape($requiredLootToken)) { throw "Loot integration is incomplete: $requiredLootToken" }
}
$allRuntimeText = $itemsText + $recipesText + $pressText + $lootText + $pressWorldText + $pressContextIconText + $pressLeftClickText
if ($allRuntimeText -match '(?i)primer|뇌관|LegacyAmmunition') {
    throw 'Retired primer and legacy-part content must not remain in runtime files.'
}
foreach ($forbidden in @('OnWeaponSwingHitPoint','OnWeaponSwing','OnPlayerAttackFinished','modData','sendClientCommand','sendServerCommand','OnTick','spent casing','SpentCasing')) {
    if ($allRuntimeText -match [regex]::Escape($forbidden)) { throw "Forbidden v1 runtime feature found: $forbidden" }
}

$distributionImages = @(
    (Join-Path $repoRoot 'workshop\preview.png'),
    (Join-Path $modRoot 'poster.png'),
    (Join-Path $modRoot 'icon.png'),
    (Join-Path $versionRoot 'poster.png'),
    (Join-Path $versionRoot 'icon.png')
)
$hashes = @()
foreach ($image in $distributionImages) {
    $size = Get-PngSize $image
    if ($size.Width -ne 512 -or $size.Height -ne 512) { throw "Workshop image must be 512x512: $image" }
    $hashes += (Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash
}
if (@($hashes | Select-Object -Unique).Count -ne 1) { throw 'Workshop preview and every root/versioned poster and icon must be identical.' }
$coverSize = Get-PngSize (Join-Path $repoRoot 'source-assets\workshop\AuxiliasAmmunition-cover-source.png')
if ($coverSize.Width -ne $coverSize.Height -or $coverSize.Width -lt 1254) { throw 'Workshop cover source must be square and at least 1254px.' }

Write-Host "Auxilia's Ammunition validation passed: 12 items, 19 recipes, 9 vanilla calibers, tabletop press, EN/KO parity."

param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$monorepoRoot = [System.IO.Path]::GetFullPath((Join-Path $repoRoot '..\..'))
$target = (Get-Content -LiteralPath (Join-Path $monorepoRoot 'config\project-zomboid.json') -Raw | ConvertFrom-Json).target
$releaseLine = [string]$target.releaseLine
$modRoot = Join-Path $repoRoot 'workshop\Contents\mods\AuxiliasAmmunition'
$versionRoot = Join-Path $modRoot $releaseLine
$scriptRoot = Join-Path $versionRoot 'media\scripts'
$translationRoot = Join-Path $versionRoot 'media\lua\shared\Translate'
$itemsPath = Join-Path $scriptRoot 'auxilias_ammunition_items.txt'
$recipesPath = Join-Path $scriptRoot 'auxilias_ammunition_recipes.txt'
$modelsPath = Join-Path $scriptRoot 'auxilias_ammunition_models.txt'
$lootPath = Join-Path $versionRoot 'media\lua\server\AuxiliasAmmunition_Loot.lua'

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
    (Join-Path $versionRoot 'mod.info'), $itemsPath, $recipesPath, $modelsPath, $lootPath,
    (Join-Path $repoRoot 'tools\sync-icons.ps1'),
    (Join-Path $repoRoot 'source-assets\workshop\AuxiliasAmmunition-cover-source.png'),
    (Join-Path $repoRoot 'source-assets\icons\AuxAmmoShotgunMold-source.png')
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
}

$itemsText = Get-Content -LiteralPath $itemsPath -Raw
$recipesText = Get-Content -LiteralPath $recipesPath -Raw
$modelsText = Get-Content -LiteralPath $modelsPath -Raw
foreach ($entry in @(@($itemsPath, $itemsText), @($recipesPath, $recipesText), @($modelsPath, $modelsText))) {
    if (([regex]::Matches($entry[1], '\{')).Count -ne ([regex]::Matches($entry[1], '\}')).Count) { throw "Unbalanced braces: $($entry[0])" }
}
if ($itemsText -match '(?m)^\s*module\s+Base\s*$' -or $recipesText -match '(?m)^\s*module\s+Base\s*$') { throw 'Items and recipes may not override module Base.' }

$itemIds = @([regex]::Matches($itemsText, '(?m)^\s*item\s+([A-Za-z0-9_]+)\s*$') | ForEach-Object { $_.Groups[1].Value })
$recipeIds = @([regex]::Matches($recipesText, '(?m)^\s*craftRecipe\s+([A-Za-z0-9_]+)\s*$') | ForEach-Object { $_.Groups[1].Value })
if ($itemIds.Count -ne 19 -or @($itemIds | Select-Object -Unique).Count -ne 19) { throw "Expected 19 unique items; found $($itemIds.Count)." }
if ($recipeIds.Count -ne 24 -or @($recipeIds | Select-Object -Unique).Count -ne 24) { throw "Expected 24 unique craft recipes; found $($recipeIds.Count)." }
if (([regex]::Matches($recipesText, '(?m)^\s*NeedToBeLearn\s*=\s*true,')).Count -ne 24) { throw 'Every recipe must require knowledge.' }

$allowedTags = @('PotteryBench','KilnSmall','KilnLarge','Furnace','AdvancedFurnace','HandPress','WoodCharcoal')
foreach ($match in [regex]::Matches($recipesText, '(?m)^\s*Tags\s*=\s*([^,]+),')) {
    foreach ($tag in $match.Groups[1].Value.Split(';')) { if ($tag.Trim() -notin $allowedTags) { throw "Unknown workstation tag: $tag" } }
}
$allowedSkills = @('Pottery','Blacksmith','MetalWelding','Farming','PlantScavenging','Reloading')
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

$customReferences = @([regex]::Matches($recipesText, 'AuxiliasAmmunition\.([A-Za-z0-9_]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
foreach ($reference in $customReferences) { if ($reference -notin $itemIds) { throw "Undeclared custom item reference: $reference" } }
$manualCoverage = @([regex]::Matches($itemsText, 'AuxAmmo[A-Za-z0-9_]+') | ForEach-Object { $_.Value } | Where-Object { $_ -in $recipeIds })
foreach ($recipeId in $recipeIds) { if (($manualCoverage | Where-Object { $_ -eq $recipeId }).Count -ne 1) { throw "Recipe must appear in exactly one manual: $recipeId" } }

$customIconAssignments = [ordered]@{
    ShotgunMold = 'AuxAmmoShotgunMold'
    SmallPistolProjectile = 'AuxAmmoSmallPistolProjectile'
    HeavyPistolProjectile = 'AuxAmmoHeavyPistolProjectile'
    RifleProjectile = 'AuxAmmoRifleProjectile'
    ShotCharge = 'AuxAmmoShotCharge'
    SmallPistolCasing = 'AuxAmmoSmallPistolCasing'
    HeavyPistolCasing = 'AuxAmmoHeavyPistolCasing'
    RifleCasing = 'AuxAmmoRifleCasing'
    ShotgunHull = 'AuxAmmoShotgunHull'
    ImprovisedPrimer = 'AuxAmmoImprovisedPrimer'
    FactoryPrimer = 'AuxAmmoFactoryPrimer'
}
$vanillaIcons = @('ClayMold_GlassPane_Unfired','BulletMold','Limestone','GunpowderJar','Magazine_Armory1','Magazine_Armory2','Magazine_Metalworking2')
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

$translationFiles = @('IG_UI.json','ItemName.json','Recipes.json','Tooltip.json')
$translations = @{}
foreach ($language in @('EN','KO')) {
    $translations[$language] = @{}
    foreach ($file in $translationFiles) {
        $path = Join-Path $translationRoot "$language\$file"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing translation: $path" }
        $json = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $keys = @($json.PSObject.Properties.Name | Sort-Object)
        foreach ($property in $json.PSObject.Properties) { if ($property.Value -isnot [string] -or [string]::IsNullOrWhiteSpace($property.Value)) { throw "Empty translation: $path -> $($property.Name)" } }
        $translations[$language][$file] = $keys
    }
}
foreach ($file in $translationFiles) {
    if (($translations.EN[$file] -join "`n") -ne ($translations.KO[$file] -join "`n")) { throw "EN/KO key mismatch: $file" }
}
$itemTranslationKeys = $translations.EN['ItemName.json']
foreach ($id in $itemIds) { if ("AuxiliasAmmunition.$id" -notin $itemTranslationKeys) { throw "Missing item translation: $id" } }
$recipeTranslationKeys = $translations.EN['Recipes.json']
foreach ($id in $recipeIds) { if ("Recipe_$id" -notin $recipeTranslationKeys) { throw "Missing recipe translation: $id" } }

$luaFiles = @(Get-ChildItem -LiteralPath (Join-Path $versionRoot 'media\lua') -Recurse -Filter '*.lua' -File)
if ($luaFiles.Count -ne 1 -or $luaFiles[0].FullName -ne $lootPath) { throw 'The release may contain only the server loot-injection Lua file.' }
$lootText = Get-Content -LiteralPath $lootPath -Raw
foreach ($requiredLootToken in @('Events.OnPreDistributionMerge.Add','lootInjected','GunStoreLiterature','FactoryPrimer')) {
    if ($lootText -notmatch [regex]::Escape($requiredLootToken)) { throw "Loot integration is incomplete: $requiredLootToken" }
}
$allRuntimeText = $itemsText + $recipesText + $modelsText + $lootText
foreach ($forbidden in @('OnWeaponSwingHitPoint','OnWeaponSwing','OnPlayerAttackFinished','modData','sendClientCommand','sendServerCommand','OnTick','spent casing','SpentCasing')) {
    if ($allRuntimeText -match [regex]::Escape($forbidden)) { throw "Forbidden v1 runtime feature found: $forbidden" }
}

$distributionImages = @((Join-Path $repoRoot 'workshop\preview.png'), (Join-Path $modRoot 'poster.png'), (Join-Path $modRoot 'icon.png'))
$hashes = @()
foreach ($image in $distributionImages) {
    $size = Get-PngSize $image
    if ($size.Width -ne 512 -or $size.Height -ne 512) { throw "Workshop image must be 512x512: $image" }
    $hashes += (Get-FileHash -LiteralPath $image -Algorithm SHA256).Hash
}
if (@($hashes | Select-Object -Unique).Count -ne 1) { throw 'Workshop preview, poster, and icon must be identical.' }
$coverSize = Get-PngSize (Join-Path $repoRoot 'source-assets\workshop\AuxiliasAmmunition-cover-source.png')
if ($coverSize.Width -ne $coverSize.Height -or $coverSize.Width -lt 1254) { throw 'Workshop cover source must be square and at least 1254px.' }

Write-Host "Auxilia's Ammunition validation passed: 19 items, 24 recipes, 9 vanilla calibers, EN/KO parity."

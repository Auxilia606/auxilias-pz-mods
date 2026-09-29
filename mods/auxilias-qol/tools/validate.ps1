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
    (Join-Path $versionRoot 'media'),
    (Join-Path $versionRoot 'media\lua\client'),
    (Join-Path $versionRoot 'media\lua\shared')
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
$requiredFiles += @(
    (Join-Path $versionRoot 'media\lua\client\AQoLVehicleDismantleMenu.lua'),
    (Join-Path $versionRoot 'media\lua\shared\AQoLVehicleDismantle.lua'),
    (Join-Path $versionRoot 'media\lua\shared\Vehicles\TimedActions\ISAQoLDismantleVehicle.lua'),
    (Join-Path $versionRoot 'media\scripts\AQoLPhysicalSkillBooks.txt'),
    (Join-Path $versionRoot 'media\scripts\AQoLAdditionalSkillBooks.txt'),
    (Join-Path $versionRoot 'media\lua\shared\AQoLSkillBooks.lua'),
    (Join-Path $versionRoot 'media\lua\server\AQoLPhysicalSkillBooks.lua'),
    (Join-Path $versionRoot 'media\lua\shared\AQoLPhysicalSkillBooksForaging.lua'),
    (Join-Path $versionRoot 'media\lua\server\AQoLPhysicalSkillBooksLoot.lua')
)
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

$translationRoot = Join-Path $versionRoot 'media\lua\shared\Translate'
$skillNames = @{
    Fitness = @('Fitness', '체력'); Strength = @('Strength', '근력')
    Sprinting = @('Running', '능숙한 달리기')
    Lightfoot = @('Lightfooted', '조용한 발걸음')
    Nimble = @('Nimble', '조준시 발걸음')
    Sneak = @('Sneaking', '은밀한 움직임')
    Axe = @('Axe', '도끼')
    Blunt = @('Long Blunt', '긴 둔기')
    SmallBlunt = @('Short Blunt', '짧은 둔기')
    SmallBlade = @('Short Blade', '단검')
    Spear = @('Spear', '창')
}
$expectedKeys = @{
    'ContextMenu' = @('ContextMenu_AQoL_DismantleVehicle')
    'Tooltip' = @(
        'Tooltip_AQoL_DismantleVehicle', 'Tooltip_AQoL_VehicleUnavailable',
        'Tooltip_AQoL_StopVehicle', 'Tooltip_AQoL_DetachVehicle',
        'Tooltip_AQoL_EmptySeats', 'Tooltip_AQoL_RemoveAnimals',
        'Tooltip_AQoL_NeedMask',
        'Tooltip_AQoL_NeedTorch'
    )
    'IG_UI' = @('IGUI_AQoL_ConfirmDismantleVehicle')
    'ItemName' = @(foreach ($skill in $skillNames.Keys) {
        foreach ($tier in 1..5) { "AuxiliasQoL.Book$skill$tier" }
    })
}
foreach ($category in $expectedKeys.Keys) {
    foreach ($language in @('EN', 'KO')) {
        $translationPath = Join-Path $translationRoot "$language\$category.json"
        if (-not (Test-Path -LiteralPath $translationPath -PathType Leaf)) {
            throw "Missing translation file: $translationPath"
        }
        $translations = Get-Content -LiteralPath $translationPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $actualKeys = @($translations.PSObject.Properties.Name | Sort-Object)
        $requiredKeys = @($expectedKeys[$category] | Sort-Object)
        if (@(Compare-Object $actualKeys $requiredKeys).Count -ne 0) {
            throw "Unexpected translation keys in ${translationPath}: $($actualKeys -join ', ')"
        }
        foreach ($key in $requiredKeys) {
            if ([string]::IsNullOrWhiteSpace([string]$translations.$key)) {
                throw "Empty translation ${key}: $translationPath"
            }
        }
    }
}

$bookScript = (@(foreach ($name in @('AQoLPhysicalSkillBooks.txt', 'AQoLAdditionalSkillBooks.txt')) {
    $script = Get-Content -LiteralPath (Join-Path $versionRoot "media\scripts\$name") -Raw -Encoding UTF8
    if ($script -notmatch 'module\s+AuxiliasQoL\s*\{') { throw "Books must use the AuxiliasQoL module: $name" }
    $script
}) -join "`n")
$bookDefinitions = [regex]::Matches($bookScript, '(?s)\bitem\s+(\w+)\s*\{([^{}]*)\}')
if ($bookDefinitions.Count -ne 55) { throw 'Expected exactly 55 skill books.' }
$seen = @{}
foreach ($book in $bookDefinitions) {
    $id = $book.Groups[1].Value
    if ($id -notmatch '^Book([A-Za-z]+)([1-5])$' -or $seen.ContainsKey($id)) {
        throw "Unexpected or duplicate skill book: $id"
    }
    $skill, $tier = $Matches[1], [int]$Matches[2]
    if (-not $skillNames.ContainsKey($skill)) { throw "Unexpected book skill: $skill" }
    $seen[$id] = $true
    $fields = @{}
    foreach ($field in [regex]::Matches($book.Groups[2].Value, '(?m)^\s*(\w+)\s*=\s*([^,\r\n]+),')) {
        $fieldName = $field.Groups[1].Value
        if ($fields.ContainsKey($fieldName)) { throw "Duplicate $fieldName in $id" }
        $fields[$fieldName] = $field.Groups[2].Value.Trim()
    }
    $expected = @{
        DisplayCategory = 'SkillBook'; ItemType = 'base:literature'; Weight = '1.0'
        SkillTrained = $skill; LvlSkillTrained = [string](2 * $tier - 1)
        NumLevelsTrained = '2'; NumberOfPages = [string](180 + 40 * $tier)
        Icon = 'Book_Generic'; IconColorMask = 'Book_Generic_Mask'
        StaticModel = 'BookOpenTINT'; WorldStaticModel = 'BookClosedTINT'
    }
    foreach ($field in $expected.Keys) {
        if ($fields[$field] -cne $expected[$field]) { throw "Invalid $field in $id : $($fields[$field])" }
    }
    foreach ($channel in @('ColorRed', 'ColorGreen', 'ColorBlue')) {
        if ($fields[$channel] -notmatch '^\d+$' -or [int]$fields[$channel] -gt 255) {
            throw "Invalid $channel in $id"
        }
    }
    foreach ($language in @('EN', 'KO')) {
        $names = Get-Content (Join-Path $translationRoot "$language\ItemName.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        $title = [string]$names."AuxiliasQoL.$id"
        $prefix = if ($language -eq 'EN') { "$($skillNames[$skill][0]) $(@('I','II','III','IV','V')[$tier-1]): " }
                  else { "$($skillNames[$skill][1]) ${tier}권: " }
        if (-not $title.StartsWith($prefix) -or $title -notmatch ': "[^"\r\n]+"$') {
            throw "Skill book title does not follow vanilla naming: $language $id"
        }
    }
}

Write-Host "AuxiliasQoL validation passed for Project Zomboid $releaseLine (mod $version); 55 skill books, EN/KO names."

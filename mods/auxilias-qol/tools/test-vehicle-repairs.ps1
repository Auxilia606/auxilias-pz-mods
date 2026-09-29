param(
    [Parameter(Mandatory = $true)][string]$GameDirectory,
    [string]$JavaCompiler = 'javac'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '../..'))
$releaseLine = (Get-Content (Join-Path $repoRoot 'config/project-zomboid.json') -Raw | ConvertFrom-Json).target.releaseLine
$media = Join-Path $projectRoot "workshop/Contents/mods/AuxiliasQoL/$releaseLine/media"
$gameRoot = (Resolve-Path -LiteralPath $GameDirectory).Path
$testRoot = Join-Path $PSScriptRoot 'tests'
$work = Join-Path $projectRoot 'work/vehicle-repair-tests'
New-Item -ItemType Directory -Path $work -Force | Out-Null

# Independent oracle from installed item definitions and vehicle templates.
$normal = Get-Content (Join-Path $gameRoot 'media/scripts/generated/items/normal.txt') -Raw
$fixing = Get-Content (Join-Path $gameRoot 'media/scripts/generated/fixing.txt') -Raw
$oracle = @('vanillaRepairTargets = {')
$ids = @()
foreach ($definition in [regex]::Matches($normal, '(?s)\bitem\s+((?:Old|Normal|Modern)(?:Brake|Suspension|CarMuffler|Tire)[1-3])\s*\{([^{}]*)\}')) {
    $id, $body = $definition.Groups[1].Value, $definition.Groups[2].Value
    if ($body -notmatch 'MechanicsItem\s*=\s*true' -or $body -notmatch 'ConditionMax\s*=\s*100') {
        throw "Target is not a condition-bearing mechanics item: $id"
    }
    if ($body -match 'base:repairwith(tape|glue|epoxy)' -or $fixing -match "\bBase\.$id\b") {
        throw "Target now has a vanilla repair path; reassess coverage: $id"
    }
    $stem = $id -replace '[1-3]$', ''
    $family = if ($id -match 'CarMuffler') { 'muffler' } elseif ($id -match 'Suspension') { 'suspension' }
              elseif ($id -match 'Brake') { 'brake' } else { 'tire' }
    $template = Get-Content (Join-Path $gameRoot "media/scripts/generated/vehicles/template_$family.txt") -Raw
    if ($template -notmatch "\bBase\.$stem\b" -or $template -notmatch 'table uninstall' -or $template -match 'table repair') {
        throw "Vehicle template no longer supports the selected repair scope: $id"
    }
    $ids += "Base.$id"
    $oracle += '    ["Base.' + $id + '"] = true,'
}
if ($ids.Count -ne 33) { throw "Expected 33 shipped repair targets, found $($ids.Count)." }
$oracle += '}'
[IO.File]::WriteAllLines((Join-Path $work 'vanilla-repair-targets.lua'), $oracle)
$recipes = Get-Content (Join-Path $media 'scripts/AQoLVehicleRepairs.txt') -Raw
$recipeIds = @()
foreach ($inputLine in [regex]::Matches($recipes, 'item 1 \[([^\]]+)\] mode:keep flags\[Prop2;IsDamaged;AllowDestroyedItem\]')) {
    $recipeIds += $inputLine.Groups[1].Value.Split(';')
}
if ($recipeIds.Count -ne 33 -or @(Compare-Object ($ids | Sort-Object) ($recipeIds | Sort-Object)).Count) {
    throw 'Recipe inputs differ from the independently inspected vanilla parts.'
}
foreach ($material in @('ScrapMetal', 'TirePiece')) {
    if ($normal -notmatch "\bitem\s+$material\b") { throw "Missing repair material: $material" }
}

& $JavaCompiler -d $work (Join-Path $testRoot 'RunLua.java')
if ($LASTEXITCODE -ne 0) { throw 'Could not compile the Lua test runner.' }
$sources = @(
    (Join-Path $testRoot 'vehicle-repair-bootstrap.lua'),
    (Join-Path $work 'vanilla-repair-targets.lua'),
    (Join-Path $media 'lua/shared/Auxilia/SkillUtils.lua'),
    (Join-Path $media 'lua/shared/AQoLVehicleRepairConfig.lua'),
    (Join-Path $media 'lua/shared/AQoLVehicleRepair.lua'),
    (Join-Path $gameRoot 'media/lua/shared/Entity/TimedActions/ISHandcraftAction.lua'),
    (Join-Path $testRoot 'vehicle-repair-integration.lua')
)
Copy-Item -LiteralPath (Join-Path $gameRoot 'stdlib.lua') -Destination (Join-Path $work 'stdlib.lua') -Force
Push-Location -LiteralPath $work
try {
    # This Kahlua build increments errorCount twice for one pcall-caught Lua error.
    # The integration test deliberately raises exactly one Beyond Ten API error.
    & (Join-Path $gameRoot 'jre64/bin/java.exe') '-Dauxilia.expectedKahluaErrors=2' "-Duser.home=$work" "-Djava.library.path=$gameRoot" -cp "$work;$(Join-Path $gameRoot 'projectzomboid.jar')" RunLua @sources
    if ($LASTEXITCODE -ne 0) { throw 'Vehicle repair Lua integration checks failed.' }
}
finally { Pop-Location }

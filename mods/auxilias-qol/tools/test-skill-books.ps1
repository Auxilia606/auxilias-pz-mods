param(
    [Parameter(Mandatory = $true)][string]$GameDirectory,
    [string]$JavaCompiler = 'javac'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot '..\..'))
$releaseLine = (Get-Content (Join-Path $repoRoot 'config/project-zomboid.json') -Raw | ConvertFrom-Json).target.releaseLine
$media = Join-Path $projectRoot "workshop/Contents/mods/AuxiliasQoL/$releaseLine/media"
$gameRoot = (Resolve-Path -LiteralPath $GameDirectory).Path
$gameLua = Join-Path $gameRoot 'media/lua'
$gameJar = Join-Path $gameRoot 'projectzomboid.jar'
$gameJava = Join-Path $gameRoot 'jre64/bin/java.exe'
$testRoot = Join-Path $PSScriptRoot 'tests'
$work = Join-Path $projectRoot 'work/skill-book-tests'
New-Item -ItemType Directory -Path $work -Force | Out-Null

& $JavaCompiler -d $work (Join-Path $testRoot 'RunLua.java')
if ($LASTEXITCODE -ne 0) { throw 'Could not compile the Lua test runner.' }
$sources = @(
    (Join-Path $testRoot 'book-bootstrap.lua'),
    (Join-Path $gameLua 'server/XpSystem/XPSystem_SkillBook.lua'),
    (Join-Path $media 'lua/shared/AQoLSkillBooks.lua'),
    (Join-Path $media 'lua/server/AQoLPhysicalSkillBooks.lua'),
    (Join-Path $media 'lua/server/AQoLPhysicalSkillBooks.lua'),
    (Join-Path $gameLua 'server/Items/Distribution_BinJunk.lua'),
    (Join-Path $gameLua 'server/Items/Distribution_ClosetJunk.lua'),
    (Join-Path $gameLua 'server/Items/Distribution_CounterJunk.lua'),
    (Join-Path $gameLua 'server/Items/Distribution_DeskJunk.lua'),
    (Join-Path $gameLua 'server/Items/Distribution_ShelfJunk.lua'),
    (Join-Path $gameLua 'server/Items/Distribution_SideTableJunk.lua'),
    (Join-Path $gameLua 'server/Items/Distribution_BagsAndContainers.lua'),
    (Join-Path $gameLua 'server/Items/ProceduralDistributions.lua'),
    (Join-Path $gameLua 'server/Items/Distributions.lua'),
    (Join-Path $gameLua 'server/Vehicles/VehicleDistributions.lua'),
    (Join-Path $gameLua 'server/RandomizedWorldContent/StoryClutter/StoryClutter_Definitions.lua'),
    (Join-Path $gameLua 'shared/Foraging/Categories/Junk.lua'),
    (Join-Path $media 'lua/shared/AQoLPhysicalSkillBooksForaging.lua'),
    (Join-Path $media 'lua/shared/AQoLPhysicalSkillBooksForaging.lua'),
    (Join-Path $media 'lua/server/AQoLPhysicalSkillBooksLoot.lua'),
    (Join-Path $work 'vanilla-book-ids.lua'),
    (Join-Path $testRoot 'book-loot-integration.lua'),
    (Join-Path $gameLua 'shared/TimedActions/ISReadABook.lua'),
    (Join-Path $testRoot 'book-integration.lua')
)
# Independent coverage oracle from the installed item definitions, not the mod's ID list.
$literature = Get-Content (Join-Path $gameRoot 'media/scripts/generated/items/literature.txt') -Raw
$oracle = @('vanillaBookIds = {')
foreach ($book in [regex]::Matches($literature, '(?s)\bitem\s+(\w+)\s*\{([^{}]*\bSkillTrained\s*=[^{}]*)\}')) {
    $level = [int][regex]::Match($book.Groups[2].Value, 'LvlSkillTrained\s*=\s*(\d+)').Groups[1].Value
    $oracle += '    ["' + $book.Groups[1].Value + '"] = ' + (($level + 1) / 2) + ','
}
$oracle += '}'
[IO.File]::WriteAllLines((Join-Path $work 'vanilla-book-ids.lua'), $oracle)
Copy-Item -LiteralPath (Join-Path $gameRoot 'stdlib.lua') -Destination (Join-Path $work 'stdlib.lua') -Force
Push-Location -LiteralPath $work
try {
    & $gameJava "-Duser.home=$work" "-Djava.library.path=$gameRoot" -cp "$work;$gameJar" RunLua @sources
    if ($LASTEXITCODE -ne 0) { throw 'Skill book Lua integration checks failed.' }
}
finally { Pop-Location }

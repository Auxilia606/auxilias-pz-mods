-- Only game-facing objects are fakes. Registration, loot and ISReadABook are
-- executed from their actual source files by test-skill-books.ps1.
function require() end
-- The test runner loads the actual clutter/container definitions below.
ClutterTables = {}
BagsAndContainers = {}
forageSystem = { forageDefinitions = {}, doGenericItemSpawn = function() end }
function forageSystem.addForageDef(key, definition)
    if string.match(key, "^AQoLBook") then
        assert(not forageSystem.forageDefinitions[key], "Duplicate mod foraging definition")
    end
    if not forageSystem.forageDefinitions[key] then forageSystem.forageDefinitions[key] = definition end
end
Perks = setmetatable({}, { __index = function(t, key) rawset(t, key, key); return key end })
local callbacks = {}
Events = { OnPreDistributionMerge = { Add = function(callback) table.insert(callbacks, callback) end } }
function runLootMerge()
    for _, callback in ipairs(callbacks) do callback() end
end
ISBaseTimedAction = {}
function ISBaseTimedAction:derive()
    local child = {}
    child.__index = child
    return setmetatable(child, { __index = self })
end
function ISBaseTimedAction:new() return setmetatable({}, self) end
CharacterTrait = { ILLITERATE = "Illiterate", FAST_READER = "FastReader", SLOW_READER = "SlowReader" }
CharacterStat = { BOREDOM = "Boredom", UNHAPPINESS = "Unhappiness", STRESS = "Stress" }
ItemTag = { FAST_READ = "FastRead" }
ItemBodyLocation = { EYES = "Eyes" }
function getSandboxOptions()
    return { getOptionByName = function() return { getValue = function() return 2 end } end }
end
function getGameTime()
    return { getMinutesPerDay = function() return 60 end, getMultiplier = function() return 1 end }
end
testServer = false
function isServer() return testServer end
function isClient() return false end
function syncItemFields() end
function sendSyncPlayerFields() end
function getText(key) return key end
function ZombRand() return 0 end
HaloTextHelper = { addGoodText = function() end, addBadText = function() end }
function addXpMultiplier(character, perk, multiplier, minLevel, maxLevel)
    character.multiplier[perk] = multiplier
    character.range[perk] = { minLevel, maxLevel }
end

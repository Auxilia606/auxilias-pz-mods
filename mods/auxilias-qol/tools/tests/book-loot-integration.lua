-- Independent expectations; do not derive the expected groups from the mod catalog.
local physical = {"Fitness", "Strength", "Sprinting", "Lightfoot", "Nimble", "Sneak"}
local melee = {"Axe", "Blunt", "SmallBlunt", "SmallBlade", "Spear"}
local skills, combat = {}, {}
local function hasEntries(values)
    for _ in pairs(values) do return true end
    return false
end
for _, skill in ipairs(physical) do table.insert(skills, skill) end
for _, skill in ipairs(melee) do table.insert(skills, skill); combat[skill] = true end
local function tierOf(value)
    if type(value) ~= "string" then return nil end
    return vanillaBookIds[(string.gsub(value, "^Base%.", ""))]
end
local function bladeTier(value)
    if type(value) ~= "string" then return nil end
    return tonumber(string.match(string.gsub(value, "^Base%.", ""), "^BookLongBlade([1-5])$"))
end
local preferred = {
    BookstoreSports={10,8,6,4,2}, LibrarySports={8,6,4,2,1},
    UniversityLibrarySports={8,6,6,4,2}, FitnessTrainer={8,6,4,2,1},
    GymLockers={6,4,3,2,1}, GymWeights={8,6,4,2,1}, SchoolGymSportsGear={8,6,4,2,1},
    BaseballLockers={4,3,2,1,0.5}, GolfLockers={4,3,2,1,0.5}, PoolLockers={4,3,2,1,0.5},
    SportStoreBoxing={6,4,3,2,1}, SportStorageWeights={6,4,3,2,1},
    ClassroomDesk={2,1.5,1,0.5,0.25}, ClassroomSecondaryDesk={2,1.5,1,0.5,0.25},
    ClassroomMisc={4,3,2,1,0.5}, ClassroomShelves={4,3,2,1,0.5},
    ClassroomSecondaryMisc={4,3,2,1,0.5}, ClassroomSecondaryShelves={4,3,2,1,0.5},
    SchoolLockers={2,1.5,1,0.5,0.25}, SchoolLockersBad={2,1.5,1,0.5,0.25},
    CrateBooksSchool={2,1.5,1,0.5,0.25}, UniversityLibraryBooks={4,3,12,6,3},
}

local bonusByItems = {}
local function bonus(name, targetSkills, weights)
    local pool = ProceduralDistributions.list[name]
    assert(pool and pool.items, "Missing themed pool: " .. name)
    local bySkill = bonusByItems[pool.items] or {}
    bonusByItems[pool.items] = bySkill
    for _, skill in ipairs(targetSkills) do bySkill[skill] = weights end
end
for name, weights in pairs(preferred) do bonus(name, physical, weights) end
bonus("LoggingFactoryTools", {"Axe"}, {2,1,0.5,0.1,0.05})
bonus("Hunter", {"SmallBlade", "Spear"}, {2,1,0.5,0.1,0.05})
bonus("HuntingLockers", {"SmallBlade", "Spear"}, {2,1,0.5,0.1,0.05})

local visited, snapshots, count, bladeCount = {}, {}, 0, 0
local function snapshot(node, path)
    if type(node) ~= "table" or visited[node] then return end
    visited[node] = true
    local before, general, blades = {}, {}, {}
    for i, value in ipairs(node) do before[i] = value end
    for i = 1, #node, 2 do
        local tier, weight = tierOf(node[i]), node[i+1]
        if tier and type(weight) == "number" and weight > 0 then
            general[tier] = math.max(general[tier] or 0, weight)
            if bladeTier(node[i]) then blades[tier] = math.max(blades[tier] or 0, weight) end
        end
    end
    if hasEntries(general) then count = count + 1 end
    if hasEntries(blades) then bladeCount = bladeCount + 1 end
    local wanted = {}
    for _, skill in ipairs(skills) do
        wanted[skill] = {}
        local source = combat[skill] and blades or general
        local floor = bonusByItems[node] and bonusByItems[node][skill] or {}
        for tier = 1, 5 do wanted[skill][tier] = math.max(source[tier] or 0, floor[tier] or 0) end
    end
    snapshots[node] = {before=before, wanted=wanted, path=path}
    for key, child in pairs(node) do
        if type(child) == "table" then snapshot(child, path .. "." .. tostring(key)) end
    end
end
snapshot(ProceduralDistributions.list, "Procedural")
snapshot(Distributions, "Distributions")
snapshot(SuburbsDistributions, "Suburbs")
snapshot(VehicleDistributions, "Vehicles")
snapshot(BagsAndContainers, "Bags")
snapshot(ClutterTables, "Clutter")
assert(count > 50 and bladeCount > 5, "Unexpectedly few vanilla loot lists")

local stories, storyCount = {}, 0
for _, items in pairs(StoryClutter) do
    local before, tiers, blades = {}, {}, {}
    for i, item in ipairs(items) do
        before[i] = item
        local tier = tierOf(item)
        if tier then tiers[tier] = true end
        if bladeTier(item) then blades[bladeTier(item)] = true end
    end
    if hasEntries(tiers) then storyCount = storyCount + 1 end
    stories[items] = {before=before, tiers=tiers, blades=blades}
end

runLootMerge()
runLootMerge()
local function weightOf(items, id)
    local found, weight = 0, nil
    for i = 1, #items, 2 do
        if items[i] == id then found = found + 1; weight = items[i+1] end
    end
    assert(found <= 1, "Duplicate book: " .. id)
    return weight
end
for items, check in pairs(snapshots) do
    for i, value in ipairs(check.before) do
        assert(items[i] == value, "Changed vanilla loot: " .. check.path)
    end
    local added = 0
    for _, skill in ipairs(skills) do
        for tier = 1, 5 do
            local expected = check.wanted[skill][tier]
            local actual = weightOf(items, "AuxiliasQoL.Book" .. skill .. tier)
            if expected > 0 then
                assert(actual == expected, "Wrong/missing weight: " .. check.path .. " " .. skill .. tier)
                added = added + 2
            else
                assert(actual == nil, "Book in forbidden pool: " .. check.path .. " " .. skill .. tier)
            end
        end
    end
    assert(#items == #check.before + added, "Unexpected addition: " .. check.path)
end
for items, check in pairs(stories) do
    for i, item in ipairs(check.before) do assert(items[i] == item) end
    local added = 0
    for _, skill in ipairs(skills) do
        local tiers = combat[skill] and check.blades or check.tiers
        for tier = 1, 5 do
            local found = 0
            for _, item in ipairs(items) do
                if item == "AuxiliasQoL.Book" .. skill .. tier then found = found + 1 end
            end
            assert(found == (tiers[tier] and 1 or 0), "Wrong story book: " .. skill .. tier)
            added = added + found
        end
    end
    assert(#items == #check.before + added)
end

-- Explicitly protect the school/gym exclusion and the medieval classroom exception.
for name in pairs(preferred) do
    local items = ProceduralDistributions.list[name].items
    for _, skill in ipairs(melee) do
        for tier = 1, 5 do
            assert(weightOf(items, "AuxiliasQoL.Book" .. skill .. tier) == nil,
                "Athletic/education bonus leaked to melee: " .. name)
        end
    end
end
for _, skill in ipairs(melee) do
    for tier, weight in ipairs({10,8,6,4,2}) do
        assert(weightOf(ProceduralDistributions.list.MedievalBooks.items,
            "AuxiliasQoL.Book" .. skill .. tier) == weight)
    end
end

local forageCount = 0
for _, skill in ipairs(skills) do
    for tier = 1, 5 do
        local source = combat[skill] and "LongBlade" or "Carpentry"
        local original = forageSystem.forageDefinitions["Book" .. source .. tier]
        local entry = forageSystem.forageDefinitions["AQoLBook" .. skill .. tier]
        if original then
            forageCount = forageCount + 1
            assert(entry and entry.type == "AuxiliasQoL.Book" .. skill .. tier)
            assert(entry.skill == original.skill and entry.xp == original.xp)
            assert(entry.zones ~= original.zones and entry.categories ~= original.categories)
            for zone, weight in pairs(original.zones) do assert(entry.zones[zone] == weight) end
            for i, category in ipairs(original.categories) do assert(entry.categories[i] == category) end
        else
            assert(entry == nil, "Foraging has no matching vanilla source for " .. skill)
        end
    end
end

-- Qualified IDs, different weights/tiers, unrelated mod IDs, aliases and cycles.
local fixture = {items={
    "Base.BookCarpentry3", 8, "Base.BookLongBlade3", 0.75,
    "BookLongBlade5", 0.05, "OtherMod.BookLongBlade2", 99,
}}
fixture.alias = fixture
ProceduralDistributions.list.AQoLTest = fixture
ProceduralDistributions.list.AQoLTestAlias = fixture
StoryClutter.AQoLTest = {"Base.BookLongBlade2", "BookCarpentry4", "OtherMod.BookLongBlade5"}
runLootMerge()
runLootMerge()
assert(#fixture.items == 8 + 4 * #skills)
for _, skill in ipairs(skills) do
    local prefix = "AuxiliasQoL.Book" .. skill
    assert(weightOf(fixture.items, prefix .. "3") == (combat[skill] and 0.75 or 8))
    assert(weightOf(fixture.items, prefix .. "5") == 0.05)
    assert(weightOf(fixture.items, prefix .. "2") == nil)
end
local storyPresent = {}
for _, id in ipairs(StoryClutter.AQoLTest) do assert(not storyPresent[id]); storyPresent[id] = true end
for _, skill in ipairs(skills) do
    assert(storyPresent["AuxiliasQoL.Book" .. skill .. "2"])
    assert(not storyPresent["AuxiliasQoL.Book" .. skill .. "5"])
    assert((storyPresent["AuxiliasQoL.Book" .. skill .. "4"] == true) == (not combat[skill]))
end
-- Raising/lowering an existing entry must preserve higher weights without duplicates.
for i = 1, #fixture.items, 2 do
    if fixture.items[i] == "AuxiliasQoL.BookAxe3" then fixture.items[i+1] = 0.1 end
    if fixture.items[i] == "AuxiliasQoL.BookSpear3" then fixture.items[i+1] = 2 end
end
runLootMerge()
runLootMerge()
assert(#fixture.items == 8 + 4 * #skills)
assert(weightOf(fixture.items, "AuxiliasQoL.BookAxe3") == 0.75)
assert(weightOf(fixture.items, "AuxiliasQoL.BookSpear3") == 2)
ProceduralDistributions.list.AQoLTest = nil
ProceduralDistributions.list.AQoLTestAlias = nil
StoryClutter.AQoLTest = nil
return "Covered " .. count .. " general and " .. bladeCount .. " LongBlade weighted lists, " ..
    storyCount .. " story lists, 22 athletic/education and 3 weapon-specific pools, " .. forageCount .. " foraging definitions."

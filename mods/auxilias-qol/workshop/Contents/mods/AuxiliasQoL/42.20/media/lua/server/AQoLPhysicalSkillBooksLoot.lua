require "Items/Distribution_BagsAndContainers"
require "AQoLSkillBooks"
require "Items/Distribution_BinJunk"
require "Items/Distribution_ClosetJunk"
require "Items/ProceduralDistributions"
require "Items/Distributions"
require "Vehicles/VehicleDistributions"
require "RandomizedWorldContent/StoryClutter/StoryClutter_Definitions"

-- Only shipped skill-book IDs can supply weights; exclude our books, magazines
-- and other mods so repeating the merge cannot inflate the base weights.
local vanillaSeries = {}
for _, name in ipairs({
    "Aiming", "Blacksmith", "Butchering", "Carpentry", "Carving", "Cooking",
    "Electrician", "Farming", "FirstAid", "Fishing", "FlintKnapping", "Foraging",
    "Glassmaking", "Husbandry", "LongBlade", "Maintenance", "Masonry",
    "Mechanic", "MetalWelding", "Pottery", "Reloading", "Tailoring", "Tracking", "Trapping",
}) do
    vanillaSeries["Book" .. name] = true
end

local function vanillaTier(fullType)
    if type(fullType) ~= "string" then return nil end
    local itemType = string.gsub(fullType, "^Base%.", "")
    local series, tier = string.match(itemType, "^(Book%a+)([1-5])$")
    if vanillaSeries[series] then return tonumber(tier), series end
end

-- Minimum weights, not extra entries or percentages. General locations inherit
-- their local vanilla weights; these athletic/education bonuses only apply to
-- physical and movement books.
local preferred = {
    BookstoreSports = { 10, 8, 6, 4, 2 },
    LibrarySports = { 8, 6, 4, 2, 1 },
    UniversityLibrarySports = { 8, 6, 6, 4, 2 },
    FitnessTrainer = { 8, 6, 4, 2, 1 },
    GymLockers = { 6, 4, 3, 2, 1 },
    GymWeights = { 8, 6, 4, 2, 1 },
    SchoolGymSportsGear = { 8, 6, 4, 2, 1 },
    BaseballLockers = { 4, 3, 2, 1, 0.5 },
    GolfLockers = { 4, 3, 2, 1, 0.5 },
    PoolLockers = { 4, 3, 2, 1, 0.5 },
    SportStoreBoxing = { 6, 4, 3, 2, 1 },
    SportStorageWeights = { 6, 4, 3, 2, 1 },
    ClassroomDesk = { 2, 1.5, 1, 0.5, 0.25 },
    ClassroomSecondaryDesk = { 2, 1.5, 1, 0.5, 0.25 },
    ClassroomMisc = { 4, 3, 2, 1, 0.5 },
    ClassroomShelves = { 4, 3, 2, 1, 0.5 },
    ClassroomSecondaryMisc = { 4, 3, 2, 1, 0.5 },
    ClassroomSecondaryShelves = { 4, 3, 2, 1, 0.5 },
    SchoolLockers = { 2, 1.5, 1, 0.5, 0.25 },
    SchoolLockersBad = { 2, 1.5, 1, 0.5, 0.25 },
    CrateBooksSchool = { 2, 1.5, 1, 0.5, 0.25 },
    UniversityLibraryBooks = { 4, 3, 12, 6, 3 },
}

-- Separate, modest floors for weapon-specific workplaces. These are balance
-- choices, not weights copied from vanilla LongBlade books.
local weaponPreferred = {
    LoggingFactoryTools = { skills = { "Axe" }, weights = { 2, 1, 0.5, 0.1, 0.05 } },
    Hunter = { skills = { "SmallBlade", "Spear" }, weights = { 2, 1, 0.5, 0.1, 0.05 } },
    HuntingLockers = { skills = { "SmallBlade", "Spear" }, weights = { 2, 1, 0.5, 0.1, 0.05 } },
}

local function ensureWeight(items, fullType, weight)
    for i = 1, #items, 2 do
        if items[i] == fullType then
            items[i + 1] = math.max(items[i + 1], weight)
            return
        end
    end
    table.insert(items, fullType)
    table.insert(items, weight)
end

local function addBooks(items, weights, lootTemplate)
    for tier = 1, 5 do
        if weights[tier] and weights[tier] > 0 then
            for _, series in ipairs(AQoLSkillBooks) do
                if series.lootTemplate == lootTemplate then
                    ensureWeight(items, "AuxiliasQoL.Book" .. series.skill .. tier, weights[tier])
                end
            end
        end
    end
end

local function injectBooks()
    -- Shared lists and aliases must be visited only once per merge.
    local visited = {}
    local function visit(node)
        if type(node) ~= "table" or visited[node] then return end
        visited[node] = true
        local weights, meleeWeights = {}, {}
        for i = 1, #node, 2 do
            local tier, source = vanillaTier(node[i])
            local weight = node[i + 1]
            if tier and type(weight) == "number" and weight > 0 then
                weights[tier] = math.max(weights[tier] or 0, weight)
                if source == "BookLongBlade" then
                    meleeWeights[tier] = math.max(meleeWeights[tier] or 0, weight)
                end
            end
        end
        addBooks(node, weights)
        addBooks(node, meleeWeights, "LongBlade")
        for _, child in pairs(node) do
            if type(child) == "table" then visit(child) end
        end
    end
    visit(ProceduralDistributions.list)
    visit(Distributions)
    visit(SuburbsDistributions)
    visit(VehicleDistributions)
    visit(BagsAndContainers)
    visit(ClutterTables)

    for name, weights in pairs(preferred) do
        local distribution = ProceduralDistributions.list[name]
        if distribution and distribution.items then
            addBooks(distribution.items, weights)
        else
            print("[AuxiliasQoL] Skill books: missing loot distribution " .. name)
        end
    end

    for name, bonus in pairs(weaponPreferred) do
        local distribution = ProceduralDistributions.list[name]
        if distribution and distribution.items then
            for _, skill in ipairs(bonus.skills) do
                for tier, weight in ipairs(bonus.weights) do
                    ensureWeight(distribution.items, "AuxiliasQoL.Book" .. skill .. tier, weight)
                end
            end
        else
            print("[AuxiliasQoL] Skill books: missing weapon loot distribution " .. name)
        end
    end

    -- Randomized building clutter uses unweighted lists, handled separately.
    for _, items in pairs(StoryClutter) do
        if type(items) == "table" then
            local tiers, meleeTiers, present = {}, {}, {}
            for _, fullType in ipairs(items) do
                if type(fullType) == "string" then
                    present[fullType] = true
                    local tier, source = vanillaTier(fullType)
                    if tier then tiers[tier] = true end
                    if source == "BookLongBlade" then meleeTiers[tier] = true end
                end
            end
            for tier = 1, 5 do
                if tiers[tier] then
                    for _, series in ipairs(AQoLSkillBooks) do
                        if not series.lootTemplate or meleeTiers[tier] then
                            local fullType = "AuxiliasQoL.Book" .. series.skill .. tier
                            if not present[fullType] then table.insert(items, fullType) end
                        end
                    end
                end
            end
        end
    end
end

Events.OnPreDistributionMerge.Add(injectBooks)

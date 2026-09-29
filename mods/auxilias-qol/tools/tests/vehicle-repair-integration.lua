local Repair = AQoLVehicleRepair
local Skill = AuxiliaSkillUtils
local player = { level = 0, getPerkLevel = function(self, perk)
    assert(perk == Perks.Mechanics)
    return self.level
end }
local function near(actual, expected)
    assert(math.abs(actual - expected) < 0.000001, tostring(actual) .. " ~= " .. tostring(expected))
end
local function item(fullType, condition, repairs)
    local result = { fullType = fullType or "Base.NormalBrake1", condition = condition or 0,
        repairs = repairs or 1, maximum = 100, carried = true, owner = player,
        tags = {}, syncs = 0, writes = 0, capacity = 27, identity = 123 }
    function result:getFullType() return self.fullType end
    function result:isInPlayerInventory() return self.carried end
    function result:getCondition() return self.condition end
    function result:getConditionMax() return self.maximum end
    function result:getHaveBeenRepaired() return self.repairs end
    function result:hasTag(tag) return self.tags[tag] == true end
    function result:getOutermostContainer()
        return { getParent = function() return self.owner end }
    end
    function result:setCondition(value) self.condition = value end
    function result:setHaveBeenRepaired(value) self.repairs = value; self.writes = self.writes + 1 end
    function result:syncItemFields() self.syncs = self.syncs + 1 end
    return result
end
local function data(inputs)
    return { getAllInputItems = function() return list(inputs) end }
end

assert(Skill.GetSkillLevel(nil, Perks.Mechanics) == 0)
assert(Skill.GetSkillLevel(player, nil) == 0)
for _, level in ipairs({0, 5, 10, 11, 12, 13, 14, 15, 20}) do
    player.level = level
    near(Repair.CalculateRepairAmount(player, 100), 100 + level * 2)
    near(Repair.GetIgnoreChance(player), math.min(level * 0.05, 0.75))
end
player.level = 5
BeyondTen = { GetEffectiveLevel = function(character, perk)
    assert(character == player and perk == Perks.Mechanics)
    return 15
end }
assert(Skill.GetSkillLevel(player, Perks.Mechanics) == 15)
BeyondTen.GetEffectiveLevel = function() error("optional API failed") end
assert(Skill.GetSkillLevel(player, Perks.Mechanics) == 5)
for _, invalid in ipairs({"15", -1, math.huge, -math.huge, 0/0, false}) do
    BeyondTen.GetEffectiveLevel = function() return invalid end
    assert(Skill.GetSkillLevel(player, Perks.Mechanics) == 5)
end
BeyondTen.GetEffectiveLevel = function() return nil end
assert(Skill.GetSkillLevel(player, Perks.Mechanics) == 5)
BeyondTen.GetEffectiveLevel = 15
assert(Skill.GetSkillLevel(player, Perks.Mechanics) == 5)
BeyondTen = false
assert(Skill.GetSkillLevel(player, Perks.Mechanics) == 5)
BeyondTen = nil

local count = 0
for fullType in pairs(Repair.Targets) do
    assert(vanillaRepairTargets[fullType], "Unverified target " .. fullType)
    local target = item(fullType)
    assert(Repair.OnTest(target))
    Repair.OnCreate(data({target}), player)
    assert(target.condition == 22 and target.repairs == 2 and target.writes == 1)
    assert(target.syncs == 1 and target.capacity == 27 and target.identity == 123)
    count = count + 1
end
assert(count == 33)
for fullType in pairs(vanillaRepairTargets) do assert(Repair.Targets[fullType]) end
for _, level in ipairs({0, 5, 10, 15}) do
    player.level = level
    local target = item()
    testRoll = 0.99
    Repair.OnCreate(data({target}), player)
    assert(target.condition == 20 + level * 0.4 and target.repairs == 2)
    testRoll = 0
    target = item()
    Repair.OnCreate(data({target}), player)
    assert(target.repairs == (level == 0 and 2 or 1))
    testRoll = Repair.GetIgnoreChance(player)
    assert(not Repair.RollIgnoreRepairCount(player), "Probability boundary must be exclusive")
end
player.level, testRoll = 15, 0.74
assert(Repair.RollIgnoreRepairCount(player))
player.level, testRoll = 0, 0.99
local target = item(nil, 0, 4)
Repair.OnCreate(data({target}), player)
assert(target.condition == 5 and target.repairs == 5)
target = item(nil, 0, 0)
Repair.OnCreate(data({target}), player)
assert(target.condition == 20 and target.repairs == 1)
target = item(nil, 99, 100)
Repair.OnCreate(data({target}), player)
assert(target.condition == 100 and target.repairs == 101)
local function rejected(target)
    local condition, repairs = target.condition, target.repairs
    Repair.OnCreate(data({target}), player)
    assert(target.condition == condition and target.repairs == repairs and target.syncs == 0)
end
rejected(item(nil, 100))
rejected(item("Base.EngineParts"))
rejected(item("OtherMod.NormalBrake1"))
target = item(); target.maximum = 0; rejected(target)
target = item(); target.condition = -1; rejected(target)
target = item(); target.carried = false; assert(not Repair.OnTest(target)); rejected(target)
target = item(); target.owner = {}; rejected(target)
target = item(); target.fixes = {"Another repair"}; assert(not Repair.OnTest(target)); rejected(target)
for _, tag in ipairs({"base:repairwithtape", "base:repairwithglue", "base:repairwithepoxy"}) do
    target = item(); target.tags[tag] = true; assert(not Repair.OnTest(target)); rejected(target)
end
assert(not Repair.CanRepairItem(nil) and not Repair.OnTest(nil))
assert(Repair.OnTest(item("Base.ScrapMetal")), "OnTest must allow material inputs")
Repair.OnCreate(nil, player)
Repair.OnCreate(data({}), player)
target = item()
Repair.OnCreate(data({target}), nil)
Repair.OnCreate(data({target, item()}), player)
assert(target.syncs == 0)

-- Execute the installed ISHandcraftAction (not a copied implementation).
-- Its SP perform / MP complete paths must consume once and roll once.
for _, mode in ipairs({"single", "server", "client", "cancelled"}) do
    testClient, testServer = mode == "client", mode == "server"
    target = item()
    local calls, consumptions, before = 0, 0, rollCount
    local recipeData = data({item("Base.Wrench"), target, item("Base.ScrapMetal")})
    function recipeData:luaCallOnCreate(character)
        calls = calls + 1
        Repair.OnCreate(self, character)
    end
    function recipeData:processDestroyAndUsedItems() consumptions = consumptions + 1 end
    local action = setmetatable({ character = player, eatPercentage = 0,
        clearItemsProgressBar = function() end,
        logic = { performCurrentRecipe = function() return true end,
            getCreatedOutputItems = function() end,
            getRecipeData = function() return recipeData end },
    }, ISHandcraftAction)
    if mode ~= "cancelled" then
        if mode ~= "server" then action:perform() end
        if mode ~= "client" then action:complete() end
    end
    local expected = (mode == "single" or mode == "server") and 1 or 0
    assert(calls == expected and consumptions == expected and target.syncs == expected)
    assert(rollCount - before == expected and target.writes == expected)
end
testClient = true
target = item()
Repair.OnCreate(data({target}), player)
assert(target.syncs == 0)
testClient, testServer = false, false
return "Vehicle repair: 33 shipped targets, formulas, fallback, rejection and vanilla SP/MP action paths passed."

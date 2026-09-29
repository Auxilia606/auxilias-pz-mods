require "Auxilia/SkillUtils"
require "AQoLVehicleRepairConfig"

local Repair = AQoLVehicleRepair

function Repair.GetMechanicsLevel(character)
    return AuxiliaSkillUtils.GetSkillLevel(character, Perks.Mechanics)
end

function Repair.CalculateRepairAmount(character, baseAmount)
    return baseAmount * (1 + Repair.GetMechanicsLevel(character)
        * Repair.Config.RepairAmountBonusPerLevel)
end

function Repair.GetIgnoreChance(character)
    return math.min(Repair.GetMechanicsLevel(character)
        * Repair.Config.IgnoreRepairCountPerLevel, Repair.Config.IgnoreRepairCountMax)
end

function Repair.RollIgnoreRepairCount(character)
    return ZombRandFloat(0, 1) < Repair.GetIgnoreChance(character)
end

function Repair.CanRepairItem(item)
    if not item or not Repair.Targets[item:getFullType()] then return false end
    -- syncItemFields targets player inventories in this build. Require pickup
    -- first; this also excludes installed parts and loose world/container items.
    if not item:isInPlayerInventory() then return false end
    if item:getConditionMax() <= 0 or item:getCondition() < 0
        or item:getCondition() >= item:getConditionMax() then return false end

    -- Yield to legacy Fixing definitions or generic crafting repairs added by
    -- another mod / future vanilla update. Do not hook either existing path.
    local fixes = FixingManager.getFixes(item)
    if fixes and fixes:size() > 0 then return false end
    return not item:hasTag("base:repairwithtape")
        and not item:hasTag("base:repairwithglue")
        and not item:hasTag("base:repairwithepoxy")
end

-- CraftRecipe.OnTest is an input-item predicate, including tools/materials.
function Repair.OnTest(item)
    if not item then return false end
    if Repair.Targets[item:getFullType()] then return Repair.CanRepairItem(item) end
    return true
end

function Repair.OnCreate(recipeData, character)
    -- ISHandcraftAction invokes this in SP or on the MP server. Never mutate
    -- client state or roll separately on each peer.
    if isClient() or not recipeData or not character then return end
    local inputs = recipeData:getAllInputItems()
    if not inputs then return end
    local target
    for index = 0, inputs:size() - 1 do
        local item = inputs:get(index)
        if item and Repair.Targets[item:getFullType()] then
            if target then return end
            target = item
        end
    end
    if not Repair.CanRepairItem(target) then return end
    local container = target:getOutermostContainer()
    if not container or container:getParent() ~= character then return end

    local condition = target:getCondition()
    local previousRepairs = target:getHaveBeenRepaired()
    local missing = target:getConditionMax() - condition
    local baseAmount = missing * Repair.Config.BaseMissingConditionFraction
        / math.max(previousRepairs, 1)
    local amount = math.max(Repair.Config.MinimumRepairAmount,
        math.floor(Repair.CalculateRepairAmount(character, baseAmount) + 0.5))
    target:setCondition(math.min(target:getConditionMax(), condition + amount))
    -- This recipe owns the repair; no vanilla fixing callback is invoked.
    -- Successful count-ignore leaves the exact previous value untouched.
    if not Repair.RollIgnoreRepairCount(character) then
        target:setHaveBeenRepaired(previousRepairs + 1)
    end
    target:syncItemFields()
end

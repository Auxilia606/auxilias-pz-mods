require "Items/ProceduralDistributions"
require "Items/Distribution_BagsAndContainers"

AuxiliaCrossbow = AuxiliaCrossbow or {}

local function addWeighted(items, fullType, weight)
    table.insert(items, fullType)
    table.insert(items, weight)
end

local function injectLoot()
    if AuxiliaCrossbow.lootInjected then
        return
    end
    AuxiliaCrossbow.lootInjected = true

    local safehouseLists = {
        "SafehouseArmor",
        "SafehouseArmor_Mid",
        "SafehouseArmor_Late",
        "SafehouseTraps",
        "SafehouseFireplace",
        "SafehouseFireplace_Late",
    }

    for _, listName in ipairs(safehouseLists) do
        local distribution = ProceduralDistributions.list[listName]
        if distribution and distribution.items then
            addWeighted(distribution.items, "AuxiliasCrossbow.ImprovisedCrossbow", 0.10)
            addWeighted(distribution.items, "AuxiliasCrossbow.ReinforcedCrossbow", 0.035)
            addWeighted(distribution.items, "AuxiliasCrossbow.HeavyArbalest", 0.008)
            addWeighted(distribution.items, "Base.AuxiliasCrossbowBolt", 0.35)
        end
    end

    if BagsAndContainers and BagsAndContainers.SurvivorItems then
        addWeighted(BagsAndContainers.SurvivorItems, "AuxiliasCrossbow.ImprovisedCrossbow", 0.08)
        addWeighted(BagsAndContainers.SurvivorItems, "AuxiliasCrossbow.ReinforcedCrossbow", 0.02)
        addWeighted(BagsAndContainers.SurvivorItems, "AuxiliasCrossbow.HeavyArbalest", 0.004)
        addWeighted(BagsAndContainers.SurvivorItems, "Base.AuxiliasCrossbowBolt", 0.20)
    end
end

Events.OnPreDistributionMerge.Add(injectLoot)


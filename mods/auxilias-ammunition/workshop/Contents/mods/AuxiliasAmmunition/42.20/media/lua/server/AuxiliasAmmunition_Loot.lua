require "Items/ProceduralDistributions"

AuxiliasAmmunition = AuxiliasAmmunition or {}

local function addWeighted(distributionName, fullType, weight)
    local distribution = ProceduralDistributions.list[distributionName]
    if not distribution or not distribution.items then
        return
    end
    table.insert(distribution.items, fullType)
    table.insert(distribution.items, weight)
end

local function injectLoot()
    if AuxiliasAmmunition.lootInjected then
        return
    end
    AuxiliasAmmunition.lootInjected = true

    addWeighted("GunStoreLiterature", "AuxiliasAmmunition.AmmunitionManual1", 0.70)
    addWeighted("GunStoreLiterature", "AuxiliasAmmunition.AmmunitionManual2", 0.40)
    addWeighted("GunStoreLiterature", "AuxiliasAmmunition.AmmunitionManual3", 0.18)
    addWeighted("ArmyStorageAmmunition", "AuxiliasAmmunition.AmmunitionManual3", 0.06)

end

Events.OnPreDistributionMerge.Add(injectLoot)

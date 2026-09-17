AuxiliaCrossbowCrafting = AuxiliaCrossbowCrafting or {}

local upgradeInputs = {
    ["AuxiliasCrossbow.ImprovisedCrossbow"] = true,
    ["AuxiliasCrossbow.ReinforcedCrossbow"] = true,
}

function AuxiliaCrossbowCrafting.canUseUpgradeItem(item)
    if upgradeInputs[item:getFullType()] then
        return item:getCurrentAmmoCount() == 0
    end
    return true
end

function AuxiliaCrossbowCrafting.finishUpgrade(recipeData)
    local consumed = recipeData:getAllConsumedItems()
    local source
    for index = 0, consumed:size() - 1 do
        local item = consumed:get(index)
        if upgradeInputs[item:getFullType()] then
            source = item
            break
        end
    end

    local result = recipeData:getFirstCreatedItem()
    if not source or not result then
        return
    end

    local ammoType = source:getAmmoType()
    if ammoType then
        result:setAmmoType(ammoType)
        result:syncItemFields()
    end
end

AuxiliaCrossbow = AuxiliaCrossbow or {}

local crossbows = {
    ["AuxiliasCrossbow.ImprovisedCrossbow"] = true,
    ["AuxiliasCrossbow.ReinforcedCrossbow"] = true,
    ["AuxiliasCrossbow.HeavyArbalest"] = true,
}

local STONE_AMMO_TYPE = "auxiliascrossbow:stonebolt"

local function getTargetInventory(target)
    if not target or not target.getInventory then
        return nil
    end

    local ok, inventory = pcall(function()
        return target:getInventory()
    end)

    if ok then
        return inventory
    end
    return nil
end

local function onWeaponHit(owner, weapon, hitObject, damage, hitCount)
    if isClient() and not isServer() then
        return
    end
    if not weapon or not crossbows[weapon:getFullType()] then
        return
    end
    if not damage or damage <= 0 or not hitCount or hitCount <= 0 then
        return
    end

    local inventory = getTargetInventory(hitObject)
    if not inventory then
        return
    end

    local ammoType = weapon:getAmmoType()
    local isStoneBolt = ammoType and ammoType:toString() == STONE_AMMO_TYPE
    local intactChance = isStoneBolt and 45 or 70

    if ZombRand(100) < intactChance then
        inventory:AddItem(isStoneBolt and "Base.AuxiliasStoneCrossbowBolt" or "Base.AuxiliasCrossbowBolt")
    else
        inventory:AddItem(isStoneBolt and "AuxiliasCrossbow.BrokenStoneBolt" or "AuxiliasCrossbow.BrokenBolt")
    end
end

Events.OnWeaponHitXp.Add(onWeaponHit)

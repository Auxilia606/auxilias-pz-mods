require "ISUI/ISContextMenu"

AuxiliaCrossbow = AuxiliaCrossbow or {}

local METAL_AMMO_TYPE = "auxiliascrossbow:bolt"
local STONE_AMMO_TYPE = "auxiliascrossbow:stonebolt"

local crossbows = {
    ["AuxiliasCrossbow.ImprovisedCrossbow"] = true,
    ["AuxiliasCrossbow.ReinforcedCrossbow"] = true,
    ["AuxiliasCrossbow.HeavyArbalest"] = true,
}

local function unwrapItem(entry)
    if instanceof(entry, "InventoryItem") then
        return entry
    end
    if type(entry) == "table" and entry.items and #entry.items > 0 then
        return entry.items[1]
    end
    return nil
end

local function selectAmmoType(weapon, ammoTypeName)
    if not weapon or weapon:getCurrentAmmoCount() > 0 then
        return
    end

    local ammoType = AmmoType.get(ResourceLocation.of(ammoTypeName))
    if not ammoType then
        return
    end

    weapon:setAmmoType(ammoType)
    weapon:syncItemFields()
end

local function addAmmoSelectionOption(playerIndex, context, items)
    for _, entry in ipairs(items) do
        local weapon = unwrapItem(entry)
        if weapon and crossbows[weapon:getFullType()] and weapon:getCurrentAmmoCount() <= 0 then
            local currentAmmoType = weapon:getAmmoType()
            local currentName = currentAmmoType and currentAmmoType:toString() or METAL_AMMO_TYPE

            if currentName == STONE_AMMO_TYPE then
                context:addOption(
                    getText("ContextMenu_AuxiliaCrossbow_SelectMetalBolts"),
                    weapon,
                    selectAmmoType,
                    METAL_AMMO_TYPE
                )
            else
                context:addOption(
                    getText("ContextMenu_AuxiliaCrossbow_SelectStoneBolts"),
                    weapon,
                    selectAmmoType,
                    STONE_AMMO_TYPE
                )
            end
            return
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(addAmmoSelectionOption)

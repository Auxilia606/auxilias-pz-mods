require "ISUI/ISContextMenu"

local function spawnTestKit(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if not player then
        return
    end

    local inventory = player:getInventory()
    inventory:AddItem("AuxiliasCrossbow.ImprovisedCrossbow")
    inventory:AddItem("AuxiliasCrossbow.ReinforcedCrossbow")
    inventory:AddItem("AuxiliasCrossbow.HeavyArbalest")
    for _ = 1, 30 do
        inventory:AddItem("Base.AuxiliasCrossbowBolt")
        inventory:AddItem("Base.AuxiliasStoneCrossbowBolt")
    end
end

local function addTestKitOption(playerIndex, context, items)
    if not isDebugEnabled() then
        return
    end
    context:addOption(getText("ContextMenu_AuxiliaCrossbow_TestKit"), playerIndex, spawnTestKit)
end

Events.OnFillInventoryObjectContextMenu.Add(addTestKitOption)

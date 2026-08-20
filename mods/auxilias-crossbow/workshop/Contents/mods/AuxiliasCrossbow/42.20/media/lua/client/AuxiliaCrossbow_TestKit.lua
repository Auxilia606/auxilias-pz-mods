require "ISUI/ISContextMenu"

local pendingDropComparison = nil

local function spawnTestKit(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if not player then
        return
    end

    local inventory = player:getInventory()
    inventory:AddItem("AuxiliasCrossbow.ImprovisedCrossbow")
    inventory:AddItem("AuxiliasCrossbow.ReinforcedCrossbow")
    inventory:AddItem("AuxiliasCrossbow.HeavyArbalest")
    inventory:AddItem("Base.Twigs")
    inventory:AddItem("Base.Sapling")
    for _ = 1, 30 do
        inventory:AddItem("Base.AuxiliasCrossbowBolt")
        inventory:AddItem("Base.AuxiliasStoneCrossbowBolt")
    end
end

local function dropWorldModelComparison(playerIndex)
    local player = getSpecificPlayer(playerIndex)
    if not player or not ISInventoryPaneContextMenu then
        return
    end

    local inventory = player:getInventory()
    pendingDropComparison = {
        startedAt = getTimestampMs(),
        samples = {
            { label = "Bolt", item = inventory:AddItem("Base.AuxiliasCrossbowBolt") },
            { label = "Twigs", item = inventory:AddItem("Base.Twigs") },
            { label = "Sapling", item = inventory:AddItem("Base.Sapling") },
        },
    }

    for _, sample in ipairs(pendingDropComparison.samples) do
        ISInventoryPaneContextMenu.dropItem(sample.item, playerIndex)
    end
end

local function reportDropWorldModelComparison()
    if not pendingDropComparison then
        return
    end

    local allDropped = true
    for _, sample in ipairs(pendingDropComparison.samples) do
        local worldItem = sample.item:getWorldItem()
        if not worldItem then
            allDropped = false
        elseif not sample.reported then
            local square = worldItem:getSquare()
            print(string.format(
                "[Auxilia Drop Comparison] item=%s square=%d,%d,%d offset=%.3f,%.3f,%.3f rotation=%.1f",
                sample.label,
                square:getX(), square:getY(), square:getZ(),
                worldItem:getOffX(), worldItem:getOffY(), worldItem:getOffZ(),
                sample.item:getWorldZRotation()
            ))
            sample.reported = true
        end
    end

    if allDropped or getTimestampMs() - pendingDropComparison.startedAt > 10000 then
        pendingDropComparison = nil
    end
end

local function addTestKitOption(playerIndex, context, items)
    if not isDebugEnabled() then
        return
    end
    context:addOption(getText("ContextMenu_AuxiliaCrossbow_TestKit"), playerIndex, spawnTestKit)
    context:addOption(getText("ContextMenu_AuxiliaCrossbow_DropComparison"), playerIndex, dropWorldModelComparison)
end

Events.OnFillInventoryObjectContextMenu.Add(addTestKitOption)
Events.OnTick.Add(reportDropWorldModelComparison)

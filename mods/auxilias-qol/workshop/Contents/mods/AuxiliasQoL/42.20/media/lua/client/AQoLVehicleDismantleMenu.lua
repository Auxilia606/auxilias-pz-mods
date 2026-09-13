require "AQoLVehicleDismantle"
require "Vehicles/TimedActions/ISAQoLDismantleVehicle"
require "Vehicles/ISUI/ISVehicleMenu"
require "ISUI/ISModalDialog"

local function hasWeldingMask(item)
    return item and (item:hasTag(ItemTag.WELDING_MASK) or item:getType() == "WeldingMask")
end

local function hasReadyTorch(item)
    return item and (item:hasTag(ItemTag.BLOW_TORCH) or item:getType() == "BlowTorch")
        and item:getCurrentUses() >= 10
end

local function getTorch(player)
    return player:getInventory():getBestTypeEvalRecurse("Base.BlowTorch", function(left, right)
        return left:getCurrentUses() - right:getCurrentUses()
    end)
end

local function startDismantling(player, vehicle)
    if AQoLVehicleDismantle.getBlockReason(vehicle) then return end
    local inventory = player:getInventory()
    local mask = inventory:getFirstEvalRecurse(hasWeldingMask)
    local torch = getTorch(player)
    if not mask or not hasReadyTorch(torch) then return end
    if not luautils.walkAdj(player, vehicle:getSquare()) then return end

    ISWorldObjectContextMenu.equip(player, player:getPrimaryHandItem(), hasReadyTorch, true)
    ISInventoryPaneContextMenu.wearItem(mask, player:getPlayerNum())
    ISTimedActionQueue.add(ISAQoLDismantleVehicle:new(player, vehicle))
end

local function onConfirm(_, button, player, vehicle)
    if button.internal == "YES" then
        startDismantling(player, vehicle)
    end
end

local function onSelect(player, vehicle)
    if AQoLVehicleDismantle.getBlockReason(vehicle) then return end
    local playerNum = player:getPlayerNum()
    local modal = ISModalDialog:new(0, 0, 440, 180,
        getText("IGUI_AQoL_ConfirmDismantleVehicle"), true, nil,
        onConfirm, playerNum, player, vehicle)
    modal:initialise()
    modal.moveWithMouse = true
    modal:addToUIManager()
    if JoypadState.players[playerNum + 1] then
        setJoypadFocus(playerNum, modal)
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, _, test)
    if test then return end
    local player = getSpecificPlayer(playerNum)
    if not player or player:getVehicle() then return end

    local vehicle
    if JoypadState.players[playerNum + 1] then
        vehicle = player:getUseableVehicle() or player:getNearVehicle()
    else
        vehicle = IsoObjectPicker.Instance:PickVehicle(getMouseXScaled(), getMouseYScaled())
    end
    if not vehicle then return end

    local reason = AQoLVehicleDismantle.getBlockReason(vehicle)
    if reason == "Tooltip_AQoL_VehicleUnavailable" then return end

    local option = context:addOption(getText("ContextMenu_AQoL_DismantleVehicle"), player, onSelect, vehicle)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    tooltip:setName(getText("ContextMenu_AQoL_DismantleVehicle"))
    tooltip.description = getText("Tooltip_AQoL_DismantleVehicle")
    option.toolTip = tooltip

    if reason then
        tooltip.description = tooltip.description .. " <LINE> <RGB:1,0,0> " .. getText(reason)
        option.notAvailable = true
    end
    if not player:getInventory():containsEvalRecurse(hasWeldingMask) then
        tooltip.description = tooltip.description .. " <LINE> <RGB:1,0,0> " .. getText("Tooltip_AQoL_NeedMask")
        option.notAvailable = true
    end
    if not hasReadyTorch(getTorch(player)) then
        tooltip.description = tooltip.description .. " <LINE> <RGB:1,0,0> " .. getText("Tooltip_AQoL_NeedTorch")
        option.notAvailable = true
    end
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)

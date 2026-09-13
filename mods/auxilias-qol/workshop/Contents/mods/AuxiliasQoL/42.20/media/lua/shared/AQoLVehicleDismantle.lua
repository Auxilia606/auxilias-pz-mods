AQoLVehicleDismantle = AQoLVehicleDismantle or {}

-- The vanilla wreck action is reserved for scripts named Burnt or Smashed.
function AQoLVehicleDismantle.getBlockReason(vehicle)
    if not vehicle or vehicle:isRemovedFromWorld() then
        return "Tooltip_AQoL_VehicleUnavailable"
    end

    local script = vehicle:getScript()
    if not script or script:getPassengerCount() < 1 then
        return "Tooltip_AQoL_VehicleUnavailable"
    end
    if vehicle:isBurntOrSmashed() then
        return "Tooltip_AQoL_VehicleUnavailable"
    end

    if not vehicle:getSquare() or not vehicle:isStopped() or vehicle:isEngineRunning() then
        return "Tooltip_AQoL_StopVehicle"
    end
    if vehicle:getVehicleTowing() or vehicle:getVehicleTowedBy() then
        return "Tooltip_AQoL_DetachVehicle"
    end
    for seat = 0, script:getPassengerCount() - 1 do
        if vehicle:getCharacter(seat) then
            return "Tooltip_AQoL_EmptySeats"
        end
    end
    local animals = vehicle:getAnimals()
    if animals and animals:size() > 0 then
        return "Tooltip_AQoL_RemoveAnimals"
    end
    return nil
end

-- This runs from the authoritative timed-action completion, before the
-- vehicle and its part containers are permanently removed.
function AQoLVehicleDismantle.dropStoredItems(vehicle)
    local square = vehicle:getSquare()
    if not square then return false end

    for partIndex = 0, vehicle:getPartCount() - 1 do
        local part = vehicle:getPartByIndex(partIndex)
        local container = part and part:getItemContainer()
        if container then
            local items = container:getItems()
            for itemIndex = items:size() - 1, 0, -1 do
                local item = items:get(itemIndex)
                local dropped = square:AddWorldInventoryItem(item,
                    ZombRandFloat(0.1, 0.9), ZombRandFloat(0.1, 0.9), 0)
                if not dropped then return false end
                container:Remove(item)
                if isServer() then
                    sendRemoveItemFromContainer(container, item)
                end
            end
        end
    end
    return true
end

require "Vehicles/TimedActions/ISRemoveBurntVehicle"
require "AQoLVehicleDismantle"

ISAQoLDismantleVehicle = ISRemoveBurntVehicle:derive("ISAQoLDismantleVehicle")

local function hasWeldingMask(item)
    return item and (item:hasTag(ItemTag.WELDING_MASK) or item:getType() == "WeldingMask")
end

function ISAQoLDismantleVehicle:isValid()
    if AQoLVehicleDismantle.getBlockReason(self.vehicle) then
        return false
    end
    if self.character:getVehicle() then
        return false
    end
    if not self.vehicle:isCharacterAdjacentTo(self.character) then
        return false
    end
    if not self.character:getInventory():containsEvalRecurse(hasWeldingMask) then
        return false
    end
    if self.item and self.item ~= self.character:getPrimaryHandItem() then
        return false
    end
    return ISRemoveBurntVehicle.isValid(self)
end

function ISAQoLDismantleVehicle:update()
    ISRemoveBurntVehicle.update(self)
    self.item:setJobType(getText("ContextMenu_AQoL_DismantleVehicle"))
end

function ISAQoLDismantleVehicle:complete()
    -- Recheck on the authoritative side before the vanilla action pays out
    -- salvage, consumes torch fuel, and permanently removes the vehicle.
    if not self.item or not self:isValid() then
        return false
    end
    if not AQoLVehicleDismantle.dropStoredItems(self.vehicle) then
        return false
    end
    return ISRemoveBurntVehicle.complete(self)
end

function ISAQoLDismantleVehicle:new(character, vehicle)
    local action = ISRemoveBurntVehicle.new(self, character, vehicle)
    action.stopOnWalk = true
    action.stopOnRun = true
    return action
end

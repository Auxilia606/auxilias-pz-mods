require "TimedActions/ISReloadWeaponAction"

AuxiliaCrossbow = AuxiliaCrossbow or {}

local reloadSpeeds = {
    ["AuxiliasCrossbow.ImprovisedCrossbow"] = { base = 0.24, perLevel = 0.015 },
    ["AuxiliasCrossbow.ReinforcedCrossbow"] = { base = 0.27, perLevel = 0.018 },
    ["AuxiliasCrossbow.HeavyArbalest"] = { base = 0.18, perLevel = 0.012 },
}

if not AuxiliaCrossbow.reloadSpeedPatched then
    AuxiliaCrossbow.reloadSpeedPatched = true
    local vanillaSetReloadSpeed = ISReloadWeaponAction.setReloadSpeed

    ISReloadWeaponAction.setReloadSpeed = function(character, rack)
        vanillaSetReloadSpeed(character, rack)

        if rack then
            return
        end

        local weapon = character:getPrimaryHandItem()
        if not weapon then
            return
        end

        local profile = reloadSpeeds[weapon:getFullType()]
        if not profile then
            return
        end

        local skill = character:getPerkLevel(Perks.Reloading)
        character:setVariable("ReloadSpeed", profile.base + (skill * profile.perLevel))
    end
end


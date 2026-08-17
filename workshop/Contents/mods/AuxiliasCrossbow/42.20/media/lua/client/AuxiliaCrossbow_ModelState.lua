AuxiliaCrossbow = AuxiliaCrossbow or {}

local modelProfiles = {
    ["AuxiliasCrossbow.ImprovisedCrossbow"] = {
        relaxed = "AuxiliaImprovisedCrossbow",
        cocked = "AuxiliaImprovisedCrossbowCocked",
    },
    ["AuxiliasCrossbow.ReinforcedCrossbow"] = {
        relaxed = "AuxiliaReinforcedCrossbow",
        cocked = "AuxiliaReinforcedCrossbowCocked",
    },
    ["AuxiliasCrossbow.HeavyArbalest"] = {
        relaxed = "AuxiliaHeavyArbalest",
        cocked = "AuxiliaHeavyArbalestCocked",
    },
}

-- A remote/client ammo update can arrive after the visual shot event. Keep the
-- released model authoritative until this player observes the empty weapon;
-- otherwise the per-frame synchronizer could briefly draw the string again.
local releasedWeapons = {}

local function setModelState(player, weapon, modelName)
    if not weapon or weapon:getWeaponSprite() == modelName then
        return
    end
    weapon:setWeaponSprite(modelName)
    if player then
        player:resetEquippedHandsModels()
    end
end

local function synchronizeEquippedCrossbow(player)
    if not player or player:isDead() then
        if player then
            releasedWeapons[player] = nil
        end
        return
    end
    local weapon = player:getPrimaryHandItem()
    if not weapon then
        return
    end
    local profile = modelProfiles[weapon:getFullType()]
    if not profile then
        return
    end
    local ammoCount = weapon:getCurrentAmmoCount()
    if releasedWeapons[player] == weapon then
        setModelState(player, weapon, profile.relaxed)
        if ammoCount <= 0 then
            releasedWeapons[player] = nil
        end
        return
    end
    local desiredModel = ammoCount > 0 and profile.cocked or profile.relaxed
    setModelState(player, weapon, desiredModel)
end

local function releaseStringAfterShot(player, weapon)
    if not player or not weapon then
        return
    end
    local profile = modelProfiles[weapon:getFullType()]
    if not profile then
        return
    end
    -- MaxAmmo is one for every Auxilia crossbow. The shot event is the exact
    -- visual release point, so do not wait for a later inventory refresh.
    releasedWeapons[player] = weapon
    setModelState(player, weapon, profile.relaxed)
end

AuxiliaCrossbow.synchronizeModelState = synchronizeEquippedCrossbow

Events.OnPlayerUpdate.Add(synchronizeEquippedCrossbow)
Events.OnWeaponSwingHitPoint.Add(releaseStringAfterShot)
Events.OnPlayerAttackFinished.Add(releaseStringAfterShot)

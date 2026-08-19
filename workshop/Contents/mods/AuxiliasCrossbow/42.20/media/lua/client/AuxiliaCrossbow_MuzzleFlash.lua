local crossbows = {
    ["AuxiliasCrossbow.ImprovisedCrossbow"] = true,
    ["AuxiliasCrossbow.ReinforcedCrossbow"] = true,
    ["AuxiliasCrossbow.HeavyArbalest"] = true,
}

local function updateCrossbowBallistics(player)
    if not player or player:isDead() then
        return
    end

    local weapon = player:getPrimaryHandItem()
    if not weapon or not crossbows[weapon:getFullType()] then
        return
    end

    -- The item remains a ranged aimed-hand weapon, but not an aimed firearm.
    -- That prevents Build 42 from entering the hard-coded muzzle-light and
    -- bright bullet-tracer branch. Reproduce only the ballistics update which
    -- the engine otherwise gates behind the aimed-firearm flag.
    if player:isAiming() then
        player:setAngleFromAim()
    end
    player:updateBallistics()
end

local function prepareEquippedCrossbow(player, weapon)
    if not player or not weapon or not crossbows[weapon:getFullType()] then
        return
    end

    -- Allocate the controller as soon as the crossbow is equipped. Waiting for
    -- OnPlayerUpdate is one frame too late when the player fires immediately.
    player:updateBallistics()
end

local function prepareLoadedPlayers()
    for playerIndex = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(playerIndex)
        if player then
            prepareEquippedCrossbow(player, player:getPrimaryHandItem())
        end
    end
end

Events.OnEquipPrimary.Add(prepareEquippedCrossbow)
Events.OnGameStart.Add(prepareLoadedPlayers)
Events.OnPlayerUpdate.Add(updateCrossbowBallistics)

local crossbows = {
    ["AuxiliasCrossbow.ImprovisedCrossbow"] = true,
    ["AuxiliasCrossbow.ReinforcedCrossbow"] = true,
    ["AuxiliasCrossbow.HeavyArbalest"] = true,
}

local pendingMuzzleLights = {}

local function isCrossbow(weapon)
    return weapon and crossbows[weapon:getFullType()] == true
end

local function rememberLightsBeforeShot(player, weapon)
    if not player or not isCrossbow(weapon) then
        return
    end

    local cell = getCell()
    if not cell then
        return
    end

    local lights = cell:getLamppostPositions()
    local existingLights = {}
    for index = 0, lights:size() - 1 do
        existingLights[lights:get(index)] = true
    end

    pendingMuzzleLights[#pendingMuzzleLights + 1] = {
        cell = cell,
        existingLights = existingLights,
        x = math.floor(player:getX()),
        y = math.floor(player:getY()),
        z = math.floor(player:getZ()),
    }
end

local function removePendingMuzzleLights()
    if #pendingMuzzleLights == 0 then
        return
    end

    for _, pending in ipairs(pendingMuzzleLights) do
        local lights = pending.cell:getLamppostPositions()
        for index = lights:size() - 1, 0, -1 do
            local light = lights:get(index)
            if not pending.existingLights[light]
                and light:getX() == pending.x
                and light:getY() == pending.y
                and light:getZ() == pending.z
                and light:getRadius() == 18 then
                -- Build 42 creates this six-tick firearm light after
                -- OnWeaponSwingHitPoint. OnTick runs after combat update but
                -- before rendering, so setting its life to zero here prevents
                -- even a one-frame flash without changing firearm ballistics.
                pending.cell:removeLamppost(light)
            end
        end
    end

    pendingMuzzleLights = {}
end

Events.OnWeaponSwingHitPoint.Add(rememberLightsBeforeShot)
Events.OnTick.Add(removePendingMuzzleLights)

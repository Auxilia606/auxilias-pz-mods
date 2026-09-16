local PRESS_ITEM = "AuxiliasAmmunition.Mov_AmmoPress"
local PRESS_SPRITES = {
    auxammo_press_01_0 = true,
    auxammo_press_01_1 = true,
    auxammo_press_01_2 = true,
    auxammo_press_01_3 = true,
}

local function restorePressComponents(object)
    local sprite = object and object:getSprite()
    if not sprite or not PRESS_SPRITES[sprite:getName()] then
        return
    end

    local properties = object:getProperties()
    if not properties or properties:get("CustomItem") ~= PRESS_ITEM then
        return
    end

    local needsUi = not object:hasComponent(ComponentType.UiConfig)
    local needsBench = not object:hasComponent(ComponentType.CraftBench)
    if not needsUi and not needsBench then
        return
    end

    local itemScript = ScriptManager.instance:FindItem(PRESS_ITEM)
    if not itemScript then
        return
    end

    local uiScript = needsUi and itemScript:getComponentScriptFor(ComponentType.UiConfig)
    local benchScript = needsBench and itemScript:getComponentScriptFor(ComponentType.CraftBench)
    if (needsUi and not uiScript) or (needsBench and not benchScript) then
        return
    end

    -- Saved moveables retain their old component set after the item script changes.
    if needsUi then
        GameEntityFactory.AddComponent(object, ComponentType.UiConfig:CreateComponentFromScript(uiScript))
    end
    if needsBench then
        GameEntityFactory.AddComponent(object, ComponentType.CraftBench:CreateComponentFromScript(benchScript))
    end

    if not isClient() then
        object:flagForHotSave()
    end
end

local function restoreSquare(square)
    if not square then
        return
    end

    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        restorePressComponents(objects:get(index))
    end
end

local function onLoadChunk(chunk)
    if not chunk then
        return
    end

    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for x = 0, 7 do
            for y = 0, 7 do
                restoreSquare(chunk:getGridSquare(x, y, z))
            end
        end
    end
end

local function onGameStart()
    if isServer() then
        return
    end

    local player = getPlayer()
    if not player then
        return
    end

    local cell = getCell()
    local centerX = math.floor(player:getX())
    local centerY = math.floor(player:getY())
    local z = math.floor(player:getZ())
    for x = centerX - 3, centerX + 3 do
        for y = centerY - 3, centerY + 3 do
            restoreSquare(cell:getGridSquare(x, y, z))
        end
    end
end

Events.LoadChunk.Add(onLoadChunk)
Events.OnGameStart.Add(onGameStart)

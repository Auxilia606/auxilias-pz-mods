require "Entity/ISEntityUI"

local PRESS_ITEM = "AuxiliasAmmunition.Mov_AmmoPress"
local PRESS_SPRITES = {
    auxammo_press_01_0 = true,
    auxammo_press_01_1 = true,
    auxammo_press_01_2 = true,
    auxammo_press_01_3 = true,
}

local downPress
local downX
local downY

local function isPress(object)
    local press = object and object:getMasterObject()
    local sprite = press and press:getSprite()
    local properties = press and press:getProperties()
    if sprite and PRESS_SPRITES[sprite:getName()]
        and properties and properties:get("CustomItem") == PRESS_ITEM then
        return press
    end
    return nil
end

local function getPress(object)
    local press = isPress(object)
    if press then
        return press
    end

    -- A tabletop press can share its square with furniture. The left-click
    -- picker may return that furniture even when the press is visible.
    local square = object and object:getSquare()
    local objects = square and square:getObjects()
    if objects then
        for i = 0, objects:size() - 1 do
            press = isPress(objects:get(i))
            if press then
                return press
            end
        end
    end
    return nil
end

local function onPressMouseDown(object, x, y)
    downPress = getPress(object)
    downX = x
    downY = y
end

local function onPressMouseUp(object, x, y)
    local press = getPress(object)
    local sameClick = press and press == downPress
        and math.abs(x - downX) <= 4 and math.abs(y - downY) <= 4
    downPress = nil
    downX = nil
    downY = nil
    if not sameClick or (ISObjectClickHandler and ISObjectClickHandler.isDoubleClick) then
        return
    end

    local player = getSpecificPlayer(0)
    local square = press:getSquare()
    local playerSquare = player and player:getCurrentSquare()
    local speedControls = UIManager.getSpeedControls()
    if not player or not player:isAlive() or player:isAiming()
        or getCore():getGameMode() == "Tutorial"
        or (speedControls and speedControls:getCurrentGameSpeed() == 0)
        or (getCell():getDrag(0) and getCell():getDrag(0).Type == "ISDestroyCursor")
        or not square or not square:isSeen(0)
        or not playerSquare or player:DistToSquared(press:getX() + 0.5, press:getY() + 0.5) >= 6
        or playerSquare:isSomethingTo(square) then
        return
    end

    -- Vanilla's left-click path only opens entities with a multi-square master.
    -- This single-tile moveable uses the same native window after the same checks.
    if ISEntityUI.CanOpenWindowFor(player, press) then
        ISEntityUI.OpenWindow(player, press)
    end
end

Events.OnObjectLeftMouseButtonDown.Add(onPressMouseDown)
Events.OnObjectLeftMouseButtonUp.Add(onPressMouseUp)

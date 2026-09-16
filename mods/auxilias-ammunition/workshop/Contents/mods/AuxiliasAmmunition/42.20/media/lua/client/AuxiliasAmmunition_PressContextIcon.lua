local PRESS_ITEM = "AuxiliasAmmunition.Mov_AmmoPress"
local PRESS_SPRITES = {
    auxammo_press_01_0 = true,
    auxammo_press_01_1 = true,
    auxammo_press_01_2 = true,
    auxammo_press_01_3 = true,
}

ISWorldMenuElements = ISWorldMenuElements or {}

function ISWorldMenuElements.AuxAmmoPressContextIcon()
    local self = ISMenuElement.new()
    -- The vanilla ContextEntity element creates the option at priority 1000.
    self.zIndex = 1001

    function self.createMenu(data)
        if not data.context or data.test then
            return
        end

        for _, object in ipairs(data.objects) do
            local press = object:getMasterObject()
            local sprite = press and press:getSprite()
            local properties = press and press:getProperties()
            if sprite and PRESS_SPRITES[sprite:getName()]
                and properties and properties:get("CustomItem") == PRESS_ITEM then
                local option = data.context:getOptionFromName(press:getEntityDisplayName())
                if option and option.param1 == press then
                    option.iconTexture = getTexture("media/textures/Item_AuxAmmoPress.png")
                    return
                end
            end
        end
    end

    return self
end

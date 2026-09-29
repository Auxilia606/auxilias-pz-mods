require "Foraging/Categories/Junk"
require "AQoLSkillBooks"

-- Register before forageSystem.init builds its loot tables. Clone the matching
-- vanilla book's definition so biome chances and rarity remain unchanged.
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

for _, series in ipairs(AQoLSkillBooks) do
    for tier = 1, 5 do
        -- No LongBlade forage definition means no melee books in foraging.
        local template = forageSystem.forageDefinitions["Book" .. (series.lootTemplate or "Carpentry") .. tier]
        if template then
            local skill = series.skill
            local key = "AQoLBook" .. skill .. tier
            if not forageSystem.forageDefinitions[key] then
                local definition = copy(template)
                definition.type = "AuxiliasQoL.Book" .. skill .. tier
                forageSystem.addForageDef(key, definition)
            end
        end
    end
end

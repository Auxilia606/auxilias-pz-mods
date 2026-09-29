require "XpSystem/XPSystem_SkillBook"
require "AQoLSkillBooks"

-- Vanilla also loads server Lua in the client. Load its table first so its
-- initial "SkillBook = {}" cannot erase these entries later in the load order.
-- Reuse ISReadABook for progress, level limits, persistence and network sync.
for _, series in ipairs(AQoLSkillBooks) do
    local skill = series.skill
    local book = SkillBook[skill] or {}
    book.perk = Perks[skill]
    for tier = 1, 5 do
        book["maxMultiplier" .. tier] = SkillBook[series.template]["maxMultiplier" .. tier]
    end
    SkillBook[skill] = book
end

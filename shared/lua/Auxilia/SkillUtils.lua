-- Shared skill lookup; no events or hard dependency on a skill-extension mod.
-- Edit this source, then run tools/sync-shared.ps1 for registered consumers.
AuxiliaSkillUtils = AuxiliaSkillUtils or {}

local function validLevel(level)
    return type(level) == "number" and level == level
        and level >= 0 and level < math.huge
end

function AuxiliaSkillUtils.GetSkillLevel(character, perk)
    if not character or not perk then return 0 end

    -- Resolve at call time so optional-mod loading order does not matter.
    if type(BeyondTen) == "table" and type(BeyondTen.GetEffectiveLevel) == "function" then
        local ok, level = pcall(BeyondTen.GetEffectiveLevel, character, perk)
        if ok and validLevel(level) then return level end
    end

    local level = character:getPerkLevel(perk)
    return validLevel(level) and level or 0
end

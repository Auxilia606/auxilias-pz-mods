local skills = {"Fitness", "Strength", "Sprinting", "Lightfoot", "Nimble", "Sneak",
    "Axe", "Blunt", "SmallBlunt", "SmallBlade", "Spear"}
local combat = {Axe=true, Blunt=true, SmallBlunt=true, SmallBlade=true, Spear=true}
local function multipliers(skill)
    if combat[skill] then return {1.5, 2.5, 4, 6, 8} end
    return {3, 5, 8, 12, 16}
end
for _, skill in ipairs(skills) do
    assert(SkillBook[skill].perk == Perks[skill], "Wrong perk mapping")
    for tier, multiplier in ipairs(multipliers(skill)) do
        assert(SkillBook[skill]["maxMultiplier" .. tier] == multiplier)
    end
end
assert(SkillBook.Aiming.maxMultiplier5 == 8, "Vanilla aiming was changed")
assert(SkillBook.Carpentry.maxMultiplier5 == 16, "Vanilla carpentry was changed")
for _, skill in ipairs({"Aiming", "Reloading", "LongBlade"}) do
    for tier, value in ipairs({1.5, 2.5, 4, 6, 8}) do
        assert(SkillBook[skill]["maxMultiplier" .. tier] == value, "Vanilla combat book changed")
    end
end

local function character(level)
    local c = { level=level, pages={}, multiplier={}, range={}, illiterate=false }
    function c:getPlayerNum() return 0 end
    function c:isTimedActionInstant() return false end
    function c:getPerkLevel() return self.level end
    function c:hasTrait(trait) return trait == "Illiterate" and self.illiterate end
    function c:getAlreadyReadPages(id) return self.pages[id] or 0 end
    function c:setAlreadyReadPages(id, pages) self.pages[id] = pages end
    function c:getWornItems() return { getItem = function() end } end
    function c:isSitOnGround() return false end
    function c:isSittingOnFurniture() return false end
    function c:isSitting() return false end
    function c:getBodyDamage() return {} end
    function c:getStats() return {} end
    function c:getXp()
        return { getMultiplier = function(_, perk) return c.multiplier[perk] or 0 end }
    end
    return c
end
local function book(skill, tier)
    local b = { pages = 0 }
    function b:getSkillTrained() return skill end
    function b:getLvlSkillTrained() return tier * 2 - 1 end
    function b:getMaxLevelTrained() return tier * 2 end
    function b:getNumberOfPages() return 180 + tier * 40 end
    function b:getAlreadyReadPages() return self.pages end
    function b:setAlreadyReadPages(pages) self.pages = pages end
    function b:getFullType() return "AuxiliasQoL.Book" .. skill .. tier end
    function b:hasTag() return false end
    function b:setJobDelta() end
    function b:getLearnedRecipes() return nil end
    function b:hasModData() return false end
    return b
end

for _, skill in ipairs(skills) do
    for tier, max in ipairs(multipliers(skill)) do
        local c, b = character(tier * 2 - 2), book(skill, tier)
        local action = ISReadABook:new(c, b)
        assert(action.maxMultiplier == max)
        for _, percent in ipairs({0, 0.09, 0.1, 0.5, 0.6, 0.7, 0.99, 1}) do
            b.pages = math.floor(b:getNumberOfPages() * percent)
            ISReadABook.checkMultiplier(action)
            local wanted = math.floor(b.pages / b:getNumberOfPages() * 10) * max / 10
            assert(math.abs((c.multiplier[skill] or 0) - wanted) < 0.000001)
        end
        local range = c.range[skill]
        assert(range[1] == tier*2-1 and range[2] == tier*2)
        -- Completing again must not multiply the previous bonus.
        action:complete()
        action:complete()
        assert(c.multiplier[skill] == max)
        assert(b.pages == b:getNumberOfPages())

        -- Resume uses character progress, not the physical copy's previous reader.
        local saved = math.floor(b:getNumberOfPages() / 2)
        c.pages[b:getFullType()] = saved
        local resume = ISReadABook:new(c, b)
        assert(resume.startPage == saved and b.pages == saved)
        local newReader = character(c.level)
        ISReadABook:new(newReader, b)
        assert(b.pages == 0 and newReader.multiplier[skill] == nil)

        c.illiterate = true
        ISReadABook.checkLevel(c, b)
        assert(c.pages[b:getFullType()] == 0)
        c.illiterate = false
        c.level = tier*2-3
        c.pages[b:getFullType()] = saved
        b.pages = saved
        ISReadABook.checkLevel(c, b)
        assert(b.pages == 0 and c.pages[b:getFullType()] == 0)

        -- Use vanilla update to reject obsolete/advanced books and illiteracy.
        for _, mode in ipairs({"tooLow", "tooHigh", "illiterate"}) do
            local level = tier*2-2
            if mode == "tooLow" then level = level-1 end
            if mode == "tooHigh" then level = tier*2 end
            local blocked = character(level)
            blocked.illiterate = mode == "illiterate"
            local reading = ISReadABook:new(blocked, book(skill, tier))
            reading.pageTimer = 200
            function reading:getJobDelta() return 0.5 end
            function reading:forceStop() self.stopped = true end
            reading:update()
            assert(reading.stopped and blocked.multiplier[skill] == nil, "Invalid book granted bonus")
        end
    end
end

-- A level-5 reader uses volume 3, then volume 4 at level 6.
local c = character(5)
assert(ISReadABook:new(c, book("Fitness", 3)).maxMultiplier == 8)
c.level = 6
assert(ISReadABook:new(c, book("Fitness", 4)).maxMultiplier == 12)
-- Server completion registers the same range; no custom client XP hook exists.
testServer = true
for _, skill in ipairs(skills) do
    for tier, max in ipairs(multipliers(skill)) do
        local reader = character(tier * 2 - 2)
        ISReadABook:new(reader, book(skill, tier)):complete()
        assert(reader.multiplier[skill] == max)
        assert(reader.range[skill][1] == tier * 2 - 1 and reader.range[skill][2] == tier * 2)
    end
end
return "All 55 books passed reading and server-completion checks with their expected multiplier groups."

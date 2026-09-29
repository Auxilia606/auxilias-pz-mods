function require() end
Perks = { Mechanics = "Mechanics" }
testClient, testServer, testRoll, rollCount = false, false, 0.99, 0
function isClient() return testClient end
function isServer() return testServer end
function ZombRandFloat()
    rollCount = rollCount + 1
    return testRoll
end
function list(values)
    return { size = function() return #values end,
        get = function(_, index) return values[index + 1] end }
end
FixingManager = { getFixes = function(item) return list(item.fixes or {}) end }
ArrayList = { new = function() return list({}) end }
ISBaseTimedAction = {}
function ISBaseTimedAction:derive()
    local child = {}
    child.__index = child
    return setmetatable(child, { __index = self })
end
function ISBaseTimedAction.perform() end
ISInventoryPage = { dirtyUI = function() end }
Actions = { addOrDropItem = function() error("Repair must not create an output item") end }

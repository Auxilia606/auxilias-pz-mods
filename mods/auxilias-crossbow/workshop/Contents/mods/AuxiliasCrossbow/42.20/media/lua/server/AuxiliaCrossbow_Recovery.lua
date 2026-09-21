AuxiliaCrossbow = AuxiliaCrossbow or {}

local crossbows = {
    ["AuxiliasCrossbow.ImprovisedCrossbow"] = true,
    ["AuxiliasCrossbow.ReinforcedCrossbow"] = true,
    ["AuxiliasCrossbow.HeavyArbalest"] = true,
}

local recoveryByAmmoType = {
    ["auxiliascrossbow:bolt"] = {
        intactChance = 70,
        intactItem = "Base.AuxiliasCrossbowBolt",
        brokenItem = "AuxiliasCrossbow.BrokenBolt",
    },
    ["auxiliascrossbow:stonebolt"] = {
        intactChance = 45,
        intactItem = "Base.AuxiliasStoneCrossbowBolt",
        brokenItem = "AuxiliasCrossbow.BrokenStoneBolt",
    },
}

local PENDING_RECOVERY_KEY = "AuxiliaCrossbowPendingRecovery"

local function isAuthoritativeGame()
    return not isClient() or isServer()
end

local function getRecoveryProfile(weapon)
    if not weapon or not crossbows[weapon:getFullType()] then
        return nil
    end

    local ammoType = weapon:getAmmoType()
    if not ammoType then
        return nil
    end

    return recoveryByAmmoType[ammoType:toString()]
end

local function rollRecoveryItemType(profile)
    if ZombRand(100) < profile.intactChance then
        return profile.intactItem
    end
    return profile.brokenItem
end

local function queueZombieRecovery(zombie, bodyPart, itemType)
    local item = instanceItem(itemType)
    if not item then
        return
    end

    -- Build 42 transfers this list into the corpse inventory when the zombie
    -- dies. Keep recovery non-visual while the zombie is alive.
    zombie:addItemToSpawnAtDeath(item)
    if getDebug() then
        print(string.format(
            "[AuxiliaCrossbow] queued %s for zombie corpse after %s hit",
            itemType,
            bodyPart and tostring(bodyPart) or "Unknown"
        ))
    end
end

local function queueRecoveryForDeath(target, itemType)
    if not target or not target.getModData then
        return
    end

    local modData = target:getModData()
    local pending = modData[PENDING_RECOVERY_KEY]
    if type(pending) ~= "table" then
        pending = {}
        modData[PENDING_RECOVERY_KEY] = pending
    end
    table.insert(pending, itemType)
end

local function onHitZombie(zombie, owner, bodyPart, weapon)
    if not isAuthoritativeGame() then
        return
    end

    local profile = getRecoveryProfile(weapon)
    if not profile or not zombie then
        return
    end

    queueZombieRecovery(zombie, bodyPart, rollRecoveryItemType(profile))
end

local function onWeaponHitCharacter(owner, target, weapon, damage)
    if not isAuthoritativeGame() or not target or instanceof(target, "IsoZombie") then
        return
    end
    if not damage or damage <= 0 then
        return
    end

    local profile = getRecoveryProfile(weapon)
    if not profile then
        return
    end

    -- Animals and other non-zombie characters do not use the Human embedded-item
    -- slots reliably. Keep their recovery bound to that exact target until death.
    queueRecoveryForDeath(target, rollRecoveryItemType(profile))
end

local function onCharacterDeath(character)
    if not isAuthoritativeGame() or not character or instanceof(character, "IsoZombie") then
        return
    end
    if not character.getModData or not character.getSquare then
        return
    end

    local modData = character:getModData()
    local pending = modData[PENDING_RECOVERY_KEY]
    local square = character:getSquare()
    if type(pending) ~= "table" or not square then
        return
    end

    -- Animal corpses have no loot container in Build 42. Drop their target-bound
    -- recovery beside the body only when that character actually dies.
    for _, itemType in ipairs(pending) do
        square:AddWorldInventoryItem(itemType, ZombRand(100) / 100, ZombRand(100) / 100, 0.0)
    end
    modData[PENDING_RECOVERY_KEY] = nil
end

Events.OnHitZombie.Add(onHitZombie)
Events.OnWeaponHitCharacter.Add(onWeaponHitCharacter)
Events.OnCharacterDeath.Add(onCharacterDeath)

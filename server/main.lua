--[[
    Main Server Script for mack-gunforhire
    Handles cooldowns, payouts, item management, logging, and entity sync
]]

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Cooldown tracking (per player, per mission)
PlayerCooldowns = {}

-- Active missions tracking (for validation)
ActiveMissions = {}

-- Spawned entities tracking (for sync across players)
-- Key = missionId_playerId, Value = { entities = {netIds}, owner = playerId }
SpawnedMissionEntities = {}

-- Quest Giver NPC tracking (only one should spawn)
QuestGiverSpawned = false
QuestGiverNetId = nil

--[[
    DEBUG PRINT (Server)
]]
function DebugPrint(msg)
    if Config.Debug then
        print('^6[mack-gunforhire]^7 ' .. tostring(msg))
    end
end

--[[
    GET MISSION CONFIG
    Returns mission configuration by ID
]]
local function GetMissionConfig(missionId)
    for _, mission in ipairs(Config.Missions) do
        if mission.id == missionId then
            return mission
        end
    end
    return nil
end

--[[
    SET COOLDOWN
    Sets cooldown for a player's mission
]]
local function SetCooldown(identifier, missionId, duration)
    if not PlayerCooldowns[identifier] then
        PlayerCooldowns[identifier] = {}
    end
    PlayerCooldowns[identifier][missionId] = os.time() + duration
    DebugPrint('Cooldown set for ' .. identifier .. ' on mission ' .. missionId .. ' for ' .. duration .. 's')
end

--[[
    MISSION STARTED EVENT
    Tracks when a player starts a mission
]]
RegisterNetEvent('mack-gunforhire:server:missionStarted', function(missionId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local identifier = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    
    -- Track active mission
    ActiveMissions[src] = {
        missionId = missionId,
        startTime = os.time(),
        playerId = identifier
    }
    
    DebugPrint('Mission ' .. missionId .. ' started by ' .. firstname .. ' ' .. lastname)
    
    -- Log to rsg-log if available
    TriggerEvent('rsg-log:server:CreateLog', 'gunforhire', 'Mission Started', 'green', 
        firstname .. ' ' .. lastname .. ' started mission: ' .. missionId)
end)

--[[
    MISSION COMPLETE EVENT
    Handles rewards and cooldown setting
]]
RegisterNetEvent('mack-gunforhire:server:missionComplete', function(missionId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Validate mission was active
    if not ActiveMissions[src] or ActiveMissions[src].missionId ~= missionId then
        DebugPrint('^1Invalid mission completion attempt from ' .. src .. '^7')
        return
    end
    
    local identifier = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    
    -- Get mission config
    local missionConfig = GetMissionConfig(missionId)
    if not missionConfig then
        DebugPrint('^1Mission config not found: ' .. missionId .. '^7')
        return
    end
    
    local rewards = missionConfig.rewards
    
    -- Calculate cash reward (random between min and max)
    local cashReward = math.random(rewards.cash.min, rewards.cash.max)
    
    -- Give cash
    Player.Functions.AddMoney('cash', cashReward, 'gunforhire-mission-reward')
    
    -- Give XP
    if rewards.xp and rewards.xp > 0 then
        Player.Functions.AddXp('main', rewards.xp)
    end
    
    -- Process item rewards
    local itemsGiven = {}
    if rewards.items then
        for _, itemReward in ipairs(rewards.items) do
            if math.random() <= itemReward.chance then
                local success = Player.Functions.AddItem(itemReward.item, itemReward.amount)
                if success then
                    table.insert(itemsGiven, {
                        name = itemReward.item,
                        amount = itemReward.amount
                    })
                    DebugPrint('Item given: ' .. itemReward.amount .. 'x ' .. itemReward.item)
                end
            end
        end
    end
    
    -- Set cooldown
    local cooldown = missionConfig.cooldown or Config.DefaultCooldown
    SetCooldown(identifier, missionId, cooldown)
    
    -- Clear active mission
    ActiveMissions[src] = nil
    
    -- Notify client of rewards
    TriggerClientEvent('mack-gunforhire:client:rewardReceived', src, cashReward, rewards.xp, itemsGiven)
    
    -- Log completion
    local itemLog = ''
    for _, item in ipairs(itemsGiven) do
        itemLog = itemLog .. item.amount .. 'x ' .. item.name .. ', '
    end
    
    DebugPrint('Mission ' .. missionId .. ' completed by ' .. firstname .. ' ' .. lastname .. 
        ' | Cash: $' .. cashReward .. ' | XP: ' .. rewards.xp .. ' | Items: ' .. itemLog)
    
    TriggerEvent('rsg-log:server:CreateLog', 'gunforhire', 'Mission Completed', 'yellow',
        firstname .. ' ' .. lastname .. ' completed mission: ' .. missionId .. 
        ' | Reward: $' .. cashReward .. ', ' .. rewards.xp .. ' XP, ' .. itemLog)
end)

--[[
    MISSION FAILED EVENT
    Handles mission failure (no rewards, no cooldown)
]]
RegisterNetEvent('mack-gunforhire:server:missionFailed', function(missionId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    
    -- Clear active mission
    ActiveMissions[src] = nil
    
    DebugPrint('Mission ' .. missionId .. ' failed by ' .. firstname .. ' ' .. lastname)
    
    TriggerEvent('rsg-log:server:CreateLog', 'gunforhire', 'Mission Failed', 'red',
        firstname .. ' ' .. lastname .. ' failed mission: ' .. missionId)
end)

--[[
    REMOVE ITEM EVENT
    Removes items from player inventory (for bait, etc.)
]]
RegisterNetEvent('mack-gunforhire:server:removeItem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    amount = amount or 1
    
    local success = Player.Functions.RemoveItem(item, amount)
    
    if success then
        DebugPrint('Removed ' .. amount .. 'x ' .. item .. ' from player ' .. src)
    else
        DebugPrint('^1Failed to remove ' .. amount .. 'x ' .. item .. ' from player ' .. src .. '^7')
    end
end)

--[[
    PLAYER DISCONNECT CLEANUP
    Clears active mission when player disconnects
]]
AddEventHandler('playerDropped', function(reason)
    local src = source
    
    if ActiveMissions[src] then
        local missionKey = ActiveMissions[src].missionId .. '_' .. src
        DebugPrint('Player ' .. src .. ' disconnected during mission ' .. ActiveMissions[src].missionId)
        
        -- Cleanup spawned entities for this mission
        if SpawnedMissionEntities[missionKey] then
            TriggerClientEvent('mack-gunforhire:client:cleanupSyncedEntities', -1, missionKey)
            SpawnedMissionEntities[missionKey] = nil
        end
        
        ActiveMissions[src] = nil
    end
end)

--[[
    REGISTER SPAWNED ENTITY
    Tracks entities spawned by mission owner for sync
]]
RegisterNetEvent('mack-gunforhire:server:registerEntity', function(missionId, netId, entityType)
    local src = source
    local missionKey = missionId .. '_' .. src
    
    if not SpawnedMissionEntities[missionKey] then
        SpawnedMissionEntities[missionKey] = {
            entities = {},
            owner = src,
            missionId = missionId
        }
    end
    
    table.insert(SpawnedMissionEntities[missionKey].entities, {
        netId = netId,
        type = entityType
    })
    
    DebugPrint('Entity registered: ' .. netId .. ' for mission ' .. missionId .. ' by player ' .. src)
end)

--[[
    GET MISSION ENTITIES
    Returns all entity netIds for a mission (for other players to see)
]]
RSGCore.Functions.CreateCallback('mack-gunforhire:server:getMissionEntities', function(source, cb, missionId, ownerId)
    local missionKey = missionId .. '_' .. ownerId
    
    if SpawnedMissionEntities[missionKey] then
        cb(SpawnedMissionEntities[missionKey].entities)
    else
        cb({})
    end
end)

--[[
    CLEANUP MISSION ENTITIES
    Called when mission ends to clean up tracked entities
]]
RegisterNetEvent('mack-gunforhire:server:cleanupMissionEntities', function(missionId)
    local src = source
    local missionKey = missionId .. '_' .. src
    
    if SpawnedMissionEntities[missionKey] then
        -- Tell all clients to cleanup these entities
        TriggerClientEvent('mack-gunforhire:client:cleanupSyncedEntities', -1, missionKey)
        SpawnedMissionEntities[missionKey] = nil
        DebugPrint('Mission entities cleaned up for: ' .. missionKey)
    end
end)

--[[
    CHECK IF MISSION ACTIVE FOR PLAYER
    Other players can check if someone has an active mission
]]
RSGCore.Functions.CreateCallback('mack-gunforhire:server:isMissionActive', function(source, cb, targetPlayerId, missionId)
    if ActiveMissions[targetPlayerId] and ActiveMissions[targetPlayerId].missionId == missionId then
        cb(true)
    else
        cb(false)
    end
end)

--[[
    QUEST GIVER SPAWN CHECK
    Ensures only one client spawns the Quest Giver NPC
]]
RSGCore.Functions.CreateCallback('mack-gunforhire:server:canSpawnQuestGiver', function(source, cb)
    if QuestGiverSpawned then
        -- Already spawned by another client, return the netId
        cb(false, QuestGiverNetId)
    else
        -- First client to request, allow spawn
        QuestGiverSpawned = true
        cb(true, nil)
    end
end)

--[[
    REGISTER QUEST GIVER
    Stores the netId of the spawned Quest Giver for other clients
]]
RegisterNetEvent('mack-gunforhire:server:registerQuestGiver', function(netId)
    QuestGiverNetId = netId
    DebugPrint('Quest Giver registered with netId: ' .. tostring(netId))
end)

--[[
    RESET QUEST GIVER ON RESOURCE RESTART
]]
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        QuestGiverSpawned = false
        QuestGiverNetId = nil
    end
end)

--[[
    ADMIN COMMANDS (Debug)
]]
if Config.Debug then
    RegisterCommand('gfh_clearcooldown', function(source, args)
        local src = source
        
        -- Console only or admin check
        if src > 0 then
            local Player = RSGCore.Functions.GetPlayer(src)
            if not Player then return end
            -- Add admin check here if needed
        end
        
        local targetId = tonumber(args[1])
        if not targetId then
            print('Usage: gfh_clearcooldown [playerId]')
            return
        end
        
        local targetPlayer = RSGCore.Functions.GetPlayer(targetId)
        if not targetPlayer then
            print('Player not found')
            return
        end
        
        local identifier = targetPlayer.PlayerData.citizenid
        PlayerCooldowns[identifier] = nil
        
        print('Cleared all cooldowns for player ' .. targetId)
    end, true)
    
    RegisterCommand('gfh_testpayout', function(source, args)
        local src = source
        if src == 0 then
            print('This command must be run by a player')
            return
        end
        
        local Player = RSGCore.Functions.GetPlayer(src)
        if not Player then return end
        
        local testCash = 500
        local testXP = 100
        local testItems = {
            { name = 'raw_meat', amount = 2 }
        }
        
        Player.Functions.AddMoney('cash', testCash, 'gunforhire-test')
        Player.Functions.AddXp('main', testXP)
        Player.Functions.AddItem('raw_meat', 2)
        
        TriggerClientEvent('mack-gunforhire:client:rewardReceived', src, testCash, testXP, testItems)
        
        print('Test payout sent to player ' .. src)
    end, true)
end

--[[
    INITIALIZE
]]
DebugPrint('mack-gunforhire server initialized')

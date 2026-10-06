--[[
    Server Callbacks for mack-gunforhire
    Handles validation requests from client
]]

local RSGCore = exports['rsg-core']:GetCoreObject()

-- Server-side debug print
local function DebugPrint(msg)
    if Config.Debug then
        print('^6[mack-gunforhire]^7 ' .. tostring(msg))
    end
end

--[[
    CHECK COOLDOWN
    Verifies if player can start a specific mission
]]
RSGCore.Functions.CreateCallback('mack-gunforhire:server:checkCooldown', function(source, cb, missionId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(true, 0)
        return
    end
    
    local identifier = Player.PlayerData.citizenid
    
    -- Check cooldown
    if PlayerCooldowns[identifier] and PlayerCooldowns[identifier][missionId] then
        local cooldownEnd = PlayerCooldowns[identifier][missionId]
        local currentTime = os.time()
        
        if currentTime < cooldownEnd then
            local timeLeft = cooldownEnd - currentTime
            cb(true, timeLeft)
            return
        end
    end
    
    cb(false, 0)
end)

--[[
    CHECK ITEM
    Verifies if player has required item
]]
RSGCore.Functions.CreateCallback('mack-gunforhire:server:hasItem', function(source, cb, item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    amount = amount or 1
    
    local hasItem = Player.Functions.GetItemByName(item)
    
    if hasItem and hasItem.amount >= amount then
        cb(true)
    else
        cb(false)
    end
end)

--[[
    CHECK JOB
    Verifies if player has allowed job
]]
RSGCore.Functions.CreateCallback('mack-gunforhire:server:checkJob', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    if not Config.RequireJob then
        cb(true)
        return
    end
    
    local playerJob = Player.PlayerData.job.name
    
    for _, allowedJob in ipairs(Config.AllowedJobs) do
        if playerJob == allowedJob then
            cb(true)
            return
        end
    end
    
    cb(false)
end)

DebugPrint('Server callbacks registered')

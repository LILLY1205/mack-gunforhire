--[[
    Main Client Script for mack-gunforhire
    Handles NPC spawning, ox_target setup, and mission state management
]]

local RSGCore = exports['rsg-core']:GetCoreObject()

-- State Management
local QuestGiverNPC = nil
local QuestGiverBlip = nil
local ContactNPCs = {}
local ContactBlips = {}

-- Current Mission State
MissionState = {
    active = false,
    missionId = nil,
    missionData = nil,
    phase = 'INACTIVE', -- INACTIVE, ACCEPTED, TRAVELING, CONTACT, OBJECTIVE, COMBAT, RETURN, COMPLETE
    spawnedEntities = {},
    spawnedBlips = {},
    spawnedEnemies = {},
    targetAnimal = nil,
    targetBlip = nil,
    areaBlip = nil
}

--[[
    INITIALIZE QUEST GIVER NPC
    Spawns the main quest giver and sets up ox_target
    Each client spawns their own local NPC (standard for permanent NPCs)
]]
local function InitializeQuestGiver()
    local cfg = Config.QuestGiver
    local spawnCoords = vector3(cfg.Location.x, cfg.Location.y, cfg.Location.z)
    
    -- Load model first
    local modelHash = GetHashKey(cfg.Model)
    RequestModel(modelHash)
    
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if not HasModelLoaded(modelHash) then
        DebugPrint('^1Failed to load Quest Giver model: ' .. cfg.Model .. '^7')
        return
    end
    
    -- Spawn NPC locally (not networked - each client has their own)
    QuestGiverNPC = CreatePed(modelHash, cfg.Location.x, cfg.Location.y, cfg.Location.z, cfg.Location.w, false, false, false, false)
    
    if not QuestGiverNPC or not DoesEntityExist(QuestGiverNPC) then
        DebugPrint('^1Failed to spawn Quest Giver NPC^7')
        return
    end
    
    -- Configure NPC
    FreezeEntityPosition(QuestGiverNPC, cfg.Frozen)
    SetEntityInvincible(QuestGiverNPC, cfg.Invincible)
    SetBlockingOfNonTemporaryEvents(QuestGiverNPC, true)
    Citizen.InvokeNative(0x283978A15512B2FE, QuestGiverNPC, true) -- SetRandomOutfitVariation
    
    -- Play scenario
    if cfg.Scenario then
        TaskStartScenarioInPlace(QuestGiverNPC, GetHashKey(cfg.Scenario), -1, true, false, false, false)
    end
    
    SetModelAsNoLongerNeeded(modelHash)
    
    -- Create blip
    if cfg.Blip.Enabled then
        QuestGiverBlip = CreateBlipForCoords(
            spawnCoords,
            cfg.Blip.Sprite,
            cfg.Blip.Label,
            cfg.Blip.Color,
            cfg.Blip.Scale
        )
    end
    
    -- Setup ox_target on the NPC
    exports['ox_target']:addLocalEntity(QuestGiverNPC, {
        {
            name = 'gunforhire_talk',
            label = _L('target_talk_giver'),
            icon = 'fas fa-comments',
            distance = Config.TargetDistance,
            onSelect = function()
                OpenMissionMenu()
            end
        }
    })
    
    DebugPrint('Quest Giver initialized: ' .. QuestGiverNPC)
end

--[[
    OPEN MISSION MENU
    Shows available missions using ox_lib context menu
]]
function OpenMissionMenu()
    if MissionState.active then
        SendNotification('mission_in_progress', nil, 'ERROR')
        return
    end
    
    -- Check job requirement
    if Config.RequireJob then
        local PlayerData = RSGCore.Functions.GetPlayerData()
        local hasJob = false
        
        for _, job in ipairs(Config.AllowedJobs) do
            if PlayerData.job.name == job then
                hasJob = true
                break
            end
        end
        
        if not hasJob then
            SendNotification('notify_job_required', 'notify_job_not_allowed', 'ERROR')
            return
        end
    end
    
    -- Build menu options
    local menuOptions = {}
    
    for _, mission in ipairs(Config.Missions) do
        table.insert(menuOptions, {
            title = _L(mission.name),
            description = _L(mission.description),
            icon = GetMissionIcon(mission.type),
            onSelect = function()
                StartMission(mission.id)
            end
        })
    end
    
    -- Add coming soon entry
    table.insert(menuOptions, {
        title = _L('coming_soon'),
        icon = 'fas fa-clock',
        disabled = true
    })
    
    lib.registerContext({
        id = 'gunforhire_menu',
        title = _L('menu_title'),
        options = menuOptions
    })
    
    lib.showContext('gunforhire_menu')
end

--[[
    GET MISSION ICON
    Returns appropriate icon for mission type
]]
function GetMissionIcon(missionType)
    local icons = {
        hunt = 'fas fa-paw',
        combat = 'fas fa-crosshairs',
        escort = 'fas fa-horse',
        rescue = 'fas fa-user-shield',
        delivery = 'fas fa-box'
    }
    return icons[missionType] or 'fas fa-star'
end

--[[
    START MISSION
    Initiates a mission by ID
]]
function StartMission(missionId)
    -- Find mission data
    local missionData = nil
    for _, mission in ipairs(Config.Missions) do
        if mission.id == missionId then
            missionData = mission
            break
        end
    end
    
    if not missionData then
        DebugPrint('^1Mission not found: ' .. missionId .. '^7')
        return
    end
    
    -- Check cooldown via server
    RSGCore.Functions.TriggerCallback('mack-gunforhire:server:checkCooldown', function(onCooldown, timeLeft)
        if onCooldown then
            local minutes = math.ceil(timeLeft / 60)
            SendNotification('notify_cooldown_active', string.format(_L('notify_cooldown_wait'), minutes .. ' ' .. _L('minutes')), 'ERROR')
            return
        end
        
        -- Initialize mission state
        MissionState.active = true
        MissionState.missionId = missionId
        MissionState.missionData = missionData
        MissionState.phase = 'ACCEPTED'
        MissionState.spawnedEntities = {}
        MissionState.spawnedBlips = {}
        MissionState.spawnedEnemies = {}
        
        DebugPrint('Mission started: ' .. missionId)
        
        -- Play intro dialogue
        PlayDialogue(missionData.dialogue.intro, 5000, function()
            -- Transition to traveling phase
            MissionState.phase = 'TRAVELING'
            
            -- Spawn contact NPC
            SpawnContactNPC(missionData)
            
            -- Notify player
            SendNotification('notify_mission_accepted', 'notify_go_to_contact', 'SUCCESS')
            
            -- Set GPS to contact
            SetGPSRoute(vector3(missionData.contactNPC.location.x, missionData.contactNPC.location.y, missionData.contactNPC.location.z))
        end)
        
        -- Notify server of mission start
        TriggerServerEvent('mack-gunforhire:server:missionStarted', missionId)
        
    end, missionId)
end

--[[
    SPAWN CONTACT NPC
    Spawns the mission contact NPC with ox_target
]]
function SpawnContactNPC(missionData)
    local contact = missionData.contactNPC
    
    local npc = SpawnNPC(contact.model, contact.location, {
        frozen = true,
        invincible = true,
        scenario = contact.scenario,
        relationshipGroup = 'CIVILIAN'
    })
    
    if not npc then
        DebugPrint('^1Failed to spawn contact NPC^7')
        return
    end
    
    table.insert(MissionState.spawnedEntities, npc)
    
    -- Create blip for contact
    local blip = CreateBlipForCoords(
        vector3(contact.location.x, contact.location.y, contact.location.z),
        contact.blip.sprite,
        contact.blip.label,
        Config.Blips.Objective.Color,
        Config.Blips.Objective.Scale
    )
    table.insert(MissionState.spawnedBlips, blip)
    ContactBlips[missionData.id] = blip
    
    -- Setup ox_target for contact
    exports['ox_target']:addLocalEntity(npc, {
        {
            name = 'contact_talk_' .. missionData.id,
            label = _L('target_talk_contact'),
            icon = 'fas fa-comments',
            distance = Config.TargetDistance,
            onSelect = function()
                TalkToContact(missionData)
            end
        }
    })
    
    ContactNPCs[missionData.id] = npc
    DebugPrint('Contact NPC spawned for mission: ' .. missionData.id)
end

--[[
    TALK TO CONTACT
    Handles dialogue with contact NPC and advances mission
]]
function TalkToContact(missionData)
    if MissionState.phase ~= 'TRAVELING' then
        return
    end
    
    MissionState.phase = 'CONTACT'
    ClearGPSRoute()
    
    -- Play contact dialogue
    PlayDialogue(missionData.dialogue.contact, 5000, function()
        -- Advance to objective phase
        MissionState.phase = 'OBJECTIVE'
        
        -- Start mission-specific logic
        StartMissionObjective(missionData)
    end)
end

--[[
    START MISSION OBJECTIVE
    Routes to appropriate mission handler based on type
]]
function StartMissionObjective(missionData)
    local missionType = missionData.type
    
    if missionType == 'hunt' then
        StartHuntMission(missionData)
    elseif missionType == 'combat' then
        StartCombatMission(missionData)
    elseif missionType == 'escort' then
        StartEscortMission(missionData)
    elseif missionType == 'rescue' then
        StartRescueMission(missionData)
    else
        DebugPrint('^1Unknown mission type: ' .. missionType .. '^7')
    end
end

--[[
    COMPLETE MISSION
    Handles mission completion, rewards, and cleanup
]]
function CompleteMission()
    if not MissionState.active then
        return
    end
    
    local missionData = MissionState.missionData
    MissionState.phase = 'RETURN'
    
    -- Set GPS back to quest giver
    SetGPSRoute(vector3(Config.QuestGiver.Location.x, Config.QuestGiver.Location.y, Config.QuestGiver.Location.z))
    
    SendNotification('notify_mission_complete', 'notify_return_to_giver', 'SUCCESS')
    
    -- Add target for quest giver to complete mission
    exports['ox_target']:addLocalEntity(QuestGiverNPC, {
        {
            name = 'complete_mission',
            label = _L('menu_accept') .. ' - ' .. _L(missionData.name),
            icon = 'fas fa-check',
            distance = Config.TargetDistance,
            onSelect = function()
                FinalizeMission()
            end
        }
    })
end

--[[
    FINALIZE MISSION
    Pays rewards and resets state
]]
function FinalizeMission()
    if MissionState.phase ~= 'RETURN' then
        return
    end
    
    local missionData = MissionState.missionData
    
    -- Play completion dialogue
    PlayDialogue(missionData.dialogue.complete, 4000, function()
        -- Request payout from server
        TriggerServerEvent('mack-gunforhire:server:missionComplete', MissionState.missionId)
        
        -- Cleanup mission
        CleanupMission()
        
        -- Remove completion target option
        exports['ox_target']:removeLocalEntity(QuestGiverNPC, 'complete_mission')
        
        -- Re-add talk option
        exports['ox_target']:addLocalEntity(QuestGiverNPC, {
            {
                name = 'gunforhire_talk',
                label = _L('target_talk_giver'),
                icon = 'fas fa-comments',
                distance = Config.TargetDistance,
                onSelect = function()
                    OpenMissionMenu()
                end
            }
        })
    end)
end

--[[
    FAIL MISSION
    Handles mission failure
]]
function FailMission(reason)
    if not MissionState.active then
        return
    end
    
    SendNotification('notify_mission_failed', reason, 'ERROR')
    
    -- Cleanup
    CleanupMission()
    
    -- Notify server
    TriggerServerEvent('mack-gunforhire:server:missionFailed', MissionState.missionId)
end

--[[
    CLEANUP MISSION
    Removes all spawned entities and resets state
]]
function CleanupMission()
    local missionId = MissionState.missionId
    DebugPrint('Cleaning up mission: ' .. tostring(missionId))
    
    -- Notify server to cleanup tracked entities (for sync)
    if missionId then
        TriggerServerEvent('mack-gunforhire:server:cleanupMissionEntities', missionId)
    end
    
    -- Clear GPS
    ClearGPSRoute()
    
    -- Delete spawned entities
    for _, entity in ipairs(MissionState.spawnedEntities) do
        DeleteEntitySafe(entity)
    end
    
    -- Delete enemies
    for _, enemy in ipairs(MissionState.spawnedEnemies) do
        DeleteEntitySafe(enemy)
    end
    
    -- Remove blips (local only - other players don't see these)
    for _, blip in ipairs(MissionState.spawnedBlips) do
        RemoveBlipSafe(blip)
    end
    
    -- Remove target animal and blip
    if MissionState.targetAnimal then
        DeleteEntitySafe(MissionState.targetAnimal)
    end
    if MissionState.targetBlip then
        RemoveBlipSafe(MissionState.targetBlip)
    end
    if MissionState.areaBlip then
        RemoveBlipSafe(MissionState.areaBlip)
    end
    
    -- Remove contact NPC and targets
    if missionId and ContactNPCs[missionId] then
        exports['ox_target']:removeLocalEntity(ContactNPCs[missionId], 'contact_talk_' .. missionId)
        DeleteEntitySafe(ContactNPCs[missionId])
        ContactNPCs[missionId] = nil
    end
    
    -- Remove contact blip
    if missionId and ContactBlips[missionId] then
        RemoveBlipSafe(ContactBlips[missionId])
        ContactBlips[missionId] = nil
    end
    
    -- Remove any ox_target sphere zones for this mission
    pcall(function()
        exports['ox_target']:removeZone('place_bait_' .. tostring(missionId))
    end)
    
    -- Reset state
    MissionState = {
        active = false,
        missionId = nil,
        missionData = nil,
        phase = 'INACTIVE',
        spawnedEntities = {},
        spawnedBlips = {},
        spawnedEnemies = {},
        targetAnimal = nil,
        targetBlip = nil,
        areaBlip = nil
    }
    
    DebugPrint('Mission cleanup complete')
end

--[[
    PLAYER DEATH DETECTION
    Monitors for player death during missions
]]
CreateThread(function()
    while true do
        Wait(1000)
        
        if MissionState.active and IsPlayerDead() then
            FailMission('notify_player_died')
        end
    end
end)

--[[
    CLEANUP SYNCED ENTITIES
    Called by server when mission owner disconnects or ends mission
    Ensures entities are deleted on all clients
]]
RegisterNetEvent('mack-gunforhire:client:cleanupSyncedEntities', function(missionKey)
    DebugPrint('Received cleanup request for: ' .. missionKey)
    -- This event is broadcast to all clients to ensure entity cleanup
    -- The actual entity deletion is handled by the mission owner
    -- Other clients just need to know the mission ended
end)

--[[
    RECEIVE REWARD NOTIFICATION
    Called from server when rewards are given (ONLY to mission taker)
]]
RegisterNetEvent('mack-gunforhire:client:rewardReceived', function(cash, xp, items)
    SendNotification('notify_reward_title', string.format(_L('notify_reward_cash'), cash), 'REWARD_MONEY')
    
    Wait(1000)
    
    if xp and xp > 0 then
        TriggerEvent('bln_notify:send', {
            title = string.format(_L('notify_reward_xp'), xp),
            duration = 3000,
            placement = Config.Notifications.Placement
        }, 'TIP_XP')
    end
    
    Wait(500)
    
    if items then
        for _, item in ipairs(items) do
            TriggerEvent('bln_notify:send', {
                title = string.format(_L('notify_reward_item'), item.amount, item.name),
                duration = 3000,
                placement = Config.Notifications.Placement
            }, 'TIP')
        end
    end
end)

--[[
    INITIALIZE ON RESOURCE START
]]
CreateThread(function()
    Wait(1000) -- Wait for other systems to initialize
    InitializeQuestGiver()
    DebugPrint('mack-gunforhire client initialized')
end)

--[[
    CLEANUP ON RESOURCE STOP
]]
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DebugPrint('Resource stopping - cleaning up')
    
    -- Cleanup mission
    CleanupMission()
    
    -- Remove ox_target from quest giver before deleting
    if QuestGiverNPC and DoesEntityExist(QuestGiverNPC) then
        pcall(function()
            exports['ox_target']:removeLocalEntity(QuestGiverNPC, 'gunforhire_talk')
        end)
        SetEntityAsMissionEntity(QuestGiverNPC, false, true)
        DeleteEntity(QuestGiverNPC)
        DebugPrint('Quest Giver NPC deleted')
    end
    
    -- Remove quest giver blip
    RemoveBlipSafe(QuestGiverBlip)
    
    -- Delete contact NPCs
    for missionId, npc in pairs(ContactNPCs) do
        if npc and DoesEntityExist(npc) then
            pcall(function()
                exports['ox_target']:removeLocalEntity(npc, 'contact_talk_' .. missionId)
            end)
            SetEntityAsMissionEntity(npc, false, true)
            DeleteEntity(npc)
        end
    end
    
    -- Remove contact blips
    for _, blip in pairs(ContactBlips) do
        RemoveBlipSafe(blip)
    end
    
    DebugPrint('Resource cleanup complete')
end)

-- Export mission state for other scripts
exports('GetMissionState', function()
    return MissionState
end)

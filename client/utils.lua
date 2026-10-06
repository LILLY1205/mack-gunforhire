--[[
    Utility Functions for mack-gunforhire
    Contains reusable functions for model loading, blips, NPCs, and cleanup
]]

local RSGCore = exports['rsg-core']:GetCoreObject()

--[[
    DEBUG PRINT
    Only prints if Config.Debug is true
]]
function DebugPrint(msg)
    if Config.Debug then
        print('^6[mack-gunforhire]^7 ' .. tostring(msg))
    end
end

--[[
    MODEL LOADING
    Loads a model with timeout protection
    @param model string - Model name or hash
    @return boolean - Success status
]]
function LoadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    
    if HasModelLoaded(hash) then
        return true
    end
    
    RequestModel(hash)
    local timeout = 0
    
    while not HasModelLoaded(hash) and timeout < 10000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    if HasModelLoaded(hash) then
        DebugPrint('Model loaded: ' .. tostring(model))
        return true
    else
        DebugPrint('^1Failed to load model: ' .. tostring(model) .. '^7')
        return false
    end
end

--[[
    ANIMATION DICTIONARY LOADING
    Loads an anim dict with timeout
    @param dict string - Animation dictionary name
    @return boolean - Success status
]]
function LoadAnimDict(dict)
    if HasAnimDictLoaded(dict) then
        return true
    end
    
    RequestAnimDict(dict)
    local timeout = 0
    
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Wait(100)
        timeout = timeout + 100
    end
    
    return HasAnimDictLoaded(dict)
end

--[[
    CREATE BLIP FOR COORDS
    Creates a blip at specified coordinates (RedM pattern)
    @param coords vector3 - Blip position
    @param sprite number - Blip sprite hash
    @param label string - Blip label (locale key or string)
    @param color string - Blip color modifier (optional)
    @param scale number - Blip scale (optional)
    @return blip handle
]]
function CreateBlipForCoords(coords, sprite, label, color, scale)
    -- Create blip using BlipAddForCoords pattern
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    
    -- Set sprite
    if sprite then
        SetBlipSprite(blip, sprite, true)
    end
    
    -- Set label using CreateVarString
    if label then
        local labelText = (Locales and Locales['en'] and Locales['en'][label]) or label
        local varString = CreateVarString(10, 'LITERAL_STRING', labelText)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, varString)
    end
    
    -- Set color
    if color then
        Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey(color))
    end
    
    -- Set scale
    if scale then
        SetBlipScale(blip, scale)
    end
    
    DebugPrint('Blip created at ' .. tostring(coords))
    return blip
end

--[[
    CREATE BLIP FOR ENTITY
    Creates a blip attached to an entity (RedM pattern)
    @param entity number - Entity handle
    @param sprite number - Blip sprite hash
    @param label string - Blip label
    @param color string - Blip color modifier (optional)
    @return blip handle
]]
function CreateBlipForEntity(entity, sprite, label, color)
    -- Create blip on entity
    local blip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, entity)
    
    -- Set sprite
    if sprite then
        SetBlipSprite(blip, sprite, true)
    end
    
    -- Set label using CreateVarString
    if label then
        local labelText = (Locales and Locales['en'] and Locales['en'][label]) or label
        local varString = CreateVarString(10, 'LITERAL_STRING', labelText)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, varString)
    end
    
    -- Set color
    if color then
        Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey(color))
    end
    
    DebugPrint('Entity blip created')
    return blip
end

--[[
    CREATE AREA BLIP
    Creates a radius blip for search areas (RedM pattern)
    @param coords vector3 - Center position
    @param radius number - Area radius
    @param label string - Blip label
    @return blip handle
]]
function CreateAreaBlip(coords, radius, label)
    -- Create radius/area blip
    local blip = Citizen.InvokeNative(0x45F13B7E0A15C880, -1282792512, coords.x, coords.y, coords.z, radius)
    
    -- Set sprite for area
    SetBlipSprite(blip, joaat('blip_area_search'), true)
    
    -- Set label using CreateVarString
    if label then
        local labelText = (Locales and Locales['en'] and Locales['en'][label]) or label
        local varString = CreateVarString(10, 'LITERAL_STRING', labelText)
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, varString)
    end
    
    DebugPrint('Area blip created with radius ' .. radius)
    return blip
end

--[[
    REMOVE BLIP SAFELY
    Removes a blip if it exists
    @param blip number - Blip handle
]]
function RemoveBlipSafe(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
        DebugPrint('Blip removed')
    end
end

--[[
    SPAWN NPC
    Spawns a ped with full configuration (networked for sync)
    @param model string - Model name
    @param coords vector4 - Position and heading
    @param options table - Configuration options
    @return ped handle
]]
function SpawnNPC(model, coords, options)
    options = options or {}
    
    if not LoadModel(model) then
        return nil
    end
    
    local hash = GetHashKey(model)
    -- Network params: isNetwork=true, netMissionEntity=true for sync
    local ped = CreatePed(hash, coords.x, coords.y, coords.z, coords.w or 0.0, true, true, true, true)
    
    if not DoesEntityExist(ped) then
        DebugPrint('^1Failed to spawn NPC: ' .. model .. '^7')
        return nil
    end
    
    -- Make persistent
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    
    -- Network sync - ensure entity exists on all clients
    local netId = NetworkGetNetworkIdFromEntity(ped)
    if netId and netId ~= 0 then
        SetNetworkIdExistsOnAllMachines(netId, true)
        
        -- Register with server for tracking (if mission is active)
        if MissionState and MissionState.active and MissionState.missionId then
            TriggerServerEvent('mack-gunforhire:server:registerEntity', MissionState.missionId, netId, 'npc')
        end
    end
    
    -- Freeze position if specified
    if options.frozen then
        FreezeEntityPosition(ped, true)
    end
    
    -- Make invincible if specified
    if options.invincible then
        SetEntityInvincible(ped, true)
    end
    
    -- Block events
    if options.blockEvents ~= false then
        SetBlockingOfNonTemporaryEvents(ped, true)
    end
    
    -- Set scenario/animation
    if options.scenario then
        TaskStartScenarioInPlace(ped, GetHashKey(options.scenario), -1, true, false, false, false)
    end
    
    -- Set relationship
    if options.relationshipGroup then
        SetPedRelationshipGroupHash(ped, GetHashKey(options.relationshipGroup))
    end
    
    SetModelAsNoLongerNeeded(hash)
    DebugPrint('NPC spawned (networked): ' .. model .. ' at ' .. tostring(coords))
    
    return ped
end

--[[
    SPAWN HOSTILE NPC
    Spawns an enemy NPC configured for combat (networked for sync)
    @param model string - Model name
    @param coords vector3 - Position
    @return ped handle
]]
function SpawnHostileNPC(model, coords)
    if not LoadModel(model) then
        return nil
    end
    
    local hash = GetHashKey(model)
    local ped = CreatePed(hash, coords.x, coords.y, coords.z, math.random(0, 360), true, true, true, true)
    
    if not DoesEntityExist(ped) then
        return nil
    end
    
    -- Make persistent
    Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
    SetEntityAsMissionEntity(ped, true, true)
    
    -- Network sync - ensure entity exists on all clients
    local netId = NetworkGetNetworkIdFromEntity(ped)
    if netId and netId ~= 0 then
        SetNetworkIdExistsOnAllMachines(netId, true)
        
        -- Register with server for tracking
        if MissionState and MissionState.active and MissionState.missionId then
            TriggerServerEvent('mack-gunforhire:server:registerEntity', MissionState.missionId, netId, 'enemy')
        end
    end
    
    -- Set enemy relationship
    SetPedRelationshipGroupHash(ped, GetHashKey('ENEMY'))
    SetRelationshipBetweenGroups(5, GetHashKey('ENEMY'), GetHashKey('PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey('ENEMY'))
    
    -- Combat configuration
    SetPedCombatAttributes(ped, 46, true)  -- Always fight
    SetPedCombatAttributes(ped, 5, true)   -- Can fight unarmed
    SetPedCombatAttributes(ped, 0, true)   -- Can use cover
    SetPedCombatAttributes(ped, 58, true)  -- Disable flee
    SetPedCombatRange(ped, 2)              -- Long range
    SetPedAccuracy(ped, Config.Combat.Accuracy)
    SetPedShootRate(ped, Config.Combat.ShootRate)
    SetPedSeeingRange(ped, Config.Combat.SeeingRange)
    SetPedHearingRange(ped, Config.Combat.HearingRange)
    SetPedCombatMovement(ped, 2)           -- Offensive
    
    -- Never flee
    SetPedFleeAttributes(ped, 0, false)
    SetPedFleeAttributes(ped, 512, false)
    
    -- Pathfinding
    SetPedPathCanUseClimbovers(ped, true)
    SetPedPathCanUseLadders(ped, true)
    SetPedCanRagdoll(ped, true)
    
    -- Allow events for combat
    SetBlockingOfNonTemporaryEvents(ped, false)
    
    -- Give weapon
    local weapons = Config.EnemyWeapons.Ranged
    local weapon = weapons[math.random(#weapons)]
    GiveWeaponToPed(ped, GetHashKey(weapon), 100, true, true)
    SetPedAmmo(ped, GetHashKey(weapon), 100)
    SetCurrentPedWeapon(ped, GetHashKey(weapon), true)
    SetPedInfiniteAmmoClip(ped, true)
    
    SetModelAsNoLongerNeeded(hash)
    DebugPrint('Hostile NPC spawned (networked): ' .. model)
    
    return ped
end

--[[
    SPAWN ANIMAL
    Spawns an animal configured for combat (networked for sync)
    @param model string - Animal model
    @param coords vector3 - Position
    @param relationshipGroup string - Relationship group name
    @return animal handle
]]
function SpawnAnimal(model, coords, relationshipGroup)
    if not LoadModel(model) then
        return nil
    end
    
    local hash = GetHashKey(model)
    local animal = CreatePed(hash, coords.x, coords.y, coords.z, math.random(0, 360), true, true, true, true)
    
    if not DoesEntityExist(animal) then
        return nil
    end
    
    -- Make persistent
    Citizen.InvokeNative(0x283978A15512B2FE, animal, true)
    SetEntityAsMissionEntity(animal, true, true)
    
    -- Network sync - ensure entity exists on all clients
    local netId = NetworkGetNetworkIdFromEntity(animal)
    if netId and netId ~= 0 then
        SetNetworkIdExistsOnAllMachines(netId, true)
        
        -- Register with server for tracking
        if MissionState and MissionState.active and MissionState.missionId then
            TriggerServerEvent('mack-gunforhire:server:registerEntity', MissionState.missionId, netId, 'animal')
        end
    end
    
    -- Set aggressive relationship
    local group = relationshipGroup or 'HOSTILE_ANIMAL'
    SetPedRelationshipGroupHash(animal, GetHashKey(group))
    SetRelationshipBetweenGroups(5, GetHashKey(group), GetHashKey('PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey(group))
    
    -- Make aggressive
    Citizen.InvokeNative(0xF166E48407BAC484, animal, PlayerPedId(), 0, 0)
    FreezeEntityPosition(animal, false)
    
    SetModelAsNoLongerNeeded(hash)
    DebugPrint('Animal spawned (networked): ' .. model)
    
    return animal
end

--[[
    DELETE ENTITY SAFELY
    Deletes an entity if it exists
    @param entity number - Entity handle
]]
function DeleteEntitySafe(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
        DebugPrint('Entity deleted')
    end
end

--[[
    SET GPS ROUTE
    Sets a GPS route to coordinates
    @param coords vector3 - Destination
]]
function SetGPSRoute(coords)
    Citizen.InvokeNative(0x3D3D15AF7BCAAF83, 6, true, true)
    Citizen.InvokeNative(0x64C59DD6834FA942, coords.x, coords.y, coords.z)
    Citizen.InvokeNative(0x4426D65E029A4DC0, true)
    DebugPrint('GPS route set to ' .. tostring(coords))
end

--[[
    CLEAR GPS ROUTE
    Clears the current GPS route
]]
function ClearGPSRoute()
    SetGpsMultiRouteRender(false)
    Citizen.InvokeNative(0x3D3D15AF7BCAAF83, 6, false, false)
    DebugPrint('GPS route cleared')
end

--[[
    SEND NOTIFICATION
    Sends a notification using bln_notify
    @param title string - Notification title (locale key or string)
    @param description string - Description (locale key or string, optional)
    @param template string - Template name (SUCCESS, ERROR, INFO, TIP, etc.)
    @param icon string - Icon override (optional)
]]
function SendNotification(title, description, template, icon)
    local titleText = Locales['en'][title] or title
    local descText = description and (Locales['en'][description] or description) or nil
    
    local options = {
        title = titleText,
        description = descText,
        duration = Config.Notifications.Duration.Medium,
        placement = Config.Notifications.Placement
    }
    
    if icon then
        options.icon = icon
    end
    
    TriggerEvent('bln_notify:send', options, template or 'INFO')
    DebugPrint('Notification sent: ' .. titleText)
end

--[[
    SEND DIALOGUE
    Plays a sequence of dialogue notifications
    @param dialogueKeys table - Array of locale keys
    @param delay number - Delay between each line (ms)
    @param callback function - Called when dialogue completes
]]
function PlayDialogue(dialogueKeys, delay, callback)
    delay = delay or 5000
    
    CreateThread(function()
        for i, key in ipairs(dialogueKeys) do
            local text = Locales['en'][key] or key
            TriggerEvent('bln_notify:send', {
                title = text,
                duration = delay,
                placement = 'top-center'
            }, 'TIP')
            
            if i < #dialogueKeys then
                Wait(delay)
            end
        end
        
        Wait(delay)
        
        if callback then
            callback()
        end
    end)
end

--[[
    GET DISTANCE TO COORDS
    Calculates distance from player to coordinates
    @param coords vector3 - Target coordinates
    @return number - Distance
]]
function GetDistanceToCoords(coords)
    local playerCoords = GetEntityCoords(PlayerPedId())
    return #(playerCoords - coords)
end

--[[
    IS PLAYER DEAD
    Checks if player is dead or dying
    @return boolean
]]
function IsPlayerDead()
    local ped = PlayerPedId()
    return IsEntityDead(ped) or IsPedDeadOrDying(ped, true)
end

--[[
    FREEZE PLAYER
    Freezes player for animations/interactions
    @param freeze boolean - Freeze state
]]
function FreezePlayer(freeze)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, freeze)
    
    if freeze then
        SetCurrentPedWeapon(ped, GetHashKey('WEAPON_UNARMED'), true)
    end
end

-- Export utility functions for other resources
exports('DebugPrint', DebugPrint)
exports('LoadModel', LoadModel)
exports('SendNotification', SendNotification)

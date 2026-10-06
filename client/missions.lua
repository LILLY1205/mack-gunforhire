--[[
    Mission Type Handlers for mack-gunforhire
    Contains specific logic for hunt, combat, escort, and rescue missions
]]

local RSGCore = exports['rsg-core']:GetCoreObject()

--[[
    =====================================
    HUNT MISSION TYPE
    Track and kill dangerous animals
    =====================================
]]
function StartHuntMission(missionData)
    DebugPrint('Starting hunt mission: ' .. missionData.id)
    
    local objectives = missionData.objectives
    
    -- Create search area blip
    MissionState.areaBlip = CreateAreaBlip(
        objectives.searchArea.coords,
        objectives.searchArea.radius,
        'blip_search_area'
    )
    
    -- Create bait zone blip so player knows where to go
    local baitBlip = CreateBlipForCoords(
        objectives.baitZone.coords,
        Config.Blips.BaitZone.Sprite,
        'blip_objective',
        Config.Blips.BaitZone.Color,
        Config.Blips.BaitZone.Scale
    )
    table.insert(MissionState.spawnedBlips, baitBlip)
    
    -- Set GPS to bait zone
    SetGPSRoute(objectives.baitZone.coords)
    
    SendNotification('notify_go_to_objective', nil, 'INFO')
    
    -- Spawn first wave of enemies
    if missionData.enemies then
        Wait(missionData.enemies.alertDelay or 5000)
        SpawnEnemyWave(missionData, 1)
    end
    
    -- Create bait zone target
    exports['ox_target']:addSphereZone({
        coords = objectives.baitZone.coords,
        radius = objectives.baitZone.radius,
        debug = Config.Debug,
        options = {
            {
                name = 'place_bait_' .. missionData.id,
                label = _L('target_place_bait'),
                icon = 'fas fa-drumstick-bite',
                distance = 3.0,
                onSelect = function()
                    PlaceBait(missionData)
                end
            }
        }
    })
    
    DebugPrint('Hunt mission objective set up')
end

--[[
    PLACE BAIT
    Player places bait to lure the animal
]]
function PlaceBait(missionData)
    local baitZone = missionData.objectives.baitZone
    
    -- Check if player has required item
    RSGCore.Functions.TriggerCallback('mack-gunforhire:server:hasItem', function(hasItem)
        if not hasItem then
            SendNotification('notify_no_item', string.format(_L('notify_need_item'), baitZone.item), 'ERROR')
            return
        end
        
        -- Remove bait zone target
        exports['ox_target']:removeZone('place_bait_' .. missionData.id)
        
        -- Freeze player and play animation
        FreezePlayer(true)
        local ped = PlayerPedId()
        TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), 5500, true, false, false, false)
        
        -- Progress bar
        if lib.progressBar({
            duration = 5500,
            label = _L('progress_placing_bait'),
            useWhileDead = false,
            canCancel = false
        }) then
            ClearPedTasks(ped)
            FreezePlayer(false)
            
            -- Remove item from inventory
            TriggerServerEvent('mack-gunforhire:server:removeItem', baitZone.item, baitZone.itemCount)
            
            -- Format the notification with item name
            local usedMsg = string.format(_L('notify_item_used'), baitZone.item)
            SendNotification(usedMsg, nil, 'INFO')
            
            -- Spawn the animal
            SpawnHuntTarget(missionData)
            
            -- Spawn second wave of enemies after delay
            if missionData.enemies and #missionData.enemies.waves > 1 then
                CreateThread(function()
                    Wait(missionData.enemies.waves[2].delay or 45000)
                    if MissionState.active and MissionState.missionId == missionData.id then
                        SpawnEnemyWave(missionData, 2)
                    end
                end)
            end
        else
            FreezePlayer(false)
        end
        
    end, baitZone.item, baitZone.itemCount)
end

--[[
    SPAWN HUNT TARGET
    Spawns the animal target for hunt missions
]]
function SpawnHuntTarget(missionData)
    local animalConfig = missionData.animal
    local packSize = animalConfig.packSize or 1
    
    for i = 1, packSize do
        local spawnLoc = animalConfig.spawnLocations[math.min(i, #animalConfig.spawnLocations)]
        local animal = SpawnAnimal(animalConfig.model, spawnLoc, missionData.id .. '_animal')
        
        if animal then
            if i == 1 then
                -- Main target
                MissionState.targetAnimal = animal
                
                -- Create blip for animal using Animal blip sprite
                MissionState.targetBlip = CreateBlipForEntity(
                    animal,
                    Config.Blips.Animal.Sprite,
                    animalConfig.blipLabel,
                    Config.Blips.Animal.Color
                )
                
                -- Remove area blip and bait zone blips
                RemoveBlipSafe(MissionState.areaBlip)
                MissionState.areaBlip = nil
                
                -- Remove bait zone blips
                for _, blip in ipairs(MissionState.spawnedBlips) do
                    RemoveBlipSafe(blip)
                end
                MissionState.spawnedBlips = {}
            else
                table.insert(MissionState.spawnedEntities, animal)
            end
            
            -- Make animal attack player
            TaskCombatPed(animal, PlayerPedId(), 0, 16)
        end
    end
    
    -- Monitor animal status
    CreateThread(function()
        while MissionState.active and MissionState.missionId == missionData.id do
            Wait(1000)
            
            if MissionState.targetAnimal then
                if not DoesEntityExist(MissionState.targetAnimal) then
                    -- Animal was deleted somehow
                    SendNotification('notify_target_escaped', nil, 'ERROR')
                    FailMission('notify_target_escaped')
                    break
                    
                elseif IsPedDeadOrDying(MissionState.targetAnimal, true) then
                    -- Animal killed - mission success
                    RemoveBlipSafe(MissionState.targetBlip)
                    MissionState.targetBlip = nil
                    
                    SendNotification('notify_target_killed', nil, 'SUCCESS')
                    CompleteMission()
                    break
                    
                else
                    -- Check if animal escaped too far
                    local animalCoords = GetEntityCoords(MissionState.targetAnimal)
                    local baitCoords = missionData.objectives.baitZone.coords
                    local distance = #(animalCoords - baitCoords)
                    
                    if distance > animalConfig.escapeDistance then
                        SendNotification('notify_target_escaped', nil, 'ERROR')
                        FailMission('notify_target_escaped')
                        break
                    end
                end
            end
        end
    end)
    
    DebugPrint('Hunt target spawned')
end

--[[
    =====================================
    COMBAT MISSION TYPE
    Clear an enemy camp
    =====================================
]]
function StartCombatMission(missionData)
    DebugPrint('Starting combat mission: ' .. missionData.id)
    
    local objectives = missionData.objectives
    
    -- Set GPS to target zone
    if objectives.targetZone then
        SetGPSRoute(objectives.targetZone.coords)
        
        -- Create area blip
        MissionState.areaBlip = CreateAreaBlip(
            objectives.targetZone.coords,
            objectives.targetZone.radius,
            'blip_objective'
        )
    end
    
    SendNotification('notify_go_to_objective', nil, 'INFO')
    
    -- Spawn all enemy waves
    for waveIndex, wave in ipairs(missionData.enemies.waves) do
        CreateThread(function()
            Wait(wave.delay)
            if MissionState.active and MissionState.missionId == missionData.id then
                SpawnEnemyWave(missionData, waveIndex)
                
                if waveIndex > 1 then
                    SendNotification('notify_enemies_incoming', nil, 'ERROR')
                end
            end
        end)
    end
    
    -- Monitor enemy status
    CreateThread(function()
        Wait(2000) -- Wait for enemies to spawn
        
        while MissionState.active and MissionState.missionId == missionData.id do
            Wait(2000)
            
            -- Count alive enemies
            local aliveCount = 0
            for i = #MissionState.spawnedEnemies, 1, -1 do
                local enemy = MissionState.spawnedEnemies[i]
                if DoesEntityExist(enemy) and not IsPedDeadOrDying(enemy, true) then
                    aliveCount = aliveCount + 1
                else
                    table.remove(MissionState.spawnedEnemies, i)
                end
            end
            
            DebugPrint('Enemies remaining: ' .. aliveCount)
            
            -- Check if all enemies dead
            if aliveCount == 0 and #MissionState.spawnedEnemies == 0 then
                -- Wait a bit to ensure all waves have had chance to spawn
                Wait(3000)
                
                -- Recount
                aliveCount = 0
                for _, enemy in ipairs(MissionState.spawnedEnemies) do
                    if DoesEntityExist(enemy) and not IsPedDeadOrDying(enemy, true) then
                        aliveCount = aliveCount + 1
                    end
                end
                
                if aliveCount == 0 then
                    RemoveBlipSafe(MissionState.areaBlip)
                    MissionState.areaBlip = nil
                    
                    SendNotification('notify_all_enemies_dead', nil, 'SUCCESS')
                    CompleteMission()
                    break
                end
            end
        end
    end)
end

--[[
    =====================================
    ESCORT MISSION TYPE
    Protect a wagon convoy
    =====================================
]]
function StartEscortMission(missionData)
    DebugPrint('Starting escort mission: ' .. missionData.id)
    
    local wagon = missionData.wagon
    
    -- Spawn wagon
    if not LoadModel(wagon.model) then
        DebugPrint('^1Failed to load wagon model^7')
        FailMission('Error loading wagon')
        return
    end
    
    local wagonEntity = CreateVehicle(
        GetHashKey(wagon.model),
        wagon.spawnCoords.x,
        wagon.spawnCoords.y,
        wagon.spawnCoords.z,
        wagon.spawnCoords.w,
        true, true
    )
    
    if not DoesEntityExist(wagonEntity) then
        DebugPrint('^1Failed to spawn wagon^7')
        return
    end
    
    table.insert(MissionState.spawnedEntities, wagonEntity)
    
    -- Spawn wagon driver
    local driver = SpawnNPC(wagon.driverModel, wagon.spawnCoords, {
        frozen = false,
        invincible = false,
        relationshipGroup = 'CIVILIAN'
    })
    
    if driver then
        SetPedIntoVehicle(driver, wagonEntity, -1)
        table.insert(MissionState.spawnedEntities, driver)
    end
    
    -- Create wagon blip
    local wagonBlip = CreateBlipForEntity(wagonEntity, Config.Blips.Objective.Sprite, 'Wagon', Config.Blips.Objective.Color)
    table.insert(MissionState.spawnedBlips, wagonBlip)
    
    -- Set GPS to destination
    SetGPSRoute(wagon.destination)
    
    SendNotification('notify_go_to_objective', nil, 'INFO')
    
    -- Make driver go to destination
    if driver then
        TaskVehicleDriveToCoord(
            driver,
            wagonEntity,
            wagon.destination.x,
            wagon.destination.y,
            wagon.destination.z,
            wagon.speed or 5.0,
            0,
            GetHashKey(wagon.model),
            786603,
            5.0
        )
    end
    
    -- Setup ambush points
    for i, ambush in ipairs(missionData.ambushPoints or {}) do
        CreateThread(function()
            while MissionState.active and MissionState.missionId == missionData.id do
                Wait(1000)
                
                if DoesEntityExist(wagonEntity) then
                    local wagonCoords = GetEntityCoords(wagonEntity)
                    local distance = #(wagonCoords - ambush.coords)
                    
                    if distance < ambush.triggerRadius then
                        DebugPrint('Ambush triggered at point ' .. i)
                        SendNotification('notify_enemies_incoming', nil, 'ERROR')
                        
                        -- Spawn ambush enemies
                        local models = Config.EnemyModels[ambush.enemies.type]
                        for j, loc in ipairs(ambush.enemies.locations) do
                            local model = models[math.random(#models)]
                            local enemy = SpawnHostileNPC(model, loc)
                            if enemy then
                                table.insert(MissionState.spawnedEnemies, enemy)
                                TaskCombatPed(enemy, PlayerPedId(), 0, 16)
                            end
                        end
                        
                        break
                    end
                else
                    break
                end
            end
        end)
    end
    
    -- Monitor wagon and destination
    CreateThread(function()
        while MissionState.active and MissionState.missionId == missionData.id do
            Wait(1000)
            
            if not DoesEntityExist(wagonEntity) or IsVehicleDriveable(wagonEntity, false) == false then
                SendNotification('notify_wagon_destroyed', nil, 'ERROR')
                FailMission('notify_wagon_destroyed')
                break
            end
            
            local wagonCoords = GetEntityCoords(wagonEntity)
            local distance = #(wagonCoords - wagon.destination)
            
            if distance < 20.0 then
                ClearGPSRoute()
                SendNotification('notify_mission_complete', nil, 'SUCCESS')
                CompleteMission()
                break
            end
        end
    end)
end

--[[
    =====================================
    RESCUE MISSION TYPE
    Save a kidnapped NPC
    =====================================
]]
function StartRescueMission(missionData)
    DebugPrint('Starting rescue mission: ' .. missionData.id)
    
    local hostageConfig = missionData.hostage
    local objectives = missionData.objectives
    
    -- Set GPS to rescue zone
    SetGPSRoute(objectives.rescueZone.coords)
    
    -- Create area blip
    MissionState.areaBlip = CreateAreaBlip(
        objectives.rescueZone.coords,
        objectives.rescueZone.radius,
        'blip_objective'
    )
    
    SendNotification('notify_go_to_objective', nil, 'INFO')
    
    -- Spawn enemies at location
    for waveIndex, wave in ipairs(missionData.enemies.waves) do
        CreateThread(function()
            Wait(wave.delay)
            if MissionState.active and MissionState.missionId == missionData.id then
                SpawnEnemyWave(missionData, waveIndex)
            end
        end)
    end
    
    -- Spawn hostage
    local hostage = SpawnNPC(hostageConfig.model, vector4(hostageConfig.location.x, hostageConfig.location.y, hostageConfig.location.z, 0), {
        frozen = true,
        invincible = false,
        scenario = hostageConfig.tied and 'WORLD_HUMAN_SIT_GROUND' or nil,
        relationshipGroup = 'CIVILIAN'
    })
    
    if hostage then
        MissionState.targetAnimal = hostage -- Reusing for hostage tracking
        
        -- Create blip for hostage
        MissionState.targetBlip = CreateBlipForEntity(
            hostage,
            Config.Blips.Objective.Sprite,
            'Hostage',
            Config.Blips.Objective.Color
        )
        
        -- Add rescue target
        exports['ox_target']:addLocalEntity(hostage, {
            {
                name = 'rescue_hostage_' .. missionData.id,
                label = _L('target_rescue_hostage'),
                icon = 'fas fa-hands-helping',
                distance = 2.0,
                onSelect = function()
                    RescueHostage(missionData, hostage)
                end
            }
        })
    end
    
    -- Monitor hostage status
    CreateThread(function()
        while MissionState.active and MissionState.missionId == missionData.id do
            Wait(1000)
            
            if hostage and DoesEntityExist(hostage) then
                if IsPedDeadOrDying(hostage, true) then
                    SendNotification('notify_hostage_killed', nil, 'ERROR')
                    FailMission('notify_hostage_killed')
                    break
                end
            end
        end
    end)
end

--[[
    RESCUE HOSTAGE
    Untie and escort the hostage back
]]
function RescueHostage(missionData, hostage)
    -- Remove rescue target
    exports['ox_target']:removeLocalEntity(hostage, 'rescue_hostage_' .. missionData.id)
    
    -- Play untie animation
    FreezePlayer(true)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), 4000, true, false, false, false)
    
    if lib.progressBar({
        duration = 4000,
        label = _L('progress_untying'),
        useWhileDead = false,
        canCancel = false
    }) then
        ClearPedTasks(ped)
        FreezePlayer(false)
        
        -- Free the hostage
        FreezeEntityPosition(hostage, false)
        ClearPedTasks(hostage)
        
        -- Make hostage follow player
        TaskFollowToOffsetOfEntity(hostage, ped, 0.0, -1.5, 0.0, 3.0, -1, 1.0, true)
        
        -- Remove area blip
        RemoveBlipSafe(MissionState.areaBlip)
        MissionState.areaBlip = nil
        
        -- Set GPS to return location
        local returnZone = missionData.objectives.returnZone
        SetGPSRoute(returnZone.coords)
        
        SendNotification('notify_return_to_giver', nil, 'INFO')
        
        -- Monitor return
        CreateThread(function()
            while MissionState.active and MissionState.missionId == missionData.id do
                Wait(1000)
                
                if DoesEntityExist(hostage) and not IsPedDeadOrDying(hostage, true) then
                    local hostageCoords = GetEntityCoords(hostage)
                    local distance = #(hostageCoords - returnZone.coords)
                    
                    if distance < returnZone.radius then
                        ClearGPSRoute()
                        RemoveBlipSafe(MissionState.targetBlip)
                        MissionState.targetBlip = nil
                        
                        CompleteMission()
                        break
                    end
                else
                    break
                end
            end
        end)
    else
        FreezePlayer(false)
    end
end

--[[
    =====================================
    ENEMY SPAWNING
    =====================================
]]
function SpawnEnemyWave(missionData, waveIndex)
    local wave = missionData.enemies.waves[waveIndex]
    if not wave then return end
    
    local models = Config.EnemyModels[missionData.enemies.type]
    if not models then
        DebugPrint('^1Unknown enemy type: ' .. missionData.enemies.type .. '^7')
        return
    end
    
    DebugPrint('Spawning wave ' .. waveIndex .. ' with ' .. wave.count .. ' enemies')
    
    for i = 1, math.min(wave.count, #wave.locations) do
        local model = models[math.random(#models)]
        local loc = wave.locations[i]
        
        local enemy = SpawnHostileNPC(model, loc)
        
        if enemy then
            table.insert(MissionState.spawnedEnemies, enemy)
            
            -- Create blip for enemy
            local blip = CreateBlipForEntity(enemy, Config.Blips.Enemy.Sprite, 'blip_enemy', Config.Blips.Enemy.Color)
            table.insert(MissionState.spawnedBlips, blip)
            
            -- Make enemy attack player
            Wait(100)
            TaskCombatPed(enemy, PlayerPedId(), 0, 16)
            
            DebugPrint('Enemy spawned at wave ' .. waveIndex)
        end
        
        Wait(200) -- Stagger spawns
    end
    
    if waveIndex == 1 then
        SendNotification('notify_enemies_nearby', nil, 'ERROR')
    end
end

--[[
    ENEMY DEATH TRACKING
    Removes blips from dead enemies
]]
CreateThread(function()
    while true do
        Wait(2000)
        
        if MissionState.active and #MissionState.spawnedEnemies > 0 then
            for i = #MissionState.spawnedBlips, 1, -1 do
                local blip = MissionState.spawnedBlips[i]
                if blip and DoesBlipExist(blip) then
                    local entity = Citizen.InvokeNative(0x4D6753C11789C69D, blip)
                    if entity and DoesEntityExist(entity) and IsPedDeadOrDying(entity, true) then
                        RemoveBlipSafe(blip)
                        table.remove(MissionState.spawnedBlips, i)
                    end
                end
            end
        end
    end
end)

DebugPrint('Mission handlers loaded')

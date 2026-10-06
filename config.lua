Config = {}

--[[
    ========================================
    GLOBAL SETTINGS
    ========================================
]]
Config.Debug = true                     -- Enable/disable debug prints (set false for production)
Config.Locale = 'en'                    -- Language setting
Config.TargetDistance = 2.5             -- ox_target interaction distance
Config.DefaultCooldown = 3600           -- Default mission cooldown (1 hour in seconds)

--[[
    JOB RESTRICTIONS
]]
Config.RequireJob = false               -- Set true to restrict to specific jobs
Config.AllowedJobs = {
    'bountyhunter',
    'marshal',
    'vallaw',
    'rholaw',
    'blklaw',
    'stdenlaw',
    'strlaw'
}

--[[
    QUEST GIVER NPC (Riggs-style main contact)
]]
Config.QuestGiver = {
    Model = 'mp_g_m_m_mercs_01',      -- Valid RedM NPC model
    Location = vector4(-269.33, 776.57, 118.44, 319.69),
    Scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    Invincible = true,
    Frozen = true,
    Blip = {
        Enabled = true,
        Sprite = 990667866,             -- blip_hat
        Color = 'BLIP_MODIFIER_MP_COLOR_32',
        Scale = 0.8,
        Label = 'blip_quest_giver'      -- Locale key
    }
}

--[[
    ENEMY MODELS
]]
Config.EnemyModels = {
    Bandits = {
        'g_m_m_unibanditos_01',
        'g_m_m_unibanditos_02',
        'g_m_m_uniexconfeds_01',
        'g_m_m_uniexconfeds_02'
    },
    Natives = {
        'a_m_m_wapwarriors_01'
    },
    Pinkertons = {
        'mp_g_m_m_bountyhunters_01',
        's_m_m_marshals_01'
    }
}

--[[
    ENEMY WEAPONS
]]
Config.EnemyWeapons = {
    Melee = {
        'weapon_melee_knife',
        'weapon_melee_hatchet',
        'weapon_thrown_tomahawk'
    },
    Ranged = {
        'weapon_revolver_cattleman',
        'weapon_revolver_schofield',
        'weapon_repeater_carbine',
        'weapon_rifle_springfield'
    }
}

--[[
    ANIMAL MODELS
]]
Config.AnimalModels = {
    Lion = 'a_c_lionmangy_01',
    Wolf = 'a_c_wolf_01',
    Bear = 'a_c_bear_01',
    Cougar = 'a_c_cougar_01'
}

--[[
    WAGON MODELS
]]
Config.WagonModels = {
    Supply = 'wagon02x',
    Covered = 'wagonCircus01x',
    Prison = 'wagonprison01x'
}

--[[
    HORSE MODELS (for escort/enemy mounts)
]]
Config.HorseModels = {
    'a_c_horse_americanpaint_greyovero',
    'a_c_horse_morgan_bay',
    'a_c_horse_kentuckysaddle_chestnutpinto',
    'a_c_horse_tennesseewalker_dapplebay'
}

--[[
    NPC SCENARIOS (Idle animations)
]]
Config.NPCScenarios = {
    'WORLD_HUMAN_SMOKE',
    'WORLD_HUMAN_LEAN_WALL',
    'WORLD_HUMAN_STAND_WAITING',
    'WORLD_HUMAN_LEAN_BACK_WALL',
    'WORLD_HUMAN_DRINKING',
    'WORLD_HUMAN_GUARD_LEAN_WALL'
}

--[[
    COMBAT SETTINGS
]]
Config.Combat = {
    Accuracy = 60,                      -- Enemy accuracy (0-100)
    ShootRate = 80,                     -- Shoot rate
    CombatRange = 50.0,                 -- Combat engagement range
    SeeingRange = 100.0,                -- Vision range
    HearingRange = 80.0,                -- Hearing range
    FleeHealth = 0                      -- Health % when enemies flee (0 = never)
}

--[[
    MISSIONS CONFIGURATION
    Each mission is a complete package with objectives, enemies, and rewards
]]
Config.Missions = {
    --[[
        MISSION 1: The Mangy Lion
        Type: Hunt - Track and kill a dangerous animal
    ]]
    {
        id = 'mangy_lion',
        name = 'mission_lion_name',             -- Locale key
        description = 'mission_lion_desc',      -- Locale key
        type = 'hunt',
        cooldown = 3600,                        -- 1 hour
        
        -- Contact NPC (secondary quest giver)
        contactNPC = {
            model = 'u_m_m_rkfrancher_01',      -- Wrangler (valid RedM model)
            location = vector4(-3577.49, -2224.69, -14.21, 137.0),
            scenario = 'WORLD_HUMAN_SMOKE',
            blip = {
                sprite = 587827268,         -- blip_ambient_newspaper (for contacts)
                label = 'blip_contact'
            }
        },
        
        -- Objectives
        objectives = {
            baitZone = {
                coords = vector3(-3362.14, -1916.11, -7.18),
                radius = 15.0,
                item = 'raw_meat',
                itemCount = 1
            },
            searchArea = {
                coords = vector3(-3377.54, -1899.19, -7.10),
                radius = 100.0
            }
        },
        
        -- Animal target
        animal = {
            model = 'a_c_lionmangy_01',
            spawnLocations = {
                vector3(-3461.57, -1851.97, -4.37)
            },
            blipLabel = 'blip_lion',
            escapeDistance = 300.0
        },
        
        -- Enemies (waves of hostiles)
        enemies = {
            type = 'Pinkertons',
            alertDelay = 5000,                  -- ms before enemies spawn
            waves = {
                {
                    delay = 0,
                    count = 6,
                    locations = {
                        vector3(-3384.20, -2049.52, -5.22),
                        vector3(-3381.20, -2049.52, -5.22),
                        vector3(-3387.20, -2049.52, -5.22),
                        vector3(-3384.20, -2046.52, -5.22),
                        vector3(-3384.20, -2052.52, -5.22),
                        vector3(-3381.20, -2046.52, -5.22)
                    }
                },
                {
                    delay = 45000,              -- 45 seconds after first wave
                    count = 4,
                    locations = {
                        vector3(-3395.94, -1879.63, -6.61),
                        vector3(-3392.94, -1879.63, -6.61),
                        vector3(-3398.94, -1879.63, -6.61),
                        vector3(-3395.94, -1876.63, -6.61)
                    }
                }
            }
        },
        
        -- Rewards
        rewards = {
            cash = { min = 400, max = 600 },
            xp = 150,
            items = {
                { item = 'raw_meat', amount = 2, chance = 0.6 },
                { item = 'diamond', amount = 1, chance = 0.2 }
            }
        },
        
        -- Dialogue keys (locales)
        dialogue = {
            intro = { 'lion_intro_1', 'lion_intro_2', 'lion_intro_3', 'lion_intro_4', 'lion_intro_5' },
            contact = { 'lion_contact_1', 'lion_contact_2', 'lion_contact_3', 'lion_contact_4', 'lion_contact_5' },
            complete = { 'lion_complete_1', 'lion_complete_2', 'lion_complete_3' }
        }
    },
    
    --[[
        MISSION 2: Wolf Den
        Type: Hunt - Clear wolves from mining area
    ]]
    {
        id = 'wolf_den',
        name = 'mission_wolf_name',
        description = 'mission_wolf_desc',
        type = 'hunt',
        cooldown = 3600,
        
        contactNPC = {
            model = 'u_m_m_rkfrancher_01',    -- Army townfolk (valid RedM model)
            location = vector4(2530.50, 1590.50, 84.90, 137.0),
            scenario = 'WORLD_HUMAN_LEAN_WALL',
            blip = {
                sprite = 587827268,         -- blip_ambient_newspaper (for contacts)
                label = 'blip_contact'
            }
        },
        
        objectives = {
            baitZone = {
                coords = vector3(2489.05, 1710.20, 87.00),
                radius = 15.0,
                item = 'raw_meat',
                itemCount = 1
            },
            searchArea = {
                coords = vector3(2456.37, 1731.27, 85.65),
                radius = 50.0
            }
        },
        
        animal = {
            model = 'a_c_wolf_01',
            spawnLocations = {
                vector3(2456.37, 1731.27, 85.65),
                vector3(2460.00, 1735.00, 85.65),
                vector3(2452.00, 1728.00, 85.65)
            },
            blipLabel = 'blip_wolf',
            escapeDistance = 250.0,
            packSize = 3                        -- Spawn multiple wolves
        },
        
        enemies = {
            type = 'Natives',
            alertDelay = 5000,
            waves = {
                {
                    delay = 0,
                    count = 5,
                    locations = {
                        vector3(2521.08, 1787.91, 86.55),
                        vector3(2524.08, 1787.91, 86.55),
                        vector3(2518.08, 1787.91, 86.55),
                        vector3(2521.08, 1790.91, 86.55),
                        vector3(2521.08, 1784.91, 86.55)
                    }
                },
                {
                    delay = 60000,
                    count = 5,
                    locations = {
                        vector3(2524.08, 1790.91, 86.55),
                        vector3(2518.08, 1784.91, 86.55),
                        vector3(2524.08, 1784.91, 86.55),
                        vector3(2518.08, 1790.91, 86.55),
                        vector3(2527.08, 1787.91, 86.55)
                    }
                }
            }
        },
        
        rewards = {
            cash = { min = 350, max = 500 },
            xp = 120,
            items = {
                { item = 'raw_meat', amount = 3, chance = 0.7 },
                { item = 'wolf_pelt', amount = 1, chance = 0.4 }
            }
        },
        
        dialogue = {
            intro = { 'wolf_intro_1', 'wolf_intro_2', 'wolf_intro_3', 'wolf_intro_4', 'wolf_intro_5' },
            contact = { 'wolf_contact_1', 'wolf_contact_2', 'wolf_contact_3', 'wolf_contact_4', 'wolf_contact_5' },
            complete = { 'wolf_complete_1', 'wolf_complete_2', 'wolf_complete_3' }
        }
    },
    
    --[[
        MISSION 3: Camp Raid
        Type: Combat - Clear an outlaw camp
    ]]
    {
        id = 'camp_raid',
        name = 'mission_camp_name',
        description = 'mission_camp_desc',
        type = 'combat',
        cooldown = 2700,                        -- 45 minutes
        
        contactNPC = {
            model = 'u_m_m_rkfrancher_01',
            location = vector4(-750.73, -1266.74, 43.27, 90.0),
            scenario = 'WORLD_HUMAN_GUARD_LEAN_WALL',
            blip = {
                sprite = 587827268,         -- blip_ambient_newspaper (for contacts)
                label = 'blip_marshal'
            }
        },
        
        objectives = {
            targetZone = {
                coords = vector3(-1175.86, -571.59, 91.17),
                radius = 30.0
            }
        },
        
        enemies = {
            type = 'Bandits',
            alertDelay = 0,
            waves = {
                {
                    delay = 0,
                    count = 8,
                    locations = {
                        vector3(-1175.86, -571.59, 91.17),
                        vector3(-1172.86, -574.59, 91.17),
                        vector3(-1178.86, -568.59, 91.17),
                        vector3(-1170.86, -571.59, 91.17),
                        vector3(-1180.86, -571.59, 91.17),
                        vector3(-1175.86, -565.59, 91.17),
                        vector3(-1175.86, -577.59, 91.17),
                        vector3(-1168.86, -568.59, 91.17)
                    }
                },
                {
                    delay = 30000,
                    count = 4,
                    locations = {
                        vector3(-1182.86, -565.59, 91.17),
                        vector3(-1168.86, -577.59, 91.17),
                        vector3(-1182.86, -577.59, 91.17),
                        vector3(-1168.86, -565.59, 91.17)
                    }
                }
            }
        },
        
        rewards = {
            cash = { min = 500, max = 750 },
            xp = 200,
            items = {
                { item = 'gold_nugget', amount = 1, chance = 0.3 },
                { item = 'lockpick', amount = 2, chance = 0.5 }
            }
        },
        
        dialogue = {
            intro = { 'camp_intro_1', 'camp_intro_2', 'camp_intro_3', 'camp_intro_4' },
            contact = { 'camp_contact_1', 'camp_contact_2', 'camp_contact_3', 'camp_contact_4', 'camp_contact_5' },
            complete = { 'camp_complete_1', 'camp_complete_2', 'camp_complete_3' }
        }
    },
    
    --[[
        MISSION 4: Rescue Mission
        Type: Rescue - Save a kidnapped NPC
    ]]
    {
        id = 'rescue_settler',
        name = 'mission_rescue_name',
        description = 'mission_rescue_desc',
        type = 'rescue',
        cooldown = 3600,
        
        contactNPC = {
            model = 'a_f_m_rancher_01',
            location = vector4(-1799.34, -386.41, 161.15, 90.0),
            scenario = 'WORLD_HUMAN_STAND_WAITING',
            blip = {
                sprite = 587827268,         -- blip_ambient_newspaper (for contacts)
                label = 'blip_worried_wife'
            }
        },
        
        -- Hostage configuration
        hostage = {
            model = 'a_m_m_rancher_01',
            location = vector3(-2100.0, -500.0, 150.0),
            tied = true                         -- Hostage is tied up
        },
        
        objectives = {
            rescueZone = {
                coords = vector3(-2100.0, -500.0, 150.0),
                radius = 50.0
            },
            returnZone = {
                coords = vector3(-1799.34, -386.41, 161.15),
                radius = 10.0
            }
        },
        
        enemies = {
            type = 'Bandits',
            alertDelay = 0,
            waves = {
                {
                    delay = 0,
                    count = 6,
                    locations = {
                        vector3(-2095.0, -505.0, 150.0),
                        vector3(-2105.0, -495.0, 150.0),
                        vector3(-2090.0, -500.0, 150.0),
                        vector3(-2110.0, -500.0, 150.0),
                        vector3(-2100.0, -490.0, 150.0),
                        vector3(-2100.0, -510.0, 150.0)
                    }
                }
            }
        },
        
        rewards = {
            cash = { min = 450, max = 650 },
            xp = 175,
            items = {
                { item = 'gold_ring', amount = 1, chance = 0.4 },
                { item = 'medicine', amount = 2, chance = 0.6 }
            }
        },
        
        dialogue = {
            intro = { 'rescue_intro_1', 'rescue_intro_2', 'rescue_intro_3', 'rescue_intro_4' },
            contact = { 'rescue_contact_1', 'rescue_contact_2', 'rescue_contact_3' },
            complete = { 'rescue_complete_1', 'rescue_complete_2', 'rescue_complete_3' }
        }
    }
}

--[[
    NOTIFICATION SETTINGS
]]
Config.Notifications = {
    Duration = {
        Short = 3000,
        Medium = 5000,
        Long = 8000
    },
    Placement = 'middle-right'
}

--[[
    BLIP SETTINGS
]]
Config.Blips = {
    MissionArea = {
        Sprite = -1282792512,               -- Area blip
        Color = 'BLIP_MODIFIER_MP_COLOR_32'
    },
    Enemy = {
        Sprite = 0x318C617C,                -- Hostile blip
        Color = 'BLIP_MODIFIER_MP_COLOR_32',
        Scale = 0.8
    },
    Objective = {
        Sprite = 587827268,                 -- blip_ambient_newspaper
        Color = 'BLIP_MODIFIER_MP_COLOR_1',
        Scale = 0.8
    },
    Animal = {
        Sprite = 423351566,                 -- blip_ambient_herd (for animals)
        Color = 'BLIP_MODIFIER_MP_COLOR_32',
        Scale = 0.8
    },
    BaitZone = {
        Sprite = 456887900,                 -- blip_destroy (for bait placement)
        Color = 'BLIP_MODIFIER_MP_COLOR_1',
        Scale = 0.8
    }
}

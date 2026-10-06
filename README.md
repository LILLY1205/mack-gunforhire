# mack-gunforhire

**Gun For Hire - Multi-Mission System for RSG-Core (RedM)**

A modular mission system featuring multiple mission types including animal hunts, camp raids, escort missions, and rescue operations. Built with ox_target, ox_lib menus, and bln_notifications.

## Features

- 🎯 **5 Mission Types**: Hunt, Combat, Escort, Rescue, and more
- 🎮 **ox_target Integration**: No 3D text - clean interactions
- 🔔 **bln_notifications**: Beautiful notification system
- 🌍 **Full Locale Support**: Easy translation to any language
- ⚙️ **Highly Configurable**: All settings in config.lua
- 🐛 **Debug Mode**: Easy debugging with toggle
- 🔒 **Server-side Validation**: Secure payouts and cooldowns
- 📊 **Logging**: Integration with rsg-log

## Dependencies

- [rsg-core](https://github.com/Rexshack-RedM/rsg-core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- [bln_notify](https://github.com/Blu-Starter/bln_notify)

## Installation

1. Download and extract to your resources folder
2. Rename folder to `mack-gunforhire`
3. Add to your `server.cfg`:
```cfg
ensure mack-gunforhire
```
4. Configure `config.lua` to your preferences
5. Restart your server

## Configuration

### Global Settings
```lua
Config.Debug = false                    -- Enable debug prints
Config.Locale = 'en'                    -- Language setting
Config.TargetDistance = 2.5             -- ox_target interaction distance
Config.DefaultCooldown = 3600           -- Default cooldown (1 hour)
```

### Job Restrictions
```lua
Config.RequireJob = false               -- Enable job check
Config.AllowedJobs = {
    'bountyhunter',
    'marshal',
    'vallaw',
    -- Add more jobs
}
```

### Quest Giver NPC
```lua
Config.QuestGiver = {
    Model = 'mp_u_m_m_yourboy01',
    Location = vector4(-269.33, 776.57, 118.44, 319.69),
    Scenario = 'WORLD_HUMAN_LEAN_BACK_WALL',
    Invincible = true,
    Frozen = true,
    Blip = {
        Enabled = true,
        Sprite = -1406874050,
        Color = 'BLIP_MODIFIER_MP_COLOR_32',
        Scale = 0.8,
        Label = 'blip_quest_giver'
    }
}
```

### Adding New Missions
Each mission in `Config.Missions` follows this structure:
```lua
{
    id = 'unique_mission_id',
    name = 'locale_key_name',
    description = 'locale_key_desc',
    type = 'hunt', -- hunt, combat, escort, rescue
    cooldown = 3600,
    
    contactNPC = {
        model = 'npc_model',
        location = vector4(x, y, z, heading),
        scenario = 'WORLD_HUMAN_SMOKE',
        blip = {
            sprite = -1406874050,
            label = 'blip_contact'
        }
    },
    
    objectives = {
        -- Mission-specific objectives
    },
    
    enemies = {
        type = 'Bandits', -- Bandits, Natives, Pinkertons
        alertDelay = 5000,
        waves = {
            {
                delay = 0,
                count = 6,
                locations = { vector3(...), ... }
            }
        }
    },
    
    rewards = {
        cash = { min = 400, max = 600 },
        xp = 150,
        items = {
            { item = 'raw_meat', amount = 2, chance = 0.6 }
        }
    },
    
    dialogue = {
        intro = { 'locale_key_1', 'locale_key_2', ... },
        contact = { ... },
        complete = { ... }
    }
}
```

## Mission Types

### Hunt Mission
Players track and kill dangerous animals using bait.
- Requires `raw_meat` item for bait
- Enemy waves spawn to protect the animal
- Animal must be killed before it escapes

### Combat Mission
Players clear an enemy camp.
- Multiple enemy waves
- All enemies must be eliminated
- Automatic completion tracking

### Escort Mission
Players protect a wagon convoy.
- Wagon follows path to destination
- Ambush points trigger enemy spawns
- Wagon must survive

### Rescue Mission
Players save a kidnapped NPC.
- Hostage must be freed
- Escort hostage back to safety
- Hostage must survive

---

## Player Mission Walkthroughs

Below are step-by-step guides for each mission available in the script.

### Mission 1: The Mangy Lion (Hunt)
**Objective**: Hunt down a dangerous lion terrorizing the area.

**Step-by-Step**:
1. **Find the Quest Giver**: Head to Valentine (default location at `-269.33, 776.57, 118.44`). Look for the NPC marked with a blip on your map.
2. **Accept the Mission**: Use `ox_target` to interact with the Quest Giver. Select "The Mangy Lion" from the mission menu.
3. **Travel to Contact**: A waypoint is set to Big Valley (Hanging Dog Ranch area at `-1522.08, 1096.15, 102.74`). Go there and find the Contact NPC (a worried rancher).
4. **Talk to Contact**: Interact with the Contact. He explains a lion has been attacking livestock and asks you to eliminate it.
5. **Place Bait**: You need `raw_meat` in your inventory. Travel to the bait location (marked on map at `-1580.45, 1150.33, 111.89`). Interact with the prompt to place the bait.
6. **Wait for Lion**: The lion spawns nearby. Track it using the blip that appears.
7. **Kill the Lion**: Shoot and kill the lion. Be careful - it's aggressive!
8. **Fight Enemies**: After killing the lion, Pinkerton agents arrive (6 enemies). Eliminate them all.
9. **Return to Contact**: Go back to the Contact NPC to report success.
10. **Collect Reward**: Receive $400-$600 cash, 150 XP, and possible item drops.

---

### Mission 2: Wolf Den (Hunt)
**Objective**: Clear a pack of wolves threatening a mining operation.

**Step-by-Step**:
1. **Find the Quest Giver**: Same location in Valentine.
2. **Accept the Mission**: Select "Wolf Den" from the mission menu.
3. **Travel to Contact**: Head to Roanoke Ridge (mining area at `2594.38, 1252.67, 76.25`). Find the miner Contact NPC.
4. **Talk to Contact**: The miner explains wolves have made a den near the mine and killed workers.
5. **Place Bait**: Requires `raw_meat`. Travel to bait location (`2650.12, 1180.45, 71.33`) near the wolf den.
6. **Wait for Alpha Wolf**: An alpha wolf spawns. It's marked with a blip.
7. **Kill the Alpha**: Eliminate the alpha wolf. This may attract other wolves - be ready.
8. **Fight Enemies**: Native attackers (5 enemies) appear, believing you're trespassing on sacred land.
9. **Return to Contact**: Report back to the miner.
10. **Collect Reward**: Receive $350-$500 cash, 125 XP, and possible pelts.

---

### Mission 3: Camp Raid (Combat)
**Objective**: Eliminate an outlaw camp that's been robbing travelers.

**Step-by-Step**:
1. **Find the Quest Giver**: Valentine Quest Giver location.
2. **Accept the Mission**: Select "Camp Raid" from the menu.
3. **Travel to Contact**: Head to Scarlett Meadows (near Rhodes at `1352.67, -1285.33, 75.88`). Find the Sheriff's Deputy.
4. **Talk to Contact**: The Deputy briefs you on an outlaw gang camped nearby. They've been ambushing stagecoaches.
5. **Approach the Camp**: Travel to the outlaw camp location (`1420.55, -1350.22, 81.44`). You'll see tents and campfires.
6. **Combat Phase**: 8 bandits spawn across the camp. Use cover and eliminate them all.
7. **Clear Remaining Enemies**: Make sure all enemies are dead. Check tents and behind rocks.
8. **Return to Contact**: Head back to the Deputy to confirm the camp is cleared.
9. **Collect Reward**: Receive $500-$750 cash, 200 XP, and possible weapon components.

---

### Mission 4: Wagon Escort (Escort)
**Objective**: Protect a supply wagon traveling through dangerous territory.

**Step-by-Step**:
1. **Find the Quest Giver**: Valentine Quest Giver.
2. **Accept the Mission**: Select "Wagon Escort" from the menu.
3. **Travel to Contact**: Head to Emerald Ranch area (`1662.45, 416.78, 89.12`). Find the wagon driver.
4. **Talk to Contact**: The driver needs protection - bandits have been hitting supply runs.
5. **Stay Near Wagon**: The wagon begins moving. Stay within range to protect it.
6. **First Ambush**: At the first checkpoint (`1580.33, 320.45, 85.67`), 4 bandits attack. Kill them quickly.
7. **Continue Escort**: The wagon resumes. Keep pace and watch for threats.
8. **Second Ambush**: At the second checkpoint (`1490.22, 250.88, 82.33`), 4 more bandits attack.
9. **Reach Destination**: Escort the wagon to the final destination (`1350.67, 180.55, 78.44`).
10. **Collect Reward**: Receive $450-$650 cash, 175 XP, and possible supplies.

**Tips**:
- Stay on horseback for quick response to ambushes
- Don't ride too far ahead - the wagon moves slowly
- If the wagon takes too much damage, the mission fails

---

### Mission 5: Rescue the Settler (Rescue)
**Objective**: Save a kidnapped settler from a bandit hideout.

**Step-by-Step**:
1. **Find the Quest Giver**: Valentine Quest Giver.
2. **Accept the Mission**: Select "Rescue the Settler" from the menu.
3. **Travel to Contact**: Head to Manzanita Post (Tall Trees at `-1955.33, -1585.67, 114.22`). Find the settler's spouse.
4. **Talk to Contact**: They explain their partner was kidnapped and taken to a nearby cabin.
5. **Approach Hideout**: Travel to the bandit hideout (`-2050.88, -1650.44, 108.55`). Move carefully.
6. **Eliminate Guards**: 6 bandits guard the area. You can go loud or try to pick them off.
7. **Find Hostage**: The hostage is inside the cabin/tied up. Look for the marker.
8. **Free Hostage**: Interact with the hostage to cut them free.
9. **Escort to Safety**: The hostage follows you. Lead them back to the Contact location.
10. **Collect Reward**: Receive $550-$800 cash, 200 XP, and reputation bonus.

**Tips**:
- The hostage can be hurt - don't use explosives near them
- If the hostage dies, the mission fails
- The hostage runs slowly - stay close to protect them

---

## Multiplayer/Sync Notes

- **Notifications**: Only the player who accepted the mission receives notifications.
- **NPC Visibility**: All players nearby can see mission NPCs and enemies (they sync across clients).
- **Entity Count**: The configured enemy count spawns once - additional players don't increase enemy numbers.
- **Mission Ownership**: Only the mission owner can complete objectives and receive rewards.

## Adding Locales

Create a new file in `locales/` (e.g., `es.lua`):
```lua
Locales['es'] = {
    blip_quest_giver = 'Pistola de Alquiler',
    menu_title = 'Pistola de Alquiler',
    -- Add all translations
}
```

Then set `Config.Locale = 'es'` in config.lua.

## Debug Commands

When `Config.Debug = true`:

| Command | Description |
|---------|-------------|
| `gfh_clearcooldown [playerId]` | Clear all cooldowns for a player |
| `gfh_testpayout` | Test the payout notification system |

## File Structure

```
mack-gunforhire/
├── client/
│   ├── main.lua         -- Core client logic
│   ├── missions.lua     -- Mission type handlers
│   └── utils.lua        -- Utility functions
├── server/
│   ├── main.lua         -- Server events, payouts
│   └── callbacks.lua    -- Server callbacks
├── locales/
│   ├── en.lua           -- English translations
│   └── init.lua         -- Locale loader
├── config.lua           -- Configuration
├── fxmanifest.lua       -- Resource manifest
└── README.md            -- This file
```

## Performance

- Optimized loops with appropriate `Wait()` intervals
- Entity cleanup on mission end and resource stop
- Client-side entity management
- Server-side validation for all payouts

## Support

For issues or feature requests, please open an issue on the repository.

## Credits

- **Author**: mack
- **Framework**: RSG-Core
- **Dependencies**: ox_lib, ox_target, bln_notify

## License

This resource is provided as-is for use with RSG-Core servers.

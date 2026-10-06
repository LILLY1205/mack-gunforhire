--[[
    English Translations for mack-gunforhire
    All menus, notifications, and dialogue text
]]

Locales['en'] = {
    --[[
        BLIP LABELS
    ]]
    blip_quest_giver = 'Gun For Hire',
    blip_contact = 'Mission Contact',
    blip_marshal = 'Marshal',
    blip_merchant = 'Merchant',
    blip_worried_wife = 'Worried Settler',
    blip_lion = 'Mangy Lion',
    blip_wolf = 'Wolf Pack',
    blip_search_area = 'Search Area',
    blip_objective = 'Objective',
    blip_enemy = 'Hostile',
    
    --[[
        MENU TITLES
    ]]
    menu_title = 'Gun For Hire',
    menu_subtitle = 'Available Missions',
    menu_select_mission = 'Select a Mission',
    menu_close = 'Close',
    menu_accept = 'Accepted Mission Completed',
    menu_decline = 'Decline',
    
    --[[
        MISSION NAMES
    ]]
    mission_lion_name = 'The Mangy Lion',
    mission_wolf_name = 'Wolf Den',
    mission_camp_name = 'Camp Raid',
    mission_escort_name = 'Wagon Escort',
    mission_rescue_name = 'Rescue the Settler',
    
    --[[
        MISSION DESCRIPTIONS
    ]]
    mission_lion_desc = 'Hunt a dangerous mangy lion terrorizing the territory.',
    mission_wolf_desc = 'Clear a wolf pack from a mining area.',
    mission_camp_desc = 'Raid an outlaw camp and eliminate the threat.',
    mission_escort_desc = 'Escort a supply wagon safely to its destination.',
    mission_rescue_desc = 'Rescue a kidnapped settler from bandits.',
    
    --[[
        NOTIFICATIONS - GENERAL
    ]]
    notify_mission_accepted = 'Mission Accepted',
    notify_mission_started = 'Mission Started',
    notify_mission_complete = 'Mission Complete!',
    notify_mission_failed = 'Mission Failed',
    notify_cooldown_active = 'Cooldown Active',
    notify_cooldown_wait = 'Wait %s before starting this mission again.',
    notify_job_required = 'Job Required',
    notify_job_not_allowed = 'You need a specific job to take this mission.',
    notify_no_item = 'Missing Item',
    notify_need_item = 'You need %s to complete this objective.',
    notify_item_used = 'Used %s',
    notify_go_to_contact = 'Go speak with the contact.',
    notify_go_to_objective = 'Head to the objective area.',
    notify_return_to_giver = 'Return to the quest giver.',
    notify_enemies_incoming = 'Hostiles Incoming!',
    notify_enemies_nearby = 'Enemies are nearby!',
    notify_all_enemies_dead = 'All enemies eliminated.',
    notify_target_escaped = 'The target escaped!',
    notify_target_killed = 'Target eliminated.',
    notify_wagon_destroyed = 'The wagon was destroyed!',
    notify_hostage_killed = 'The hostage was killed!',
    notify_player_died = 'You died! Mission failed.',
    
    --[[
        NOTIFICATIONS - REWARDS
    ]]
    notify_reward_title = 'Reward Received',
    notify_reward_cash = 'You received $%s',
    notify_reward_xp = 'You earned %s XP',
    notify_reward_item = 'You received %sx %s',
    
    --[[
        TARGET LABELS (ox_target)
    ]]
    target_talk_giver = 'Talk to Gun For Hire',
    target_talk_contact = 'Talk to Contact',
    target_place_bait = 'Place Bait',
    target_search_area = 'Search Area',
    target_rescue_hostage = 'Rescue Hostage',
    target_board_wagon = 'Board Wagon',
    
    --[[
        PROGRESS LABELS
    ]]
    progress_placing_bait = 'Placing bait...',
    progress_searching = 'Searching...',
    progress_untying = 'Untying hostage...',
    
    --[[
        DIALOGUE - LION MISSION
    ]]
    lion_intro_1 = 'Stranger! I need your help with a dangerous situation.',
    lion_intro_2 = 'A mangy lion escaped from a transport wagon nearby.',
    lion_intro_3 = 'It\'s been terrorizing the area, killing livestock and travelers.',
    lion_intro_4 = 'My contact at the camp knows where it was last seen.',
    lion_intro_5 = 'Bring raw meat as bait - you\'ll need it to draw the beast out.',
    
    lion_contact_1 = 'You came! Thank heavens.',
    lion_contact_2 = 'The lion killed most of my men when it escaped.',
    lion_contact_3 = 'It was heading north into the canyon last I saw it.',
    lion_contact_4 = 'Use the meat to lure it out of hiding.',
    lion_contact_5 = 'Be careful - the Pinkertons are after it too.',
    
    lion_complete_1 = 'You killed the beast? Outstanding!',
    lion_complete_2 = 'Here\'s your payment as promised.',
    lion_complete_3 = 'Come back anytime you need work, friend.',
    
    --[[
        DIALOGUE - WOLF MISSION
    ]]
    wolf_intro_1 = 'Got a job for someone with guts.',
    wolf_intro_2 = 'Wolves have taken over a mining camp nearby.',
    wolf_intro_3 = 'The locals think they\'re sacred and won\'t let anyone near.',
    wolf_intro_4 = 'You\'ll need to deal with the wolves AND the angry natives.',
    wolf_intro_5 = 'The miner foreman will fill you in on the details.',
    
    wolf_contact_1 = 'Finally, someone willing to help!',
    wolf_contact_2 = 'These wolves have killed half my crew.',
    wolf_contact_3 = 'The natives are protecting them like gods.',
    wolf_contact_4 = 'Use bait to draw them out of the cave.',
    wolf_contact_5 = 'Good luck - you\'re going to need it.',
    
    wolf_complete_1 = 'The wolves are dead? About time!',
    wolf_complete_2 = 'You\'ve earned every penny of this.',
    wolf_complete_3 = 'Mining can resume thanks to you.',
    
    --[[
        DIALOGUE - CAMP RAID MISSION
    ]]
    camp_intro_1 = 'Marshal needs help with a situation.',
    camp_intro_2 = 'Outlaw camp has been hitting our supply routes.',
    camp_intro_3 = 'We need that camp cleared out permanently.',
    camp_intro_4 = 'My deputy will brief you on the location.',
    
    camp_contact_1 = 'The boss sent you? Good.',
    camp_contact_2 = 'The camp is heavily guarded.',
    camp_contact_3 = 'At least a dozen outlaws holed up there.',
    camp_contact_4 = 'Expect reinforcements once you start shooting.',
    camp_contact_5 = 'Clear them all out and report back.',
    
    camp_complete_1 = 'All cleared out? Excellent work.',
    camp_complete_2 = 'The territory is safer thanks to you.',
    camp_complete_3 = 'Here\'s your reward.',
    
    --[[
        DIALOGUE - ESCORT MISSION
    ]]
    escort_intro_1 = 'I need an armed escort for a supply run.',
    escort_intro_2 = 'Bandits have been hitting wagons on the trail.',
    escort_intro_3 = 'Protect the wagon until it reaches its destination.',
    escort_intro_4 = 'The merchant is waiting at the depot.',
    
    escort_contact_1 = 'You\'re my escort? Let\'s get moving.',
    escort_contact_2 = 'Stay close to the wagon at all times.',
    escort_contact_3 = 'If we get ambushed, protect the cargo.',
    
    escort_complete_1 = 'We made it! Thank you, stranger.',
    escort_complete_2 = 'Couldn\'t have done it without you.',
    escort_complete_3 = 'Here\'s your payment.',
    
    --[[
        DIALOGUE - RESCUE MISSION
    ]]
    rescue_intro_1 = 'Please, you have to help me!',
    rescue_intro_2 = 'My husband was taken by bandits.',
    rescue_intro_3 = 'They\'re holding him at their camp.',
    rescue_intro_4 = 'I\'ll give you everything I have if you save him.',
    
    rescue_contact_1 = 'The camp is just ahead.',
    rescue_contact_2 = 'Be careful - they\'ll kill him if spooked.',
    rescue_contact_3 = 'Get him out alive.',
    
    rescue_complete_1 = 'You brought him back! Thank you!',
    rescue_complete_2 = 'I don\'t know how to repay you.',
    rescue_complete_3 = 'Take this - it\'s all we have.',
    
    --[[
        MISC
    ]]
    minutes = 'minutes',
    seconds = 'seconds',
    mission_in_progress = 'Mission in progress',
    coming_soon = 'More missions coming soon...',
}

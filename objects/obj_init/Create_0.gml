/// obj_init :: Create Event
/// @description Initializes global game variables and systems ONCE at game start.

if (variable_global_exists("init_has_run_deep_check") && global.init_has_run_deep_check == true) {
    show_debug_message("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    show_debug_message("!!! CRITICAL ERROR: OBJ_INIT CREATE EVENT RUNNING AGAIN !!!");
    show_debug_message("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    // This should NOT happen if obj_init is persistent and created only once.
} else {
    show_debug_message("!!! obj_init Create Event Running for the FIRST TIME (or init_has_run_deep_check was cleared) !!!");
    global.init_has_run_deep_check = true;
}

show_debug_message("!!! obj_init Create Event Running !!!");
show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION STARTING");
show_debug_message("========================================");

// --- Dialog Colors ---
show_debug_message("Initializing Dialog System...");
global.char_colors = {
    "System": c_silver,
    "Moth":   c_aqua,
    "Boy":    c_purple,
    "Gub": c_orange
    // …add others…
};
show_debug_message("    -> global.char_colors initialized.");

// --- Input System ---
show_debug_message("Initializing Input System...");
if (script_exists(scr_init_input_mappings)) { // Check if the function/script containing it exists
    scr_init_input_mappings(); // This function will populate global.input_mappings
    show_debug_message("    -> Input mappings initialized via scr_init_input_mappings.");
} else {
    show_debug_message("    -> WARNING: scr_init_input_mappings function not found! Input system will not be initialized.");
    // As a fallback, ensure the core global array exists to prevent errors if other code tries to access it
    if (!variable_global_exists("input_mappings") || !is_array(global.input_mappings)) {
        global.input_mappings = array_create(INPUT_ACTION._count); // Requires INPUT_ACTION enum to be known
        show_debug_message("    -> Created empty global.input_mappings array as a fallback.");
    }
    if (!variable_global_exists("gamepad_player_map")) {
         global.gamepad_player_map = [0, 1, 2, 3];
    }
    // Deadzones would also need default values here if not set elsewhere
}


// --- Encounter Table ---
show_debug_message("Initializing Encounter System...");
if (script_exists(scr_InitEncounterTable)) {
    if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
        ds_map_destroy(global.encounter_table);
        show_debug_message("    -> Destroyed existing encounter_table before re-init.");
    }
    scr_InitEncounterTable(); 
    show_debug_message("    -> encounter_table initialized via scr_InitEncounterTable.");
} else {
    show_debug_message("    -> WARNING: scr_InitEncounterTable not found. Creating empty ds_map for encounter_table.");
    if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
        ds_map_destroy(global.encounter_table);
    }
    global.encounter_table = ds_map_create();
}

// --- Item Database ---
show_debug_message("Initializing Item Database...");
if (script_exists(scr_ItemDatabase)) {
    if (variable_global_exists("item_database") && ds_exists(global.item_database, ds_type_map)) {
        ds_map_destroy(global.item_database);
        show_debug_message("    -> Destroyed existing item_database before re-init.");
    }
    global.item_database = scr_ItemDatabase(); 
    show_debug_message("    -> item_database created via scr_ItemDatabase.");
} else {
    show_debug_message("    -> WARNING: scr_ItemDatabase not found. Creating empty ds_map for item_database.");
    if (variable_global_exists("item_database") && ds_exists(global.item_database, ds_type_map)) {
        ds_map_destroy(global.item_database);
    }
    global.item_database = ds_map_create();
}

// --- Character Database ---
show_debug_message("Initializing Character Database...");
if (script_exists(scr_BuildCharacterDB)) {
    if (variable_global_exists("character_data") && ds_exists(global.character_data, ds_type_map)) {
        ds_map_destroy(global.character_data);
        show_debug_message("    -> Destroyed existing character_data before re-init.");
    }
    global.character_data = scr_BuildCharacterDB(); 
    show_debug_message("    -> character_data created via scr_BuildCharacterDB.");
} else {
    show_debug_message("    -> WARNING: scr_BuildCharacterDB not found. Creating empty ds_map for character_data.");
    if (variable_global_exists("character_data") && ds_exists(global.character_data, ds_type_map)) {
        ds_map_destroy(global.character_data);
    }
    global.character_data = ds_map_create();
}

// --- Spell Database ---
show_debug_message("Initializing Spell Database...");
if (script_exists(scr_BuildSpellDB)) {
    global.spell_db = scr_BuildSpellDB();
    show_debug_message("    -> spell_db initialized via scr_BuildSpellDB.");
} else {
    show_debug_message("    -> WARNING: scr_BuildSpellDB not found. Initializing spell_db as empty struct.");
    global.spell_db = {}; 
}

// --- Party Members List ---
show_debug_message("Initializing Party Members List...");
if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
    global.party_members = [];  
    show_debug_message("  -> global.party_members array created (empty). Add starting members if needed.");
} else {
     show_debug_message("  -> global.party_members already exists.");
}


// --- SHARED PARTY INVENTORY ---
show_debug_message("Initializing Shared Party Inventory...");
if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) {
    global.party_inventory = [
        { item_key: "potion", quantity: 5 },
        { item_key: "bomb", quantity: 3 }
    ];
    show_debug_message("  -> global.party_inventory created with starting items.");
} else {
    show_debug_message("  -> global.party_inventory already exists.");
}
if (!variable_global_exists("party_currency")) {
    global.party_currency = 100;
    show_debug_message("  -> global.party_currency initialized to 100.");
} else {
    show_debug_message("  -> global.party_currency already exists.");
}

// --- PERSISTENT WORLD STATES (Pickups, Gates, Room Connections, etc.) ---
show_debug_message("Initializing Persistent World States...");

// For Item Pickups (one flag per unique persistent item)
if (!variable_global_exists("has_collected_main_echo_gem")) {
    global.has_collected_main_echo_gem = false;
    show_debug_message("  -> Initialized global.has_collected_main_echo_gem = false");
} else {
    show_debug_message("  -> global.has_collected_main_echo_gem already exists.");
}
// ... (other item pickups) ...

// --- CORRECTED: For Room Connection Map (used by player transitions) ---
show_debug_message("Initializing Room Connection Map (global.room_map)...");
if (!variable_global_exists("room_map")) {
    global.room_map = ds_map_create();
    show_debug_message("  -> Initialized global.room_map (ds_map created).");
    if (script_exists(scr_InitRoomMap)) {
        scr_InitRoomMap(); 
        show_debug_message("  -> Called scr_InitRoomMap to populate global.room_map.");
    } else {
        show_debug_message("  -> WARNING: scr_InitRoomMap script not found! global.room_map will be empty.");
    }
} else {
    if (!ds_exists(global.room_map, ds_type_map)) {
        show_debug_message("  -> CRITICAL WARNING: global.room_map existed but was NOT a ds_map! Re-creating and populating.");
        global.room_map = ds_map_create();
        if (script_exists(scr_InitRoomMap)) {
            scr_InitRoomMap();
            show_debug_message("  -> Called scr_InitRoomMap to populate re-created global.room_map.");
        } else {
            show_debug_message("  -> WARNING: scr_InitRoomMap script not found for re-created global.room_map!");
        }
    } else {
        show_debug_message("  -> global.room_map already exists and is a ds_map.");
    }
}

// --- Gates/Switches System (global.gate_states_map) ---
if (!variable_global_exists("gate_states_map")) {
    global.gate_states_map = ds_map_create();
    show_debug_message("obj_init: SUCCESS - Created global.gate_states_map. ID: " + string(global.gate_states_map) + ", Type: " + string(ds_type_to_string(ds_exists(global.gate_states_map, ds_type_map) ? ds_type_map : -1)));
} else {
    if (!ds_exists(global.gate_states_map, ds_type_map)) {
        show_debug_message("obj_init: CRITICAL WARNING - global.gate_states_map existed but was NOT a ds_map! Recreating. Old value: " + string(global.gate_states_map));
        global.gate_states_map = ds_map_create();
        show_debug_message("obj_init: SUCCESS - Recreated global.gate_states_map. ID: " + string(global.gate_states_map));
    } else {
        show_debug_message("obj_init: global.gate_states_map already exists and is a ds_map. ID: " + string(global.gate_states_map));
    }
}

// --- Recruited NPCs Map (global.recruited_npcs_map) ---
if (!variable_global_exists("recruited_npcs_map")) {
    global.recruited_npcs_map = ds_map_create();
    show_debug_message("  -> Initialized global.recruited_npcs_map (ds_map created for recruited NPCs).");
} else {
     if (!ds_exists(global.recruited_npcs_map, ds_type_map)) {
        show_debug_message("  -> WARNING: global.recruited_npcs_map existed but was NOT a ds_map! Re-creating.");
        global.recruited_npcs_map = ds_map_create();
    } else {
        show_debug_message("  -> global.recruited_npcs_map already exists and is a ds_map.");
    }
}

// --- ADDED: Broken Blocks Map (global.broken_blocks_map) ---
show_debug_message("Initializing Broken Blocks Map (global.broken_blocks_map)...");
if (!variable_global_exists("broken_blocks_map")) {
    global.broken_blocks_map = ds_map_create();
    show_debug_message("  -> Initialized global.broken_blocks_map (ds_map created).");
} else {
    if (!ds_exists(global.broken_blocks_map, ds_type_map)) {
        show_debug_message("  -> CRITICAL WARNING: global.broken_blocks_map existed but was NOT a ds_map! Re-creating.");
        global.broken_blocks_map = ds_map_create();
    } else {
        show_debug_message("  -> global.broken_blocks_map already exists and is a ds_map.");
    }
}

// --- ADDED: Loot Drops Map (global.loot_drops_map) ---
show_debug_message("Initializing Loot Drops Map (global.loot_drops_map)...");
if (!variable_global_exists("loot_drops_map")) {
    global.loot_drops_map = ds_map_create();
    show_debug_message("  -> Initialized global.loot_drops_map (ds_map created).");
} else {
    if (!ds_exists(global.loot_drops_map, ds_type_map)) {
        show_debug_message("  -> CRITICAL WARNING: global.loot_drops_map existed but was NOT a ds_map! Re-creating.");
        global.loot_drops_map = ds_map_create();
    } else {
        show_debug_message("  -> global.loot_drops_map already exists and is a ds_map.");
    }
}
// --- END PERSISTENT WORLD STATES ---

// --- Party Stats Map (global.party_current_stats) ---
show_debug_message("Initializing Party Stats Map (global.party_current_stats)...");
if (!variable_global_exists("party_current_stats")) {
    global.party_current_stats = ds_map_create();
    show_debug_message("  -> Initialized global.party_current_stats (ds_map created). Populated by obj_player on new game or by load game.");
} else {
    if (!ds_exists(global.party_current_stats, ds_type_map)) {
        show_debug_message("  -> CRITICAL WARNING: global.party_current_stats existed but was NOT a ds_map! Re-creating.");
        global.party_current_stats = ds_map_create();
    } else {
        show_debug_message("  -> global.party_current_stats already exists and is a ds_map.");
    }
}

// --- Miscellaneous ---
if (!variable_global_exists("entry_direction")) { 
    global.entry_direction = "none";
    show_debug_message("Initializing global.entry_direction = \"none\"");
}
randomise(); 

if (!variable_global_exists("display_mode")) {
    global.display_mode = "Windowed"; 
    show_debug_message("Initializing global.display_mode = \"Windowed\"");
}
if (!variable_global_exists("sfx_volume")) {
    global.sfx_volume = 1;   
    show_debug_message("Initializing global.sfx_volume = 1");
}
if (!variable_global_exists("music_volume")) {
    global.music_volume = 1;  
    show_debug_message("Initializing global.music_volume = 1");
}

show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION COMPLETE");
show_debug_message("========================================");

// The following block appears to be a more concise or possibly override block.
// Be mindful if this is intended to overwrite some of the checked initializations above.
// For clarity, I'm keeping it as is from your provided code.
global.quest_stage = 0;
global.party_members        = [];          // force it into existence (overwrites previous conditional init)
global.party_inventory      = [];          // force it into existence (overwrites previous conditional init)
global.party_current_stats = ds_map_create(); // force new map (overwrites previous conditional init/check)
global.load_pending         = false;
global.loaded_data          = undefined;
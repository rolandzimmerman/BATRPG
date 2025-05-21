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
    "Boy":   c_purple,
    "Gub": c_orange
    // …add others…
};
show_debug_message("    -> global.char_colors initialized.");

// --- Encounter Table ---
show_debug_message("Initializing Encounter System...");
if (script_exists(scr_InitEncounterTable)) {
    // It's good practice to destroy if it exists but might be from a previous failed run or bad state
    if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
        ds_map_destroy(global.encounter_table);
        show_debug_message("    -> Destroyed existing encounter_table before re-init.");
    }
    scr_InitEncounterTable(); // This script should set global.encounter_table
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
    global.item_database = scr_ItemDatabase(); // Script returns the created map
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
    global.character_data = scr_BuildCharacterDB(); // Script returns the created map
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
    // Assuming spell_db might be re-built, so no need to destroy a ds_map here unless scr_BuildSpellDB adds to an existing one.
    // If scr_BuildSpellDB returns a *new* struct/map each time, this is fine.
    global.spell_db = scr_BuildSpellDB();
    show_debug_message("    -> spell_db initialized via scr_BuildSpellDB.");
} else {
    show_debug_message("    -> WARNING: scr_BuildSpellDB not found. Initializing spell_db as empty struct.");
    global.spell_db = {}; // Initialize as an empty struct if script is missing
}

// --- Party Members List ---
show_debug_message("Initializing Party Members List...");
if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
    global.party_members = [];  // e.g. ["hero", "claude", …]
    show_debug_message("  -> global.party_members array created (empty). Add starting members if needed.");
    // Example: array_push(global.party_members, "hero");
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

if (!variable_global_exists("has_collected_main_flurry_flower")) {
    global.has_collected_main_flurry_flower = false;
    show_debug_message("  -> Initialized global.has_collected_main_flurry_flower = false");
} else {
    show_debug_message("  -> global.has_collected_main_flurry_flower already exists.");
}

if (!variable_global_exists("has_collected_main_meteor_shard")) {
    global.has_collected_main_meteor_shard = false;
    show_debug_message("  -> Initialized global.has_collected_main_meteor_shard = false");
} else {
    show_debug_message("  -> global.has_collected_main_meteor_shard already exists.");
}

// --- CORRECTED: For Room Connection Map (used by player transitions) ---
show_debug_message("Initializing Room Connection Map (global.room_map)...");
if (!variable_global_exists("room_map")) {
    global.room_map = ds_map_create();
    show_debug_message("  -> Initialized global.room_map (ds_map created).");
    // Populate it immediately after creation
    if (script_exists(scr_InitRoomMap)) {
        scr_InitRoomMap(); // This script will fill global.room_map
        show_debug_message("  -> Called scr_InitRoomMap to populate global.room_map.");
    } else {
        show_debug_message("  -> WARNING: scr_InitRoomMap script not found! global.room_map will be empty.");
    }
} else {
    // If it exists, ensure it's actually a ds_map. If not, this is a critical issue.
    if (!ds_exists(global.room_map, ds_type_map)) {
        show_debug_message("  -> CRITICAL WARNING: global.room_map existed but was NOT a ds_map! Re-creating and populating.");
        // Potentially destroy if it was another DS type with the same ID, though ds_map_create will get a new ID.
        // if (is_real(global.room_map) && global.room_map >= 0) { ds_destroy(global.room_map); } // Careful with generic ds_destroy
        global.room_map = ds_map_create();
        if (script_exists(scr_InitRoomMap)) {
            scr_InitRoomMap();
            show_debug_message("  -> Called scr_InitRoomMap to populate re-created global.room_map.");
        } else {
            show_debug_message("  -> WARNING: scr_InitRoomMap script not found for re-created global.room_map!");
        }
    } else {
        show_debug_message("  -> global.room_map already exists and is a ds_map. Assuming it was correctly populated (e.g., by a previous call to scr_InitRoomMap if obj_init logic allows re-entry, or if this is not the true first run).");
        // If obj_init is truly persistent and runs its Create ONCE, this 'else' for room_map
        // should ideally not be hit after the very first initialization.
        // If scr_InitRoomMap is safe to call multiple times (it is, as it clears itself), you could call it here too,
        // but it's better if this whole block runs only once.
    }
}

// --- Gates/Switches System (global.gate_states_map) ---
// Your existing initialization for global.gate_states_map is good:
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
// Your existing initialization for global.recruited_npcs_map is good:
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
    // If it exists, ensure it's actually a ds_map.
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
    // If it exists, ensure it's actually a ds_map.
    if (!ds_exists(global.loot_drops_map, ds_type_map)) {
        show_debug_message("  -> CRITICAL WARNING: global.loot_drops_map existed but was NOT a ds_map! Re-creating.");
        global.loot_drops_map = ds_map_create();
    } else {
        show_debug_message("  -> global.loot_drops_map already exists and is a ds_map.");
    }
}
// --- END PERSISTENT WORLD STATES ---


// It's also good practice to initialize global.party_current_stats here,
// as it's a DS map that your save system handles.
// obj_player can then rely on it existing and populate it for a new game if it's empty.

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
        // If it already exists and is a map, it might have been populated by a previous game run (if obj_init isn't truly first)
        // or by an earlier part of obj_init if you had split logic. Generally, it's fine.
        // For a truly fresh game start (where obj_init runs for the very first time), this 'else' for an existing map would be less common
        // unless you have complex game launch sequences.
    }
}


// --- Miscellaneous ---
if (!variable_global_exists("entry_direction")) { // Check if it exists before setting
    global.entry_direction = "none";
    show_debug_message("Initializing global.entry_direction = \"none\"");
}
randomise(); // Call once at game start for true randomness

if (!variable_global_exists("display_mode")) {
    global.display_mode = "Windowed"; // or "Fullscreen", "Borderless"
    show_debug_message("Initializing global.display_mode = \"Windowed\"");
}
if (!variable_global_exists("sfx_volume")) {
    global.sfx_volume = 1;    // 0.0 to 1.0
    show_debug_message("Initializing global.sfx_volume = 1");
}
if (!variable_global_exists("music_volume")) {
    global.music_volume = 1;  // 0.0 to 1.0
    show_debug_message("Initializing global.music_volume = 1");
}


show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION COMPLETE");
show_debug_message("========================================");

// Ensure this obj_init is in your very first room and is ideally persistent itself,
// or that it runs before any other game logic that might depend on these globals.
// If obj_init is not persistent, ensure it's in a room that is only visited once at launch.
// If it can be run multiple times, the `if (!variable_global_exists(...))` checks are crucial.

/// obj_init :: Create Event
global.quest_stage = 0
global.party_members       = [];          // force it into existence
global.party_inventory     = [];
global.party_current_stats = ds_map_create();
global.load_pending        = false;
global.loaded_data         = undefined;
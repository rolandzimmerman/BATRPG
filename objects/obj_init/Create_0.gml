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

// --- PERSISTENT WORLD STATES (Pickups, Gates, etc.) --- <<< NEW SECTION
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

// For Gates/Switches System (using group_id as keys)
if (!variable_global_exists("gate_states_map")) {
    global.gate_states_map = ds_map_create();
    show_debug_message("  -> Initialized global.gate_states_map (ds_map created).");
} else {
    // If it exists, ensure it's actually a ds_map. If not, something is wrong.
    if (!ds_exists(global.gate_states_map, ds_type_map)) {
        show_debug_message("  -> WARNING: global.gate_states_map existed but was NOT a ds_map! Re-creating it.");
        // Attempt to destroy if it was a valid ID of another DS type to prevent memory leaks
        // This is defensive. If this happens, there's a deeper issue with how global.gate_states_map is handled elsewhere.
        if (is_real(global.gate_states_map) && global.gate_states_map >= 0) { // Check if it looks like a DS ID
             // ds_destroy(global.gate_states_map); // Be very careful with a generic ds_destroy
        }
        global.gate_states_map = ds_map_create();
    } else {
        show_debug_message("  -> global.gate_states_map already exists and is a ds_map.");
    }
}
// --- END PERSISTENT WORLD STATES ---

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
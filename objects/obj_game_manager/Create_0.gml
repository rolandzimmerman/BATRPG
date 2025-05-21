// obj_game_manager :: Create Event

show_debug_message("[GameManager_Create] Initializing...");

// game_state initialization
if (!variable_instance_exists(id, "game_state")) {
    game_state = "playing";
}

// Initialize primary loading system flags
if (!variable_global_exists("isLoadingGame")) {
    global.isLoadingGame = false;
}
if (!variable_global_exists("pending_load_data")) {
    global.pending_load_data = undefined;
}
if (!variable_global_exists("player_state_loaded_this_frame")) {
    global.player_state_loaded_this_frame = false;
}

// Ensure this object is persistent (Check the Object Editor box!)
// persistent = true; // Should be set in Object Editor

// --- Initialize Global DS Maps for Persistent States ---
show_debug_message("[GameManager_Create] Initializing global DS Maps for game state...");

var _init_global_ds_map = function(map_name_string) {
    var map_exists_as_valid_ds = false;
    if (variable_global_exists(map_name_string)) {
        var current_val = variable_global_get(map_name_string);
        if (is_real(current_val) && ds_exists(current_val, ds_type_map)) {
            map_exists_as_valid_ds = true;
        }
    }

    if (!map_exists_as_valid_ds) {
        if (variable_global_exists(map_name_string)) {
            var current_val = variable_global_get(map_name_string);
            if (is_real(current_val) && ds_exists(current_val, ds_type_map)) {
                 show_debug_message("[GameManager_Create] Destroying potentially stale DS Map: " + map_name_string);
                 ds_map_destroy(current_val);
            }
        }
        variable_global_set(map_name_string, ds_map_create());
        show_debug_message("[GameManager_Create] Initialized NEW global DS Map: " + map_name_string);
    } else {
        show_debug_message("[GameManager_Create] Global DS Map already exists and is valid: " + map_name_string + " (Size: " + string(ds_map_size(variable_global_get(map_name_string))) + ")");
    }
};

_init_global_ds_map("party_current_stats");
_init_global_ds_map("gate_states_map");
_init_global_ds_map("recruited_npcs_map");
_init_global_ds_map("broken_blocks_map");
_init_global_ds_map("loot_drops_map");
// Add any other global DS Maps here following the same pattern

// Initialize party members and inventory arrays
if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
    global.party_members = [];
    show_debug_message("[GameManager_Create] Initialized global.party_members array.");
}
if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) {
    global.party_inventory = [];
    show_debug_message("[GameManager_Create] Initialized global.party_inventory array.");
}


// Debug Save Trigger
if (keyboard_check_pressed(vk_f5)) {
    show_debug_message("--- F5 Pressed! Attempting Save (using scr_save_game) ---");
    var _save_success = scr_save_game("mysave.json");
    show_debug_message("--- scr_save_game Result: " + string(_save_success) + " ---");
}

// Debug Load Trigger
if (keyboard_check_pressed(vk_f9)) {
    show_debug_message("--- F9 Pressed! Attempting Load (using scr_load_game) ---");
    var _load_initiated = scr_load_game("mysave.json");
    show_debug_message("--- scr_load_game Initiated: " + string(_load_initiated) + " ---");
}

layer_to_hide_on_alarm = "";

show_debug_message("[GameManager_Create] Initialization complete.");
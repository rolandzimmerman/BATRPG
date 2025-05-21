// obj_game_manager :: Create Event

// global.player_position_handled_by_battle_return = false; // This seems specific, keep if needed for battle logic

if (!variable_instance_exists(id, "game_state")) {
    game_state = "playing";
}

// NEW: Initialize the primary flag for our loading system
if (!variable_global_exists("isLoadingGame")) {
    global.isLoadingGame = false;
}
// These are primarily managed by the new load/apply scripts, but initializing is okay.
if (!variable_global_exists("pending_load_data")) {
    global.pending_load_data = undefined;
}
if (!variable_global_exists("player_state_loaded_this_frame")) {
    global.player_state_loaded_this_frame = false;
}


// Make sure the manager itself is persistent (Object Editor checkbox)

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

// Initialize party data defaults (scr_load_game will overwrite these on load)
if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
    global.party_members = [];
}
if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) {
    global.party_inventory = [];
}
if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
    if (variable_global_exists("party_current_stats") && is_real(global.party_current_stats)) {
         ds_map_destroy(global.party_current_stats); // Destroy if it's a number but not a map
    }
    global.party_current_stats = ds_map_create();
}
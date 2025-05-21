/// obj_game_manager :: Room Start Event (NEW - Replaces ALL existing Room Start code)

show_debug_message("[GameManager_RoomStart] In room: " + room_get_name(room) + ". My ID: " + string(id) + ", My Depth: " + string(depth));
if (global.isLoadingGame) {
    scr_apply_post_load_state();  // this will restore player/NPC state *and* remove any instances that shouldn’t respawn
    // after this point, normal game_start logic can run
    return; // skip the rest of this event for the load frame
}
// Log obj_player status for debugging event order
if (instance_exists(obj_player)) {
    show_debug_message("[GameManager_RoomStart] obj_player (ID: " + string(obj_player.id) + ") exists. Its Depth: " + string(obj_player.depth));
} else {
    show_debug_message("[GameManager_RoomStart] obj_player does NOT exist at the start of MY Room Start event.");
}

// Check the flag set by scr_load_game
if (variable_global_exists("isLoadingGame") && global.isLoadingGame == true) {
    show_debug_message("[GameManager_RoomStart] isLoadingGame is TRUE. Calling scr_apply_post_load_state().");
    scr_apply_post_load_state(); // This script handles applying player/NPC states, activation, unpausing
} else {
    var _reason = "Not applicable or already handled.";
    if (!variable_global_exists("isLoadingGame")) {
         _reason = "isLoadingGame global var does not exist.";
    } else if (global.isLoadingGame == false) {
         _reason = "isLoadingGame is FALSE (normal room change or load process completed).";
    }
    show_debug_message("[GameManager_RoomStart] isLoadingGame is not true. NOT calling scr_apply_post_load_state(). Reason: " + _reason);
}
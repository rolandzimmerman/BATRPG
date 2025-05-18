/// @function scr_player_check_game_aborts()
/// @description Checks for game states that should halt player Step event processing.
/// @returns {Bool} True if player logic should abort, false otherwise.

// Get reference to the game manager
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;

// Abort if game manager missing or paused
if (_gm == noone || (variable_instance_exists(_gm, "game_state") && _gm.game_state != "playing")) {
    // Assuming game_state could be "paused", "dialogue", "battle", etc.
    // Modify condition if "playing" is not the only active state for player movement.
    return true; 
}

// Abort if in battle room (obj_player might still exist but shouldn't run overworld logic)
// or if a dialog object is active
if (room == rm_battle || instance_exists(obj_dialog)) {
    return true;
}
return false;
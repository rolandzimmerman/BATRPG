/// @function scr_player_handle_dash()
/// @description Handles player dashing state, input, and movement.
/// @returns {Bool} True if dashing (and Step should exit), false otherwise.
/// Called from obj_player's Step Event.

// --- Dash Input ---
// Assuming self.isDiving and self.isDashing are checked before calling this
// or that this script is only called if not in those states.
// For simplicity, combining input here.
var _dash_left_input  = keyboard_check_pressed(ord("Q")) || gamepad_button_check_pressed(0, gp_shoulderl);
var _dash_right_input = keyboard_check_pressed(ord("E")) || gamepad_button_check_pressed(0, gp_shoulderr);

if (!self.isDiving && !self.isDashing) { // Only allow dash input if not already dashing or diving
    if (_dash_left_input) {
        if (script_exists(scr_player_dash)) scr_player_dash(-1); // Call your existing dash trigger script
    } else if (_dash_right_input) {
        if (script_exists(scr_player_dash)) scr_player_dash(+1);
    }
}

// --- Dash Mode Handler ---
if (self.isDashing) {
    var _move_x = self.dash_speed * self.dash_dir;
    var _dash_targets = [ self.tilemap ]; // Local target array for dash
    if (self.tilemap_phase_id != -1) array_push(_dash_targets, self.tilemap_phase_id);
    array_push(_dash_targets, obj_destructible_block, obj_gate); // Ensure these are correct
    
    move_and_collide(_move_x, 0, _dash_targets);

    self.sprite_index = (self.dash_dir < 0) ? spr_player_dash_left : spr_player_dash_right;
    self.image_speed = 1;
    self.dash_timer -= 1;

    if (self.dash_timer <= 0) {
        self.isDashing  = false;
        self.player_state = PLAYER_STATE.FLYING; // Or a default state
        self.sprite_index = spr_player_walk_right; // Or default flying sprite
        self.image_speed = 0;
        self.image_index = 0;
    }
    return true; // Dashing, caller should exit
}
return false; // Not dashing
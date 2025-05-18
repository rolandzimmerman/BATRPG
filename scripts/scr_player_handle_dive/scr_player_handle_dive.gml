/// @function scr_player_handle_dive()
/// @description Handles player diving state, input, and movement.
/// @returns {Bool} True if diving (and Step should exit), false otherwise.
/// Called from obj_player's Step Event.

// --- Dive Input ---
var _dive_input = keyboard_check_pressed(ord("B")) || gamepad_button_check_pressed(0, gp_face2);
if (_dive_input && !self.isDiving && !self.isDashing) { // Only if not already diving or dashing
    if (script_exists(scr_player_dive)) scr_player_dive(); // Call your existing dive trigger script
}

// --- Dive Mode Handler ---
if (self.isDiving) {
    self.v_speed = self.dive_max_speed;
    var _dive_targets = [ self.tilemap ]; // Local target array for dive
    if (self.tilemap_phase_id != -1) array_push(_dive_targets, self.tilemap_phase_id);
    array_push(_dive_targets, obj_destructible_block); // Ensure this is correct
    
    var _cols = move_and_collide(0, self.v_speed, _dive_targets);

    self.sprite_index = spr_dive; // Ensure spr_dive exists
    self.image_speed  = 1;

    if (array_length(_cols) > 0 || place_meeting(x, y + 1, self.tilemap)) {
        self.isDiving   = false;
        self.player_state = PLAYER_STATE.FLYING; // Or default state
        self.image_speed = 0;
        self.image_index = 0;

        var _fx_layer = layer_get_id("Effects");
        if (_fx_layer == -1) _fx_layer = layer_get_id("Instances"); // Fallback layer
        if (object_exists(obj_dive_slam_fx)) {
             instance_create_layer((bbox_left + bbox_right) / 2, (bbox_top  + bbox_bottom)/ 2, _fx_layer, obj_dive_slam_fx);
        }
    }
    return true; // Diving, caller should exit
}
return false; // Not diving
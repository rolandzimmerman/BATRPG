/// @function scr_player_movement_flappy(input_dir_x, perform_flap)
/// @description Handles player's flappy bird style movement, gravity, and collisions.
/// @param {real} input_dir_x The horizontal input direction (-1 for left, 1 for right, 0 for none).
/// @param {boolean} perform_flap True if a flap action should be initiated.
function scr_player_movement_flappy(_input_dir_x, _perform_flap) { // Note: GML best practice is to prefix arguments or make them local vars
    if (object_index != obj_player) {
        show_debug_message("CRITICAL ALERT: scr_player_movement_flappy called by an object that IS NOT obj_player! Object is: " + object_get_name(object_index) + " (id: " + string(id) + ")");
        // For this test, let's just stop the script if it's not obj_player to prevent the v_speed error from THIS specific cause.
        // This won't fix it if obj_player itself is calling it before v_speed is set, but it will isolate one possibility.
        exit;
    }

    // If it IS obj_player, check for v_speed
    if (!variable_instance_exists(id, "v_speed")) {
         show_debug_message("CRITICAL ALERT: obj_player (id: " + string(id) + ") is calling scr_player_movement_flappy BUT v_speed is NOT set!");
         // Let's also exit here to prevent the crash, to see if this message appears.
         exit;
    }
    // Using local vars for arguments is safer
    var input_dir_x = _input_dir_x;
    var perform_flap = _perform_flap;

    // Diagnostic Check
    if (!variable_instance_exists(id, "v_speed") || !variable_instance_exists(id, "gravity_force")) {
        show_debug_message("ERROR in scr_player_movement_flappy: Required variables (v_speed, gravity_force) not set on instance " + string(id) + " (object: " + object_get_name(object_index) + "). Script called too early or by wrong object.");
        // If running on an object that is not obj_player, or obj_player is not initialized, this is an issue
        if (object_index != obj_player) { // Example check
             show_debug_message("Warning: scr_player_movement_flappy called by an object that is not obj_player!");
        }
        // Consider exiting if critical variables are missing, though this hides the root problem.
        // For now, let it try and potentially error, so the original error message remains consistent if this isn't the cause.
    }


    // --- Apply Flap Action ---
    if (perform_flap) {
        // Using 'self' explicitly for clarity, though usually not strictly needed if context is correct
        self.v_speed = self.flap_strength;
    }

    // --- Apply Gravity ---
    // Ensure these variables exist on 'self' (the calling instance)
    self.v_speed += self.gravity_force; // This is your line 17 based on typical script line counting
    self.v_speed = clamp(self.v_speed, self.flap_strength * 1.5, self.max_v_speed_fall);

    // --- Horizontal Movement & Collision ---
    var _current_h_speed = input_dir_x * self.horizontal_move_speed;

    if (_current_h_speed != 0 && variable_instance_exists(self.id, "tilemap") && self.tilemap != -1) {
        var _h_collisions = move_and_collide(_current_h_speed, 0, self.tilemap);
        if (array_length(_h_collisions) > 0) {
            // Horizontal collision
        }
    } else if (_current_h_speed != 0) {
        self.x += _current_h_speed;
    }

    // --- Vertical Movement & Collision ---
    if (variable_instance_exists(self.id, "tilemap") && self.tilemap != -1) {
        var _v_collisions = move_and_collide(0, self.v_speed, self.tilemap);
        if (array_length(_v_collisions) > 0) {
            self.v_speed = 0;
        }
    } else {
        self.y += self.v_speed;
    }
}

// NO OTHER EXECUTABLE CODE SHOULD BE HERE IN THE SCRIPT FILE
// For example, a line like:
// scr_player_movement_flappy(0, false); // <--- THIS WOULD CAUSE THE ERROR if present here
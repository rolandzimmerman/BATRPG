/// @function scr_player_update_state_and_movement(_input_dir_x, _perform_flap_action)
/// @description Manages player state (flying, walking) and executes movement logic.
/// @param {real} _input_dir_x Horizontal input direction (-1, 0, 1).
/// @param {boolean} _perform_flap_action True if flap action should be initiated this step.
function scr_player_update_state_and_movement(_input_dir_x, _perform_flap_action) {

    switch (self.player_state) {

        // ==================== FLYING STATE ====================
    case PLAYER_STATE.FLYING:
        // --- Physics for Flying ---
        if (_perform_flap_action) {
            self.v_speed = self.flap_strength;
        }
        self.v_speed += self.gravity_force;
        self.v_speed = clamp(self.v_speed, self.flap_strength * 1.5, self.max_v_speed_fall);

        // --- Horizontal Movement & Collision (Flying) ---
        var _current_h_speed = _input_dir_x * self.horizontal_move_speed;
        if (_current_h_speed != 0) {
            var _h_collisions_flying = move_and_collide(_current_h_speed, 0, self.tilemap);
        }

        // --- Vertical Movement & Collision (Flying) ---
        var _v_speed_before_collide = self.v_speed;
        var _v_collision_reported = false; // Flag to indicate if move_and_collide reported anything

        if (_v_speed_before_collide != 0) {
            if (self.tilemap == -1) {
                show_debug_message("WARNING in FLYING state: self.tilemap is -1. Skipping vertical collision.");
            } else {
                var _v_collision_array = move_and_collide(0, _v_speed_before_collide, self.tilemap);
                if (array_length(_v_collision_array) > 0) {
                    _v_collision_reported = true; // move_and_collide returned something
                    show_debug_message("Vertical collision reported. Data[0]: " + string(_v_collision_array[0]));
                    // Note: self.v_speed may have been set to 0 by move_and_collide if it's a "solid" stop.
                }
            }
        }

        // --- State Transition Checks (from Flying) ---
        if (_v_collision_reported) {
            // Since the collision data is not a usable struct, we rely on the direction of movement
            // before collision, and the fact that move_and_collide stopped us.
            // move_and_collide itself should have positioned the instance adjacent to the tile.

            if (_v_speed_before_collide >= 0) { // Was moving down (or stationary) and hit something
                show_debug_message("Transition: FLYING -> WALKING_FLOOR (based on downward collision stop)");
                self.player_state = PLAYER_STATE.WALKING_FLOOR;
                // self.y should be correctly positioned by move_and_collide. Fine-tune if needed later.
                self.v_speed = 0;
            } else { // Was moving up (_v_speed_before_collide < 0) and hit something
                show_debug_message("Transition: FLYING -> WALKING_CEILING (based on upward collision stop)");
                self.player_state = PLAYER_STATE.WALKING_CEILING;
                // self.y should be correctly positioned by move_and_collide. Fine-tune if needed later.
                self.v_speed = 0;
            }
        }
        break; // End of FLYING case

        // ==================== WALKING ON FLOOR STATE ====================
        case PLAYER_STATE.WALKING_FLOOR:
            show_debug_message("Player State: WALKING_FLOOR"); // Standard debug message

            // 1. Check for transition to FLYING (if flap button pressed)
            if (_perform_flap_action) {
                show_debug_message("Transition: WALKING_FLOOR -> FLYING (Flap initiated)");
                self.player_state = PLAYER_STATE.FLYING;
                self.v_speed = self.flap_strength; // Give upward flap boost
                break; // Exit this state's logic immediately
            }

            // 2. Apply "gravity" or ensure grounded (stick to floor)
            // For walking on a flat floor, we mostly want to ensure v_speed doesn't accumulate
            // and that the player is precisely on the ground.
            // move_and_collide should have placed us correctly when landing.
            self.v_speed = 0; // Prevent any residual vertical speed from affecting ground check

            // 3. Horizontal Movement
            var _current_h_speed_floor = _input_dir_x * self.horizontal_move_speed;
            if (_current_h_speed_floor != 0) {
                // Store x before move to see if a wall was hit
                // var _x_before_h_move = self.x;
                var _h_collisions_floor = move_and_collide(_current_h_speed_floor, 0, self.tilemap);
                // if (self.x == _x_before_h_move && array_length(_h_collisions_floor) > 0) {
                //    show_debug_message("Walked into a wall on floor.");
                // }
            }

            // 4. Check if still on ground after horizontal movement (detect walking off edges)
            // We check 1 pixel below the player's bounding box.
            if (place_meeting(self.x, self.y + 1, self.tilemap)) {
                // Still on ground.
                // Optional: Precise y-snapping to prevent bouncing on imperfect tile collisions,
                // but move_and_collide usually handles this well if y was correct on landing.
                // If y needs fine-tuning, it can be done here. For now, assume it's okay.
                self.v_speed = 0; // Ensure no vertical speed while grounded
            } else {
                // No ground detected 1 pixel below - player has walked off an edge.
                show_debug_message("Transition: WALKING_FLOOR -> FLYING (Walked off edge)");
                self.player_state = PLAYER_STATE.FLYING;
                // v_speed is already 0, so gravity in the FLYING state will take over next step.
            }
            break;

        // ==================== WALKING ON CEILING STATE ====================
        case PLAYER_STATE.WALKING_CEILING:
            show_debug_message("Player State: WALKING_CEILING");

            // 1. Check for transition to FLYING (if flap button pressed)
            if (_perform_flap_action) {
                show_debug_message("Transition: WALKING_CEILING -> FLYING (Flap initiated - detaching)");
                self.player_state = PLAYER_STATE.FLYING;
                self.v_speed = 1.5; // Apply a small positive (downward) v_speed to push OFF the ceiling
                break; // Exit this state's logic immediately
            }

            // 2. Stick to ceiling & Horizontal Movement
            self.v_speed = 0;
            move_and_collide(0, -1, self.tilemap); // Attempt to stick/re-align with ceiling
            self.v_speed = 0; // Re-affirm v_speed is zero after the sticking move

            var _current_h_speed_ceiling = _input_dir_x * self.horizontal_move_speed;
            if (_current_h_speed_ceiling != 0) {
                var _h_collisions_ceiling = move_and_collide(_current_h_speed_ceiling, 0, self.tilemap);
            }

            // 3. Check if still on ceiling after horizontal movement (detect walking off edges)
            if (place_meeting(self.x, self.y - 1, self.tilemap)) {
                // Still on ceiling.
            } else {
                // No ceiling detected 1 pixel above - player has walked off an edge.
                show_debug_message("Walked off edge (ceiling) - transitioning to FLYING");
                self.player_state = PLAYER_STATE.FLYING;
                
                // --- FIX FOR CLIPPING ---
                self.y += 2; // Nudge the bat down by a few pixels immediately
                self.v_speed = self.gravity_force; // Give it an initial downward speed (one step of gravity)
                                                   // This helps ensure it moves away from the ceiling edge
                                                   // in the first frame of being in the FLYING state.
                // -------------------------
            }
            break;
    }
}
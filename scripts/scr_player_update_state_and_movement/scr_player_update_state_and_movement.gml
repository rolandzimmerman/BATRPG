/// @function scr_player_update_state_and_movement(_input_dir_x, _action_key_pressed, _key_up_held, _key_down_held)
/// @description Manages player state (flying, walking) and executes movement logic, including phasing and step-up/down.
/// @param {real} _input_dir_x Horizontal input direction (-1, 0, 1).
/// @param {boolean} _action_key_pressed True if the primary action/flap key was pressed this step.
/// @param {boolean} _key_up_held True if the up directional key is held.
/// @param {boolean} _key_down_held True if the down directional key is held.
function scr_player_update_state_and_movement(_input_dir_x, _action_key_pressed, _key_up_held, _key_down_held) {
    if (object_index != obj_player) {
        // Optionally, a debug message here if you want to know what else is trying to call it.
        show_debug_message("Warning: scr_player_update_state_and_movement called by non-player: " + object_get_name(object_index));
        exit; // Stop execution for non-player objects
    }
    // --- Define Collision Targets ---
    var _collision_targets = [self.tilemap]; // Start with main collision map
    if (self.tilemap_phase_id != -1) {
        array_push(_collision_targets, self.tilemap_phase_id); // Add phase map if it exists
    }
    var _can_check_phase_layer = (self.tilemap_phase_id != -1); // Flag for easier checking later

    // --- State Machine ---
    switch (self.player_state) {

        // ==================== FLYING STATE ====================
        case PLAYER_STATE.FLYING:
            //show_debug_message("State: FLYING");
            // --- Physics for Flying ---
            if (_action_key_pressed) {
                self.v_speed = self.flap_strength;
            }
            self.v_speed += self.gravity_force;
            self.v_speed = clamp(self.v_speed, self.flap_strength * 1.5, self.max_v_speed_fall);

            // --- Horizontal Movement & Collision (Flying) ---
            var _current_h_speed_flying = _input_dir_x * self.horizontal_move_speed;
            if (_current_h_speed_flying != 0) {
                move_and_collide(_current_h_speed_flying, 0, _collision_targets);
            }

            // --- Vertical Movement & Collision (Flying) ---
            var _v_speed_before_collide = self.v_speed;
            var _v_collision_reported = false; // <<< CORRECT INITIALIZATION HERE

            if (_v_speed_before_collide != 0) {
                if (self.tilemap == -1 && (!_can_check_phase_layer || self.tilemap_phase_id == -1) ) {
                    show_debug_message("WARNING in FLYING state: No valid collision tilemaps. Skipping vertical collision.");
                } else {
                    var _v_collision_array = move_and_collide(0, _v_speed_before_collide, _collision_targets);
                    if (array_length(_v_collision_array) > 0) {
                        _v_collision_reported = true; // Set to true if move_and_collide returns collision data
                        show_debug_message("Vertical collision reported (FLYING). Data[0]: " + string(_v_collision_array[0]));
                    }
                }
            }

            // --- State Transition Checks (from Flying) ---
            // Line 42 (approximately) would be this 'if' statement:
            if (_v_collision_reported) { // Now _v_collision_reported is guaranteed to be defined
                if (_v_speed_before_collide >= 0) { // Was moving down (or stationary) and hit something
                    show_debug_message("Transition: FLYING -> WALKING_FLOOR (direct collision)");
                    self.player_state = PLAYER_STATE.WALKING_FLOOR; // Ensure this uses your corrected enum member
                    self.v_speed = 0;
                } else { // Was moving up (_v_speed_before_collide < 0) and hit something
                    show_debug_message("Transition: FLYING -> WALKING_CEILING (direct collision)");
                    self.player_state = PLAYER_STATE.WALKING_CEILING; // Ensure this uses your corrected enum member
                    self.v_speed = 0;
                }
            } else if (_v_speed_before_collide < 0) { 
                // NO direct collision stopped us, BUT we WERE moving upwards. Check for a "near miss" ceiling latch.
                var _ceiling_grace_check_dist = 2; 
                var _y_check_for_grace_latch = self.y - _ceiling_grace_check_dist;

                var _near_ceiling_main = place_meeting(self.x, _y_check_for_grace_latch, self.tilemap);
                var _near_ceiling_phase = false;
                if (_can_check_phase_layer) {
                    _near_ceiling_phase = place_meeting(self.x, _y_check_for_grace_latch, self.tilemap_phase_id);
                }

                if (_near_ceiling_main || _near_ceiling_phase) {
                    show_debug_message("Grace Latch: FLYING -> WALKING_CEILING (near miss detected)");
                    self.player_state = PLAYER_STATE.WALKING_CEILING; // Corrected enum member
                    self.v_speed = 0; 
                    // Optional: Add an immediate forceful snap to the ceiling here if needed
                    // move_and_collide(0, -(_ceiling_grace_check_dist + 2), _collision_targets);
                    // self.v_speed = 0; // Re-zero after snap
                }
            }
            break; // End of FLYING case


        // ==================== WALKING ON FLOOR STATE ====================
        case PLAYER_STATE.WALKING_FLOOR:
// --- Phasing Check (Priority 1) ---
            if (_action_key_pressed && _key_down_held && _can_check_phase_layer && variable_instance_exists(id,"TILE_SIZE") && self.TILE_SIZE > 0) {
                if (tilemap_get_at_pixel(self.tilemap_phase_id, self.x, self.bbox_bottom) != 0) { 
                    show_debug_message("Attempting Phase: Floor -> Ceiling");
                    
                    var _player_height = self.bbox_bottom - self.bbox_top;
                    // Move player's origin DOWN so its TOP edge is TILE_SIZE below its original BOTTOM edge.
                    // This ensures the entire hitbox clears the tile it was standing on.
                    self.y += (_player_height + self.TILE_SIZE); 
                    
                    self.player_state = PLAYER_STATE.WALKING_CEILING; 
                    self.v_speed = 0;
                    
                    // NO immediate snap here. Let the WALKING_CEILING state's logic handle sticking in the next frame.
                    break; 
                }
            }

            // --- Flap to Fly Check (Priority 2) ---
            if (_action_key_pressed) {
                show_debug_message("Transition: WALKING_FLOOR -> FLYING (Flap initiated)");
                self.player_state = PLAYER_STATE.FLYING;
                self.v_speed = self.flap_strength;
                break;
            }

            // --- Normal Floor Walking Logic (Priority 3) ---
            //show_debug_message("State: WALKING_FLOOR");
            self.v_speed = 0; // Keep v_speed zero while walking

            // Horizontal Movement with Step-Up
            var _current_h_speed_floor = _input_dir_x * self.horizontal_move_speed;
            if (_current_h_speed_floor != 0) {
                var _x_before_h_move_floor = self.x;
                var _y_before_h_move_floor = self.y;

                var _h_collisions_initial_floor = move_and_collide(_current_h_speed_floor, 0, _collision_targets);

                if (self.x == _x_before_h_move_floor && array_length(_h_collisions_initial_floor) > 0) {
                    show_debug_message("Floor Horizontal collision. Attempting step-up...");
                    var _max_step_up = 16; 
                    var _stepped_up_successfully = false;
                    
                    var _original_y_for_step = self.y;
                    // Try to move up, checking for ceiling collisions during the step-up itself
                    var _y_before_nudge = self.y;
                    var _upward_nudge_collisions = move_and_collide(0, -_max_step_up, _collision_targets);
                    var _actual_y_nudge_amount = _y_before_nudge - self.y; // Positive if moved up

                    if (_actual_y_nudge_amount > 0) { // If we actually moved up some amount
                        // Attempt horizontal move from new y
                        var _h_collisions_after_step = move_and_collide(_current_h_speed_floor, 0, _collision_targets);
                        if (self.x != _x_before_h_move_floor) { // Moved horizontally
                            _stepped_up_successfully = true;
                            show_debug_message("Step-up (floor) successful. Snapping down.");
                            move_and_collide(0, _actual_y_nudge_amount + 1, _collision_targets); // Snap down slightly more than nudged
                            self.v_speed = 0;
                        }
                    }
                    
                    if (!_stepped_up_successfully) {
                        self.y = _original_y_for_step; // Revert y to before any step attempt
                        self.x = _x_before_h_move_floor;  // x should already be here from first collision
                        show_debug_message("Step-up (floor) failed.");
                    }
                }
            }
            
            // Stick to floor + Edge detection
            var _check_dist_ground = 2;
            var _is_ground_below_main = place_meeting(self.x, self.y + _check_dist_ground, self.tilemap);
            var _is_ground_below_phase = false;
            if (_can_check_phase_layer) {
                _is_ground_below_phase = place_meeting(self.x, self.y + _check_dist_ground, self.tilemap_phase_id);
            }
            var _is_ground_below = _is_ground_below_main || _is_ground_below_phase;

            if (_is_ground_below) {
                move_and_collide(0, 1, _collision_targets); // Final snap down
                self.v_speed = 0;
            } else {
                show_debug_message("Transition: WALKING_FLOOR -> FLYING (Walked off edge)");
                self.player_state = PLAYER_STATE.FLYING;
            }
            break;


        // ==================== WALKING ON CEILING STATE ====================
        case PLAYER_STATE.WALKING_CEILING:
// --- Phasing Check (Priority 1) ---
            if (_action_key_pressed && _key_up_held && _can_check_phase_layer && variable_instance_exists(id,"TILE_SIZE") && self.TILE_SIZE > 0) {
                if (tilemap_get_at_pixel(self.tilemap_phase_id, self.x, self.bbox_top - 1) != 0) {
                     show_debug_message("Attempting Phase: Ceiling -> Floor");
                     
                     var _player_height = self.bbox_bottom - self.bbox_top;
                     // Move player's origin UP so its BOTTOM edge is TILE_SIZE above its original TOP edge.
                     self.y -= (_player_height + self.TILE_SIZE); 
                     
                     self.player_state = PLAYER_STATE.WALKING_FLOOR;
                     self.v_speed = 0;
                     
                     // NO immediate snap here. Let the WALKING_ON_FLOOR state's logic handle sticking in the next frame.
                     break;
                 }
             }

            // --- Flap to Fly Check (Priority 2) ---
             if (_action_key_pressed) {
                 show_debug_message("Transition: WALKING_CEILING -> FLYING (Flap initiated - detaching)");
                 self.player_state = PLAYER_STATE.FLYING;
                 self.v_speed = 1.5; 
                 break;
             }

            // --- Normal Ceiling Walking Logic (Priority 3) ---
            //show_debug_message("State: WALKING_CEILING");
            self.v_speed = 0; 

            // Horizontal Movement with Step-Down
            var _current_h_speed_ceiling = _input_dir_x * self.horizontal_move_speed;
            if (_current_h_speed_ceiling != 0) {
                var _x_before_h_move_ceil = self.x;
                var _y_before_h_move_ceil = self.y;

                var _h_collisions_initial_ceil = move_and_collide(_current_h_speed_ceiling, 0, _collision_targets);

                if (self.x == _x_before_h_move_ceil && array_length(_h_collisions_initial_ceil) > 0) {
                    show_debug_message("Ceiling Horizontal collision. Attempting step-down...");
                    var _max_step_down = 16; 
                    var _stepped_down_successfully = false;
                    
                    var _original_y_for_step_ceil = self.y;
                    // Try to move "down" (increase y) checking for floor collisions
                    var _y_before_nudge_ceil = self.y;
                    var _downward_nudge_collisions = move_and_collide(0, _max_step_down, _collision_targets);
                    var _actual_y_nudge_amount_ceil = self.y - _y_before_nudge_ceil; // Positive if moved down

                    if (_actual_y_nudge_amount_ceil > 0) { // If we actually moved "down"
                        var _h_collisions_after_step_ceil = move_and_collide(_current_h_speed_ceiling, 0, _collision_targets);
                        if (self.x != _x_before_h_move_ceil) { // Moved horizontally
                            _stepped_down_successfully = true;
                            show_debug_message("Step-down (ceiling) successful. Snapping up.");
                            move_and_collide(0, -(_actual_y_nudge_amount_ceil + 1), _collision_targets); // Snap "up"
                            self.v_speed = 0;
                        }
                    }

                    if (!_stepped_down_successfully) {
                        self.y = _original_y_for_step_ceil;
                        self.x = _x_before_h_move_ceil;
                        show_debug_message("Step-down (ceiling) failed.");
                    }
                }
            }
            
            // Stick to ceiling + Edge detection
            var _check_dist_ceil = 2;
            var _is_ceiling_above_main = place_meeting(self.x, self.y - _check_dist_ceil, self.tilemap);
            var _is_ceiling_above_phase = false;
            if (_can_check_phase_layer) {
                _is_ceiling_above_phase = place_meeting(self.x, self.y - _check_dist_ceil, self.tilemap_phase_id);
            }
            var _is_ceiling_above = _is_ceiling_above_main || _is_ceiling_above_phase;

            if (_is_ceiling_above) {
                move_and_collide(0, -1, _collision_targets); // Final snap up
                self.v_speed = 0;
            } else {
                show_debug_message("Transition: WALKING_CEILING -> FLYING (Walked off edge)");
                self.player_state = PLAYER_STATE.FLYING;
                self.y += 2; 
                self.v_speed = self.gravity_force; 
            }
            break;
    } // End Switch
} // End Function
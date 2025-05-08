/// @function scr_player_update_state_and_movement(_input_dir_x, _action_key_pressed, _key_up_held, _key_down_held)
/// @description Manages player state (flying, walking) and executes movement logic, including phasing.
/// @param {real} _input_dir_x Horizontal input direction (-1, 0, 1).
/// @param {boolean} _action_key_pressed True if the primary action/flap key was pressed this step.
/// @param {boolean} _key_up_held True if the up directional key is held.
/// @param {boolean} _key_down_held True if the down directional key is held.
function scr_player_update_state_and_movement(_input_dir_x, _action_key_pressed, _key_up_held, _key_down_held) {

    // --- Define Collision Targets ---
    var _collision_targets = [self.tilemap]; // Start with main collision map
    if (self.tilemap_phase_id != -1) {
        array_push(_collision_targets, self.tilemap_phase_id); // Add phase map if it exists
    }
    var _can_check_phase_layer = (self.tilemap_phase_id != -1); // Flag for easier checking later


    switch (self.player_state) {

        // ==================== FLYING STATE ====================
        case PLAYER_STATE.FLYING:
            // --- Physics for Flying ---
            if (_action_key_pressed) {
                self.v_speed = self.flap_strength;
            }
            self.v_speed += self.gravity_force;
            self.v_speed = clamp(self.v_speed, self.flap_strength * 1.5, self.max_v_speed_fall);

            // --- Horizontal Movement & Collision (Flying) ---
            var _current_h_speed_flying = _input_dir_x * self.horizontal_move_speed;
            if (_current_h_speed_flying != 0) {
                // Use _collision_targets array
                var _h_collisions_flying = move_and_collide(_current_h_speed_flying, 0, _collision_targets);
            }

            // --- Vertical Movement & Collision (Flying) ---
            var _v_speed_before_collide = self.v_speed;
            var _v_collision_reported = false;

            if (_v_speed_before_collide != 0) {
                if (self.tilemap == -1 && self.tilemap_phase_id == -1) { // Only skip if BOTH are invalid
                    show_debug_message("WARNING in FLYING state: No valid collision tilemaps. Skipping vertical collision.");
                } else {
                    // Use _collision_targets array
                    var _v_collision_array = move_and_collide(0, _v_speed_before_collide, _collision_targets);
                    if (array_length(_v_collision_array) > 0) {
                        _v_collision_reported = true;
                        show_debug_message("Vertical collision reported (FLYING). Data[0]: " + string(_v_collision_array[0]));
                    }
                }
            }

            // --- State Transition Checks (from Flying) ---
            if (_v_collision_reported) {
                // Fallback logic based on direction (as detailed collision data was unreliable previously)
                if (_v_speed_before_collide >= 0) { // Hit floor
                    show_debug_message("Transition: FLYING -> WALKING_FLOOR (based on downward collision stop)");
                    self.player_state = PLAYER_STATE.WALKING_FLOOR;
                    self.v_speed = 0;
                    // Snap Y position more accurately after state change if needed
                } else { // Hit ceiling
                    show_debug_message("Transition: FLYING -> WALKING_CEILING (based on upward collision stop)");
                    self.player_state = PLAYER_STATE.WALKING_CEILING;
                    self.v_speed = 0;
                    // Snap Y position more accurately after state change if needed
                }
            }
            break;


// ==================== WALKING ON FLOOR STATE ====================
        case PLAYER_STATE.WALKING_FLOOR:
            // --- Phasing Check (Priority 1) ---
            // NOTE: This still relies on a TILE_SIZE assumption for the y-adjustment.
            // If tile height truly varies, phasing needs a more complex way to determine platform thickness.
            if (_action_key_pressed && _key_down_held && _can_check_phase_layer && variable_instance_exists(id,"TILE_SIZE") && self.TILE_SIZE > 0) {
                if (tilemap_get_at_pixel(self.tilemap_phase_id, self.x, self.bbox_bottom) != 0) { // Check phase layer using coordinates
                    show_debug_message("Attempting Phase: Floor -> Ceiling");
                    // Precise Y adjust assumes TILE_SIZE is the platform thickness
                    var _current_tile_top_y = floor(self.bbox_bottom / self.TILE_SIZE) * self.TILE_SIZE;
                    var _new_target_y_for_bbox_top = _current_tile_top_y + self.TILE_SIZE;
                    self.y = _new_target_y_for_bbox_top + (self.y - self.bbox_top);
                    self.player_state = PLAYER_STATE.WALKING_CEILING;
                    self.v_speed = 0;
                    break; // Exit switch
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
            show_debug_message("State: WALKING_FLOOR");
            self.v_speed = 0; // Keep v_speed zero while walking

            // Horizontal Movement
            var _current_h_speed_floor = _input_dir_x * self.horizontal_move_speed;
            if (_current_h_speed_floor != 0) {
                move_and_collide(_current_h_speed_floor, 0, _collision_targets);
            }

            // Stick to floor & Edge detection (Check BOTH layers for ground presence)
            var _check_dist_ground = 2; // How far below bbox to check
            // Check main collision layer
            var _is_ground_below_main = place_meeting(self.x, self.y + _check_dist_ground, self.tilemap);
            // Check phase layer (if it exists)
            var _is_ground_below_phase = false;
            if (_can_check_phase_layer) { // _can_check_phase_layer was set at script start
                _is_ground_below_phase = place_meeting(self.x, self.y + _check_dist_ground, self.tilemap_phase_id);
            }
            // Consider ground present if found on EITHER layer
            var _is_ground_below = _is_ground_below_main || _is_ground_below_phase;

            show_debug_message("Ground Check: MainLayer? "+string(_is_ground_below_main)+" PhaseLayer? "+string(_is_ground_below_phase)+" | GroundBelow?: "+string(_is_ground_below));

            if (_is_ground_below) {
                // Ground IS below on at least one layer. Ensure snapped using all targets.
                move_and_collide(0, 1, _collision_targets); // Snap down using all targets
                self.v_speed = 0; // Re-affirm speed is zero after snap attempt
            } else {
                // No ground detected below on EITHER layer.
                show_debug_message("Transition: WALKING_FLOOR -> FLYING (Walked off edge - checked both layers)");
                self.player_state = PLAYER_STATE.FLYING;
                // v_speed is already 0, gravity will take over.
            }
            break; // End of WALKING_FLOOR case


// ==================== WALKING ON CEILING STATE ====================
        case PLAYER_STATE.WALKING_CEILING:
             // --- Phasing Check (Priority 1 - Requires TILE_SIZE assumption) ---
             if (_action_key_pressed && _key_up_held && _can_check_phase_layer && variable_instance_exists(id,"TILE_SIZE") && self.TILE_SIZE > 0) {
                 if (tilemap_get_at_pixel(self.tilemap_phase_id, self.x, self.bbox_top - 1) != 0) { // Check phase layer using coordinates
                     show_debug_message("Attempting Phase: Ceiling -> Floor");
                     // Precise Y adjust assumes TILE_SIZE is platform thickness
                     var _current_tile_bottom_y = ceil(self.bbox_top / self.TILE_SIZE) * self.TILE_SIZE;
                     var _new_target_y_for_bbox_bottom = _current_tile_bottom_y - self.TILE_SIZE;
                     self.y = _new_target_y_for_bbox_bottom - (self.bbox_bottom - self.y);
                     self.player_state = PLAYER_STATE.WALKING_FLOOR;
                     self.v_speed = 0;
                     break; // Exit switch.
                 }
             }

            // --- Flap to Fly Check (Priority 2) ---
             if (_action_key_pressed) {
                 show_debug_message("Transition: WALKING_CEILING -> FLYING (Flap initiated - detaching)");
                 self.player_state = PLAYER_STATE.FLYING;
                 self.v_speed = 1.5; // Push OFF the ceiling
                 break;
             }

            // --- Normal Ceiling Walking Logic (Priority 3) ---
            show_debug_message("State: WALKING_CEILING");
            self.v_speed = 0; // Keep v_speed zero

            // Horizontal Movement
            var _current_h_speed_ceiling = _input_dir_x * self.horizontal_move_speed;
            if (_current_h_speed_ceiling != 0) {
                move_and_collide(_current_h_speed_ceiling, 0, _collision_targets);
            }

            // Stick to ceiling & Edge detection (Check BOTH layers for ceiling presence)
            var _check_dist_ceil = 2; // How far above bbox to check
            // Check main collision layer
            var _is_ceiling_above_main = place_meeting(self.x, self.y - _check_dist_ceil, self.tilemap);
            // Check phase layer (if it exists)
            var _is_ceiling_above_phase = false;
            if (_can_check_phase_layer) {
                _is_ceiling_above_phase = place_meeting(self.x, self.y - _check_dist_ceil, self.tilemap_phase_id);
            }
            // Consider ceiling present if found on EITHER layer
            var _is_ceiling_above = _is_ceiling_above_main || _is_ceiling_above_phase;

            show_debug_message("Ceiling Check: MainLayer? "+string(_is_ceiling_above_main)+" PhaseLayer? "+string(_is_ceiling_above_phase)+" | CeilingAbove?: "+string(_is_ceiling_above));

            if (_is_ceiling_above) {
                // Ceiling IS above on at least one layer. Ensure snapped using all targets.
                move_and_collide(0, -1, _collision_targets); // Snap up using all targets
                self.v_speed = 0; // Re-affirm speed is zero after snap attempt
            } else {
                // No ceiling detected above on EITHER layer.
                show_debug_message("Transition: WALKING_CEILING -> FLYING (Walked off edge - checked both layers)");
                self.player_state = PLAYER_STATE.FLYING;
                self.y += 2; // Nudge down
                self.v_speed = self.gravity_force; // Initial downward speed
            }
            break; // End of WALKING_ON_CEILING case
    }
}
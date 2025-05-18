/// @function scr_player_update_state_and_movement(_input_dir_x, _action_key_pressed, _key_up_held, _key_down_held)
/// Based on user's original script, with only SAFER CORNER-SLIDE implemented.
/// Phasing initiation conditions set to user's original.
function scr_player_update_state_and_movement(_input_dir_x, _action_key_pressed, _key_up_held, _key_down_held) {
    if (self.isDiving) return;
    // if (self.isDashing) return; // Keep if this was in your provided original
    if (object_index != obj_player) exit;

    var targets = [ self.tilemap ];
    if (self.tilemap_phase_id != -1) {
        array_push(targets, self.tilemap_phase_id);
    }
    array_push(targets, obj_destructible_block, obj_gate);
    var can_phase = (self.tilemap_phase_id != -1);

    var desired_h = _input_dir_x;
    if (self.stuck_counter > 10) {
        desired_h = 0;
        self.stuck_counter = 0;
    }

    switch (self.player_state) {

    case PLAYER_STATE.FLYING:
        var old_x = x, old_y = y;
        var hspd = desired_h * horizontal_move_speed;
        if (hspd != 0) {
            var hcols = move_and_collide(hspd, 0, targets);
            if (array_length(hcols) > 0 && x == old_x) {
                y -= 1; move_and_collide(hspd, 0, targets); y += 1;
            }
        }
        if ((place_meeting(x, old_y, self.tilemap) || place_meeting(x, old_y, self.tilemap_phase_id))) {
            x = old_x;
        }
        if (hspd != 0 && x == old_x) stuck_counter += 1; else stuck_counter = 0;

        if (_action_key_pressed) v_speed = flap_strength;
        v_speed += gravity_force;
        v_speed = clamp(v_speed, flap_strength * 1.5, max_v_speed_fall);

        var vcols = [];
        if (v_speed != 0) {
            vcols = move_and_collide(0, v_speed, targets);
        }
        if ((place_meeting(old_x, y, self.tilemap) || place_meeting(old_x, y, self.tilemap_phase_id))) {
            y = old_y;
            v_speed = 0;
        }
        if (array_length(vcols) > 0) {
            if (v_speed >= 0) player_state = PLAYER_STATE.WALKING_FLOOR;
            else player_state = PLAYER_STATE.WALKING_CEILING;
            v_speed = 0;
        }
        break;

    case PLAYER_STATE.WALKING_FLOOR:
        var old_x2 = x, old_y2 = y;

        // Phase down (using exact original condition)
        if (_action_key_pressed && _key_down_held && can_phase && variable_instance_exists(id,"TILE_SIZE")) {
            if (tilemap_get_at_pixel(tilemap_phase_id, x, bbox_bottom) != 0) { // User's original condition
                y += (bbox_bottom - bbox_top) + TILE_SIZE;
                player_state = PLAYER_STATE.WALKING_CEILING;
                v_speed = 0;
                break;
            }
        }
        if (_action_key_pressed) {
            player_state = PLAYER_STATE.FLYING;
            v_speed = flap_strength;
            break;
        }

        var hspd2 = desired_h * horizontal_move_speed;
        if (hspd2 != 0) {
            var cols2 = move_and_collide(hspd2, 0, targets);
            // [ your step-up logic here ]
            if (array_length(cols2) > 0 && x == old_x2) {
                y -= 1; move_and_collide(hspd2, 0, targets); y += 1;
            }
            
            // --- SAFER CORNER-SLIDE (as implemented before) ---
            if (x == old_x2 && hspd2 != 0) { 
                var next_x_slide = x + sign(hspd2);
                var next_y_slide = y + 1; 
                var can_slide_safely = true;
                var temp_current_x = x;
                var temp_current_y = y;
                x = next_x_slide;
                y = next_y_slide;
                for (var i = 0; i < array_length(targets); ++i) {
                    if (place_meeting(x, y, targets[i])) {
                        can_slide_safely = false;
                        break; 
                    }
                }
                x = temp_current_x;
                y = temp_current_y;
                if (can_slide_safely) {
                    x = next_x_slide;
                    y = next_y_slide;
                    v_speed = 0;
                }
            }
            // --- END SAFER CORNER-SLIDE ---
        }

        if ((place_meeting(x, old_y2, tilemap) || place_meeting(x, old_y2, tilemap_phase_id))) {
            x = old_x2;
        }
        if ((place_meeting(old_x2, y, tilemap) || place_meeting(old_x2, y, tilemap_phase_id))) {
            y = old_y2;
        }

        var ground_check_dist = 2; // Using your established pattern
        var on_ground = false;
        if (self.tilemap != -1 && place_meeting(x, y + ground_check_dist, self.tilemap)) on_ground = true;
        if (!on_ground && self.tilemap_phase_id != -1 && place_meeting(x, y + ground_check_dist, self.tilemap_phase_id)) on_ground = true;
        
        if (!on_ground) player_state = PLAYER_STATE.FLYING;
        break;
                  

    case PLAYER_STATE.WALKING_CEILING:
        var old_x3 = x, old_y3 = y;

        // Phase up (using exact original condition)
        if (_action_key_pressed && _key_up_held && can_phase && variable_instance_exists(id,"TILE_SIZE")) {
            if (tilemap_get_at_pixel(tilemap_phase_id, x, bbox_top - 1) != 0) { // User's original condition
                y -= (bbox_bottom - bbox_top) + TILE_SIZE;
                player_state = PLAYER_STATE.WALKING_FLOOR;
                v_speed = 0;
                break;
            }
        }
        if (_action_key_pressed) {
            player_state = PLAYER_STATE.FLYING;
            v_speed = gravity_force;
            break;
        }

        var hspd3 = desired_h * horizontal_move_speed;
        if (hspd3 != 0) {
            var cols3 = move_and_collide(hspd3, 0, targets);
            // [ your step-down logic here ]
            if (array_length(cols3) > 0 && x == old_x3) {
                y += 1; move_and_collide(hspd3, 0, targets); y -= 1;
            }

            // --- SAFER CORNER-SLIDE (as implemented before) ---
            if (x == old_x3 && hspd3 != 0) {
                var next_x_slide_c = x + sign(hspd3);
                var next_y_slide_c = y - 1; 
                var can_slide_safely_c = true;
                var temp_current_x_c = x;
                var temp_current_y_c = y;
                x = next_x_slide_c;
                y = next_y_slide_c;
                for (var i = 0; i < array_length(targets); ++i) {
                    if (place_meeting(x, y, targets[i])) {
                        can_slide_safely_c = false;
                        break;
                    }
                }
                x = temp_current_x_c;
                y = temp_current_y_c;
                if (can_slide_safely_c) {
                    x = next_x_slide_c;
                    y = next_y_slide_c;
                    v_speed = 0;
                }
            }
            // --- END SAFER CORNER-SLIDE ---
        }

        if ((place_meeting(x, old_y3, tilemap) || place_meeting(x, old_y3, tilemap_phase_id))) {
            x = old_x3;
        }
        if ((place_meeting(old_x3, y, tilemap) || place_meeting(old_x3, y, tilemap_phase_id))) {
            y = old_y3;
        }

        var ceiling_check_dist = 2; // Using your established pattern
        var on_ceiling = false;
        if (self.tilemap != -1 && place_meeting(x, y - ceiling_check_dist, self.tilemap)) on_ceiling = true;
        if (!on_ceiling && self.tilemap_phase_id != -1 && place_meeting(x, y - ceiling_check_dist, self.tilemap_phase_id)) on_ceiling = true;

        if (!on_ceiling) {
            player_state = PLAYER_STATE.FLYING;
            y += 2;
            v_speed = gravity_force;
        }
        break;
    }
}
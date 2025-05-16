/// @function scr_player_update_state_and_movement(_input_dir_x, _action_key_pressed, _key_up_held, _key_down_held)
function scr_player_update_state_and_movement(_input_dir_x, _action_key_pressed, _key_up_held, _key_down_held) {
    if (self.isDiving) return;
    if (object_index != obj_player) exit;

    // Build collision targets once
    var targets = [ self.tilemap ];
    if (self.tilemap_phase_id != -1) {
        array_push(targets, self.tilemap_phase_id);
    }
    array_push(targets, obj_destructible_block, obj_gate, obj_map_boss_parent);
    var can_phase = (self.tilemap_phase_id != -1);

   // Escape hatch
    var desired_h = _input_dir_x;
    if (self.stuck_counter > 10) {
        desired_h = 0;
        self.stuck_counter = 0;
    }

    switch (self.player_state) {

    // ===== FLYING =====
    case PLAYER_STATE.FLYING:
        // Record old pos
        var old_x = x, old_y = y;

        // 1) Horizontal
        var hspd = desired_h * horizontal_move_speed;
        if (hspd != 0) {
            var hcols = move_and_collide(hspd, 0, targets);
            // micro-nudge
            if (array_length(hcols)>0 && x==old_x) {
                y -= 1; move_and_collide(hspd, 0, targets); y += 1;
            }
        }
        // axis-specific fallback
        if ((place_meeting(x, old_y, self.tilemap) || place_meeting(x, old_y, self.tilemap_phase_id))) {
            x = old_x;
        }

        // track stuck
        if (hspd != 0 && x == old_x) stuck_counter += 1; else stuck_counter = 0;

        // 2) Vertical
        if (_action_key_pressed) v_speed = flap_strength;
        v_speed += gravity_force;
        v_speed = clamp(v_speed, flap_strength*1.5, max_v_speed_fall);

        var vcols = [];
        if (v_speed != 0) {
            vcols = move_and_collide(0, v_speed, targets);
        }
        // micro-nudge not needed vertically

/*        // vertical fallback
        if ((place_meeting(old_x, y, self.tilemap) || place_meeting(old_x, y, self.tilemap_phase_id))) {
            y = old_y;
            v_speed = 0;
        }
*/
        // Transition
        if (array_length(vcols) > 0) {
            if (v_speed >= 0) player_state = PLAYER_STATE.WALKING_FLOOR;
            else                player_state = PLAYER_STATE.WALKING_CEILING;
            v_speed = 0;
        }
        break;


    // ===== WALKING ON FLOOR =====
    case PLAYER_STATE.WALKING_FLOOR:
        var old_x2 = x, old_y2 = y;

        // Phase down
        if (_action_key_pressed && _key_down_held && can_phase && variable_instance_exists(id,"TILE_SIZE")) {
            if (tilemap_get_at_pixel(tilemap_phase_id, x, bbox_bottom) != 0) {
                y += (bbox_bottom - bbox_top) + TILE_SIZE;
                player_state = PLAYER_STATE.WALKING_CEILING;
                v_speed = 0;
                break;
            }
        }
        // Flap to fly
        if (_action_key_pressed) {
            player_state = PLAYER_STATE.FLYING;
            v_speed = flap_strength;
            break;
        }

        // Horizontal walk + guards
        var hspd2 = desired_h * horizontal_move_speed;
        if (hspd2 != 0) {
            var cols2 = move_and_collide(hspd2, 0, targets);

            // [ your step-up logic here ]

            // micro-nudge
            if (array_length(cols2)>0 && x==old_x2) {
                y -= 1; move_and_collide(hspd2,0,targets); y += 1;
            }
            // corner-slide
            if (x==old_x2) {
                x += sign(hspd2); y += 1; v_speed = 0;
            }
        }

        // horizontal fallback
        if ((place_meeting(x, old_y2, tilemap) || place_meeting(x, old_y2, tilemap_phase_id))) {
            x = old_x2;
        }
        // vertical fallback (rare)
        if ((place_meeting(old_x2, y, tilemap) || place_meeting(old_x2, y, tilemap_phase_id))) {
            y = old_y2;
        }

        // edge-of-floor
        var ground = (place_meeting(x, y+2, tilemap) || place_meeting(x, y+2, tilemap_phase_id));
        if (!ground) player_state = PLAYER_STATE.FLYING;
        break;
              

    // ===== WALKING ON CEILING =====
    case PLAYER_STATE.WALKING_CEILING:
        var old_x3 = x, old_y3 = y;

        // Phase up
        if (_action_key_pressed && _key_up_held && can_phase && variable_instance_exists(id,"TILE_SIZE")) {
            if (tilemap_get_at_pixel(tilemap_phase_id, x, bbox_top-1) != 0) {
                y -= (bbox_bottom - bbox_top) + TILE_SIZE;
                player_state = PLAYER_STATE.WALKING_FLOOR;
                v_speed = 0;
                break;
            }
        }
        // Flap to fly
        if (_action_key_pressed) {
            player_state = PLAYER_STATE.FLYING;
            v_speed = gravity_force;
            break;
        }

        // Horizontal ceiling-walk + guards
        var hspd3 = desired_h * horizontal_move_speed;
        if (hspd3 != 0) {
            var cols3 = move_and_collide(hspd3, 0, targets);

            // [ your step-down logic here ]

            // micro-nudge
            if (array_length(cols3)>0 && x==old_x3) {
                y += 1; move_and_collide(hspd3,0,targets); y -= 1;
            }
            // corner-slide
            if (x==old_x3) {
                x += sign(hspd3); y -= 1; v_speed = 0;
            }
        }

        // horizontal fallback
        if ((place_meeting(x, old_y3, tilemap) || place_meeting(x, old_y3, tilemap_phase_id))) {
            x = old_x3;
        }
        // vertical fallback
        if ((place_meeting(old_x3, y, tilemap) || place_meeting(old_x3, y, tilemap_phase_id))) {
            y = old_y3;
        }

        // edge-of-ceiling
        var ceiling = (place_meeting(x, y-2, tilemap) || place_meeting(x, y-2, tilemap_phase_id));
        if (!ceiling) {
            player_state = PLAYER_STATE.FLYING;
            y += 2;
            v_speed = gravity_force;
        }
        break;
    }
}

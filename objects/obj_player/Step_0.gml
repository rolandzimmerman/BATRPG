/// obj_player :: Step Event

// --- Invulnerability and Flashing Logic ---
if (invulnerable_timer > 0) {
    invulnerable_timer -= 1;
    flash_cycle_timer -= 1;
    if (flash_cycle_timer <= 0) {
        flash_cycle_timer = flash_interval;
        is_flashing_visible = !is_flashing_visible;
    }
    if (invulnerable_timer == 0) {
        is_flashing_visible = true; 
    }
} else {
    if (!is_flashing_visible) { 
        is_flashing_visible = true;
    }
}

// --- KNOCKBACK HANDLING ---
if (variable_instance_exists(id, "is_in_knockback") && is_in_knockback) {
    if (knockback_timer > 0) {
        knockback_timer -= 1;
        var _kb_dx = knockback_hspeed;
        var _kb_dy = knockback_vspeed;
        if (tilemap != -1 && place_meeting(x + _kb_dx, y, tilemap)) {
            while(!place_meeting(x + sign(_kb_dx), y, tilemap)) { x += sign(_kb_dx); }
            knockback_hspeed = 0; 
        } else {
            x += _kb_dx;
        }
        if (tilemap != -1 && place_meeting(x, y + _kb_dy, tilemap)) {
            while(!place_meeting(x, y + sign(_kb_dy), tilemap)) { y += sign(_kb_dy); }
            knockback_vspeed = 0; 
            v_speed = 0;       
        } else {
            y += _kb_dy;
        }
        knockback_hspeed *= knockback_friction;
        knockback_vspeed *= knockback_friction;
        if (abs(knockback_hspeed) < 0.1 && abs(knockback_vspeed) < 0.1) {
            knockback_timer = 0;
        }
        if (knockback_timer == 0) {
            is_in_knockback = false;
            knockback_hspeed = 0; 
            knockback_vspeed = 0;
            show_debug_message("Player " + string(id) + " knockback effect ended.");
        }
        exit; // Skip normal player input and movement logic
    } else {
        is_in_knockback = false; 
        knockback_hspeed = 0;
        knockback_vspeed = 0;
    }
}
// --- END KNOCKBACK HANDLING ---

// --- Dash Mode Handler ---
if (isDashing) {
    var move_x = dash_speed * dash_dir;
    var targets = [ tilemap ];
    if (tilemap_phase_id != -1) array_push(targets, tilemap_phase_id);
    array_push(targets, obj_destructible_block, obj_gate);
    move_and_collide(move_x, 0, targets);
    sprite_index = (dash_dir < 0) ? spr_player_dash_left : spr_player_dash_right;
    image_speed = 1;
    dash_timer -= 1;
    if (dash_timer <= 0) {
        isDashing = false;
        player_state = PLAYER_STATE.FLYING;
        sprite_index = spr_player_walk_right; 
        image_speed = 0;
        image_index = 0;
    }
    exit;
}

// --- Dash Input ---
var dash_left_input = input_check_pressed(INPUT_ACTION.DASH_LEFT);
var dash_right_input = input_check_pressed(INPUT_ACTION.DASH_RIGHT);
if (!isDiving && !isDashing) {
    if (dash_left_input) scr_player_dash(-1);
    else if (dash_right_input) scr_player_dash(+1);
}

// --- Dive Mode Handler ---
if (isDiving) {
    v_speed = dive_max_speed;
    var collision_targets = [ tilemap ];
    if (tilemap_phase_id != -1) array_push(collision_targets, tilemap_phase_id);
    array_push(collision_targets, obj_destructible_block);
    var cols = move_and_collide(0, v_speed, collision_targets);
    sprite_index = spr_dive;
    image_speed = 1;
    if (array_length(cols) > 0 || place_meeting(x, y + 1, tilemap)) {
        isDiving = false;
        player_state = PLAYER_STATE.FLYING;
        image_speed = 0;
        image_index = 0;
        var fx_layer = layer_get_id("Effects");
        if (fx_layer == -1) fx_layer = layer_get_id("Instances");
        instance_create_layer(
            (bbox_left + bbox_right) / 2,
            (bbox_top  + bbox_bottom)/ 2,
            fx_layer,
            obj_dive_slam_fx
        );
    }
    exit;
}

// Get reference to the game manager
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;

// Abort if game manager missing or game not in "playing" state
if (_gm == noone || _gm.game_state != "playing") {
    if (variable_instance_exists(id, "image_speed")) { image_speed = 0; } 
    exit;
}
// Abort if in battle or dialog
if (room == rm_battle || instance_exists(obj_dialog)) {
    if (variable_instance_exists(id, "image_speed")) { image_speed = 0; }
    exit;
}

// --- Pause Handling ---
var pause_input_key = input_check_pressed(INPUT_ACTION.PAUSE); // Changed variable name slightly
if (pause_input_key && !instance_exists(obj_pause_menu)) {
    _gm.game_state = "paused";
    var pause_layer = layer_get_id("Instances_GUI");
    if (pause_layer == -1) {
        pause_layer = layer_get_id("Instances");
        if (pause_layer == -1) {
            show_debug_message("ERROR: Could not find a suitable layer for pause menu. Creating fallback.");
            pause_layer = layer_create(-10000, "PauseMenuFallbackLayer");
        }
    }
    var menu = instance_create_layer(0, 0, pause_layer, obj_pause_menu);
    instance_deactivate_object(id); 
    if (instance_exists(obj_npc_parent)) {
        instance_deactivate_object(obj_npc_parent);
    }
    instance_activate_object(menu);
    instance_activate_object(obj_game_manager); 
    exit;
}

// --- Player Input Gathering ---
// Use sign() on the axis value if you need a strictly digital (-1, 0, 1) result for dir_x/dir_y
// as the original code implied for gamepad stick input.
dir_x = sign(input_get_axis(INPUT_ACTION.MOVE_HORIZONTAL_AXIS));
dir_y = sign(input_get_axis(INPUT_ACTION.MOVE_VERTICAL_AXIS));

var key_action_initiated_this_step = input_check_pressed(INPUT_ACTION.JUMP_FLAP);
var key_up_held = input_check(INPUT_ACTION.ANY_UP_HELD);
var key_down_held = input_check(INPUT_ACTION.ANY_DOWN_HELD);
var interact_key_pressed = input_check_pressed(INPUT_ACTION.INTERACT);

var npc_at_player = instance_place(x, y, obj_npc_parent);
var can_interact_with_npc = instance_exists(npc_at_player) && variable_instance_exists(npc_at_player, "can_talk") && npc_at_player.can_talk;

// --- Process High-Level Actions ---
if (can_interact_with_npc && interact_key_pressed) {
    with (npc_at_player) {
        event_perform(ev_other, ev_user0);
    }
}

// --- Dive Input ---
var key_dive_input = input_check_pressed(INPUT_ACTION.DIVE); // Changed variable name
if (key_dive_input && !isDiving && player_state == PLAYER_STATE.FLYING) { 
    scr_player_dive();
}

// --- Call Main Movement & State Script ---
scr_player_update_state_and_movement(dir_x, key_action_initiated_this_step, key_up_held, key_down_held);

// --- Define Flap Key States for Animation ---
var anim_flap_key_pressed = key_action_initiated_this_step; 
var anim_flap_key_held = input_check(INPUT_ACTION.JUMP_FLAP);
var anim_flap_key_released = input_check_released(INPUT_ACTION.JUMP_FLAP);

// --- Animation ---
if (dir_x != 0) {
    self.face_dir = dir_x;
}
switch (self.player_state) {
    case PLAYER_STATE.FLYING:
        image_speed = 0; 
        if (self.face_dir == 1) {
            sprite_index = spr_player_walk_right; 
        } else {
            sprite_index = spr_player_walk_left;  
        }
        if (anim_flap_key_released) { 
            image_index = 0; 
        } else if (anim_flap_key_pressed) { 
            image_index = 1; 
            if (audio_exists(snd_sfx_flap)) {
                audio_play_sound(snd_sfx_flap, 10, false, 1);
            }
        } else if (anim_flap_key_held) { 
            image_index = 1; 
        } else { 
            image_index = 0; 
        }
        break;
    case PLAYER_STATE.WALKING_FLOOR: 
        if (dir_x != 0) { 
            image_speed = self.walk_animation_speed; 
        } else {
            image_speed = 0;
            image_index = 0; 
        }
        if (self.face_dir == 1) {
            sprite_index = spr_player_walk_right_ground; 
        } else {
            sprite_index = spr_player_walk_left_ground;  
        }
        break;
    case PLAYER_STATE.WALKING_CEILING: 
        if (dir_x != 0) { 
            image_speed = self.walk_animation_speed;
        } else {
            image_speed = 0;
            image_index = 0;
        }
        if (self.face_dir == 1) {
            sprite_index = spr_player_walk_right_ceiling; 
        } else {
            sprite_index = spr_player_walk_left_ceiling;  
        }
        break;
}

// --- Fire echo missile on X ---
if (input_check_pressed(INPUT_ACTION.FIRE_MISSILE)) {
    if (scr_HaveItem("echo_gem", 1)) {
        var m = instance_create_depth(x, y, 0, obj_echo_missile);
        if (audio_exists(snd_sfx_echo)) {
            audio_play_sound(snd_sfx_echo, 10, false, 1);
        }
        m.hspeed = missile_speed * face_dir;  
        m.origin_x = x;                                       
        m.max_dist = missile_max_distance;    
        if (face_dir > 0) {
            m.sprite_index = spr_echo_right;
        } else {
            m.sprite_index = spr_echo_left;
        }
        m.image_speed = 0.4;
        m.image_index = 0;
    } else { 
        // Optional: Play a "cannot fire" or "no ammo" sound
    }
}

// --- Room Transitions & Out of Bounds ---
// (Your existing room transition and clamping logic remains here unchanged)
//show_debug_message("--- Transition Block START ---");
if (!variable_instance_exists(id, "dir_x")) {
    show_debug_message("  TRANSITION_ERROR: Instance variable 'dir_x' is MISSING! Defaulting to 0.");
    var _current_h_input_dir = 0; 
} else {
    var _current_h_input_dir = dir_x; 
}
if (!variable_instance_exists(id, "dir_y")) { 
    show_debug_message("  TRANSITION_ERROR: Instance variable 'dir_y' is MISSING! Defaulting to 0.");
    var _current_v_input_dir = 0; 
} else {
    var _current_v_input_dir = dir_y; 
}
// ... (rest of your transition block) ...
var _exit_margin = 3;
var conn = ds_map_find_value(global.room_map, room);

if (ds_exists(conn, ds_type_map)) {
    // LEFT exit
    if (bbox_left <= _exit_margin) {
        if (ds_map_exists(conn, "left")) {
            var dest = ds_map_find_value(conn, "left");
            if (dest != noone && asset_get_type(dest) == asset_room && room_exists(dest)) {
                global.entry_direction = "none";
                global.next_spawn_object = obj_spawn_point_right;
                room_goto(dest);
                exit;
            }
        }
    }
    // RIGHT exit
    if (bbox_right >= room_width - _exit_margin) {
        if (ds_map_exists(conn, "right")) {
            var dest = ds_map_find_value(conn, "right");
            if (room_exists(dest)) {
                global.entry_direction = "none";
                global.next_spawn_object = obj_spawn_point_left;
                room_goto(dest);
                exit; 
            }
        }
    }
    // ABOVE exit
    if (bbox_top <= _exit_margin) {
        if (ds_map_exists(conn, "above")) {
            var dest = ds_map_find_value(conn, "above");
            if (room_exists(dest)) {
                global.entry_direction = "none"; 
                global.next_spawn_object = obj_spawn_point_bottom; 
                room_goto(dest);
                exit; 
            }
        }
    }
    // BELOW exit
    if (bbox_bottom >= room_height - _exit_margin) {
        if (ds_map_exists(conn, "below")) {
            var dest = ds_map_find_value(conn, "below");
            if (room_exists(dest)) {
                global.entry_direction = "none"; 
                global.next_spawn_object = obj_spawn_point_top; 
                room_goto(dest);
                exit; 
            }
        }
    }
}
// --- Fallback: Hard Clamps ---
var _player_bbox_left = bbox_left;
var _player_bbox_right = bbox_right;
var _player_bbox_top = bbox_top;
var _player_bbox_bottom = bbox_bottom;
if (_player_bbox_left < 0) { x = x - _player_bbox_left; } 
else if (_player_bbox_right > room_width) { x = x - (_player_bbox_right - room_width); }
if (_player_bbox_top < 0) { y = y - _player_bbox_top; } 
else if (_player_bbox_bottom > room_height) { y = y - (_player_bbox_bottom - room_height); }
//show_debug_message("--- Transition Block END (No transition occurred, clamps applied if needed) ---");


// --- Random Encounter ---
if (dir_x != 0 || v_speed != 0) { 
    if (!variable_global_exists("encounter_timer")) global.encounter_timer = 0;
    global.encounter_timer++;
}
var encounter_threshold = 300;
var encounter_chance = 10;
if (global.encounter_timer >= encounter_threshold) {
    global.encounter_timer = 0;
    if (random(100) < encounter_chance) {
        if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
            var list = ds_map_find_value(global.encounter_table, room);
            if (ds_exists(list, ds_type_list) && !ds_list_empty(list)) {
                audio_play_sound(snd_sfx_encounter, 1, 0); // Assuming gain default if not specified
                var index = irandom(ds_list_size(list) - 1);
                var formation = ds_list_find_value(list, index);
                if (is_array(formation)) {
                    global.battle_formation = formation;
                    global.original_room = room;
                    global.return_x = x; 
                    global.return_y = y; 
                    room_goto(rm_battle);
                    exit; 
                }
            }
        }
    }
}

// --- Soft “push out of solid” fallback ---
if ((tilemap != -1 && place_meeting(x, y, tilemap)) || (tilemap_phase_id != -1 && place_meeting(x, y, tilemap_phase_id))) {
    y -= 1;
}
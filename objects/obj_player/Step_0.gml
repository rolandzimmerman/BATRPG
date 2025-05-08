/// obj_player :: Step Event

// Get reference to the game manager
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;

// Abort if game manager missing or paused
if (_gm == noone || _gm.game_state != "playing") exit;
if (room == rm_battle) exit;

// --- Pause Handling ---
var pause_input = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_start);
if (pause_input && !instance_exists(obj_pause_menu)) {
    _gm.game_state = "paused";
    var pause_layer = layer_get_id("Instances_GUI");
    if (pause_layer == -1) pause_layer = layer_get_id("Instances");
    var menu = instance_create_layer(0, 0, pause_layer, obj_pause_menu);
    instance_deactivate_object(id);
    if (instance_exists(obj_npc_parent)) instance_deactivate_object(obj_npc_parent);
    instance_activate_object(menu);
    instance_activate_object(obj_game_manager);
    exit;
}

// --- Dialog Check ---
if (instance_exists(obj_dialog)) {
    // Optional: Gravity while dialog is up
    // v_speed += gravity_force;
    // v_speed = clamp(v_speed, flap_strength * 1.2, max_v_speed_fall);
    // var _v_collisions_dialog = move_and_collide(0, v_speed, tilemap);
    // if (array_length(_v_collisions_dialog) > 0) {
    //     v_speed = 0;
    // }
    exit;
}

// --- Player Input ---
// Horizontal Movement Input
var key_x_keyboard = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var joy_x_gamepad = gamepad_axis_value(0, gp_axislh);
if (abs(joy_x_gamepad) < 0.25) joy_x_gamepad = 0; // Deadzone

var dir_x = (key_x_keyboard != 0) ? key_x_keyboard : sign(joy_x_gamepad);
var current_h_speed = dir_x * horizontal_move_speed;

// Flap Input (Using Space and Gamepad Face Button 1, 'A' is now for left movement)
var key_flap_keyboard = keyboard_check_pressed(vk_space);
var key_flap_gamepad = gamepad_button_check_pressed(0, gp_face1); // Typically 'A' on Xbox, 'X' on PlayStation
var key_flap = key_flap_keyboard || key_flap_gamepad;

// NPC Interaction Input (Ensure this is a distinct key)
var interact_check_key = keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(0, gp_face3); // Example: Enter or 'Y'/Triangle
var npc_at_player = instance_place(x, y, obj_npc_parent);
var can_interact_with_npc = instance_exists(npc_at_player) && variable_instance_exists(npc_at_player, "can_talk") && npc_at_player.can_talk;

// --- Process Actions ---
if (can_interact_with_npc && interact_check_key) {
    with (npc_at_player) event_perform(ev_other, ev_user0);
    // Optionally halt player physics during interaction
    // v_speed = 0;
    // current_h_speed = 0;
} else if (key_flap) {
    v_speed = flap_strength;
    // audio_play_sound(snd_flap, 0, false); // Optional: flap sound
}

// --- Apply Gravity ---
v_speed += gravity_force;
v_speed = clamp(v_speed, flap_strength * 1.5, max_v_speed_fall); // Clamp overall vertical speed

// --- Movement & Collision ---
// Horizontal Collision
if (current_h_speed != 0 && variable_instance_exists(id, "tilemap") && tilemap != -1) {
    var _h_collisions = move_and_collide(current_h_speed, 0, tilemap);
    if (array_length(_h_collisions) > 0) {
        // Horizontal collision occurred.
        // show_debug_message("Horizontal Collision with tile.");
        // For Flappy Bird, hitting a side wall might be game over or just stop.
        // If game over: room_restart();
        // If just stop: current_h_speed would effectively be 0 for this frame's move
        // move_and_collide already handles stopping, so we might not need to set current_h_speed to 0 here
        // unless other logic depends on it AFTER collision.
    }
} else if (current_h_speed != 0) { // No tilemap to check against, or tilemap variable is invalid
    x += current_h_speed;
}

// Vertical Collision
if (variable_instance_exists(id, "tilemap") && tilemap != -1) {
    var _v_collisions = move_and_collide(0, v_speed, tilemap);
    if (array_length(_v_collisions) > 0) {
        // Vertical collision occurred.
        // show_debug_message("Vertical Collision with tile.");
        // In Flappy Bird, this is typically game over.
        // room_restart(); // Example
        v_speed = 0; // Stop vertical movement.
    }
} else { // No tilemap to check against or tilemap variable is invalid
    y += v_speed;
}

// --- Animation ---
image_speed = 1; // Default animation speed if moving/flapping

if (dir_x != 0) { // Moving horizontally
    if (dir_x > 0) {
        // If you have specific flying right/flapping right sprites:
        // sprite_index = (v_speed < -gravity_force*0.5) ? spr_player_flap_right : spr_player_fly_fall_right;
        // Using existing walk sprites as placeholders:
        sprite_index = spr_player_walk_right;
    } else { // dir_x < 0
        // sprite_index = (v_speed < -gravity_force*0.5) ? spr_player_flap_left : spr_player_fly_fall_left;
        sprite_index = spr_player_walk_left;
    }
} else { // Not moving horizontally (or input is zero), base on vertical movement
    if (v_speed < -gravity_force * 0.5) { // Moving upwards with some force
        // Use a generic "up" or "flap" animation, or a direction-neutral one if available
        // sprite_index = spr_player_flap_up; // Or a more generic flap if no horizontal movement
        sprite_index = spr_player_walk_up; // Placeholder
    } else { // Falling or neutral
        // sprite_index = spr_player_fall_down; // Or a more generic fall if no horizontal movement
        sprite_index = spr_player_walk_down; // Placeholder
    }
}

// If you want idle animations when on ground AND not flapping/moving:
// This requires a "grounded" check, which Flappy Bird usually doesn't have prominently.
// For now, the player is always considered "in air" for animation purposes.
// If v_speed is near 0 AND dir_x is 0, you might switch to an idle (e.g. spr_player_idle_down)
// but this depends on whether the player can actually "rest" or is always subject to gravity.
// For Flappy Bird style, usually, there's no true idle unless on a specific "safe" platform.


// --- Room Transitions & Out of Bounds ---
var exit_margin = 4;
var player_bbox_top = bbox_top;
var player_bbox_bottom = bbox_bottom;
var player_bbox_left = bbox_left;
var player_bbox_right = bbox_right;
var exit_dir = "none";

// Out of Bounds (Vertical - typically game over)
if (player_bbox_bottom > room_height + sprite_get_height(sprite_index) || player_bbox_top < 0 - sprite_get_height(sprite_index)) {
    // show_debug_message("GAME OVER - Out of Bounds (Vertical)");
    // room_restart(); // Example game over action
    y = clamp(y, 0, room_height); // Prevent continuous trigger if no restart
    v_speed = 0;
}
// Out of Bounds (Horizontal - might be game over or block)
if (player_bbox_right > room_width + sprite_get_width(sprite_index) && dir_x > 0) {
    // show_debug_message("GAME OVER - Out of Bounds (Right)");
    // room_restart();
    x = room_width - sprite_get_width(sprite_index)/2; // Clamp to edge
    current_h_speed = 0;
} else if (player_bbox_left < 0 - sprite_get_width(sprite_index) && dir_x < 0) {
    // show_debug_message("GAME OVER - Out of Bounds (Left)");
    // room_restart();
    x = sprite_get_width(sprite_index)/2; // Clamp to edge
    current_h_speed = 0;
}

// Room Transitions (Horizontal)
if (current_h_speed != 0) { // Only check if attempting to move horizontally
    if (player_bbox_left <= exit_margin && dir_x < 0) exit_dir = "left";
    else if (player_bbox_right >= room_width - exit_margin && dir_x > 0) exit_dir = "right";
}

if (exit_dir != "none") {
    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        var conn_map = ds_map_find_value(global.room_map, room);
        if (ds_exists(conn_map, ds_type_map) && ds_map_exists(conn_map, exit_dir)) {
            var dest = ds_map_find_value(conn_map, exit_dir);
            if (room_exists(dest)) {
                global.entry_direction = exit_dir;
                // Consider how player is positioned in new room for Flappy Bird style
                // global.return_x = (exit_dir == "left") ? room_width - 32 : 32; // Example entry points
                // global.return_y = room_height / 2;
                room_goto(dest);
                exit;
            }
        }
    }
    // If no room connection, player will be stopped by out-of-bounds logic or wall collision.
}


// --- Random Encounter ---
// Trigger based on any movement.
if (current_h_speed != 0 || v_speed != 0) {
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
                audio_play_sound(snd_sfx_encounter, 1, 0);
                var index = irandom(ds_list_size(list) - 1);
                var formation = ds_list_find_value(list, index);
                if (is_array(formation)) {
                    global.battle_formation = formation;
                    global.original_room = room;
                    global.return_x = x;
                    global.return_y = y;
                    // Consider resetting v_speed or placing player safely on battle return
                    room_goto(rm_battle);
                    exit;
                }
            }
        }
    }
}
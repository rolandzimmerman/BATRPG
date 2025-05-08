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
    // Optional: You might want to call a simplified physics script here if gravity should still apply
    // For now, just exit to prevent all player-controlled actions.
    exit;
}

// Horizontal Movement Input
var key_x_keyboard = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var joy_x_gamepad = gamepad_axis_value(0, gp_axislh);
if (abs(joy_x_gamepad) < 0.25) joy_x_gamepad = 0; // Deadzone
var dir_x = (key_x_keyboard != 0) ? key_x_keyboard : sign(joy_x_gamepad);

// Flap Input (for physics)
var key_flap_pressed_keyboard = keyboard_check_pressed(vk_space);
var key_flap_pressed_gamepad = gamepad_button_check_pressed(0, gp_face1);
var key_flap_initiated_this_step = key_flap_pressed_keyboard || key_flap_pressed_gamepad;

// NPC Interaction Input & State Setup
// These three lines MUST come before you use 'can_interact_with_npc' or 'interact_check_key' in decisions
var interact_check_key = keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(0, gp_face3); // Defines the interaction key press
var npc_at_player = instance_place(x, y, obj_npc_parent); // Finds if an NPC is at the player's position
var can_interact_with_npc = instance_exists(npc_at_player) && variable_instance_exists(npc_at_player, "can_talk") && npc_at_player.can_talk; // Defines whether interaction is possible

// --- Process High-Level Actions (Decide if interacting, then determine flap for physics) ---
// Line 45 (approximately) is likely here or similar:
var perform_flap_action_this_step = false;
if (can_interact_with_npc && interact_check_key) { // 'can_interact_with_npc' is USED here
    // Player is interacting, so no flap action
    with (npc_at_player) {
        event_perform(ev_other, ev_user0); // Perform the NPC's interaction event
    }
} else if (key_flap_initiated_this_step) {
    // Not interacting (or can't), and flap key was pressed
    perform_flap_action_this_step = true;
}

// --- Call Movement Script ---
scr_player_movement_flappy(dir_x, perform_flap_action_this_step);

// --- Define Flap Key States for Animation ---
var flap_key_is_pressed_anim = key_flap_initiated_this_step;
var flap_key_is_held_anim = keyboard_check(vk_space) || gamepad_button_check(0, gp_face1);
var flap_key_is_released_anim = keyboard_check_released(vk_space) || gamepad_button_check_released(0, gp_face1);


// --- Animation ---
image_speed = 0; // We are manually setting the image_index

// 1. Update instance variable 'face_dir' (if dir_x from input is not 0)
if (dir_x != 0) {
    self.face_dir = dir_x;
}

// 2. Set the base sprite_index based on 'face_dir'
if (self.face_dir == 1) { // Facing right
    sprite_index = spr_player_walk_right; // USE YOUR ACTUAL SPRITE NAME
} else { // Facing left
    sprite_index = spr_player_walk_left;  // USE YOUR ACTUAL SPRITE NAME
}

// 3. Set the image_index (frame) based on flap key state and vertical movement
if (flap_key_is_released_anim) {
    // Priority 1: If the flap key was just released, always go to fall frame.
    image_index = 0;
} else if (flap_key_is_pressed_anim) {
    // Priority 2: If the flap key was just pressed, show flap frame.
    // This also covers the first frame of a hold.
    image_index = 1;
} else if (flap_key_is_held_anim) {
    // Priority 3: If the flap key is being held (and not just pressed or released),
    // keep showing the flap frame. You might also add "&& self.v_speed < 0"
    // if you only want the flap frame while held AND moving up.
    // For now, holding = flap visual.
    image_index = 1;
} else {
    // Key is not pressed, not held, and not just released.
    // This state occurs after a tap (pressed then released) or just free-falling.
    // If player is rising from momentum after a tap, v_speed will be < 0.
    // "returns to index 0 when the A button is let go" applies here.
    image_index = 0; // Revert to fall frame if purely on momentum or actually falling.
}

// --- Room Transitions & Out of Bounds ---
// This logic uses dir_x (input intent) and bbox properties (actual position after movement script)
var current_h_speed_intent = dir_x * horizontal_move_speed; // Used for evaluating transition intent

var exit_margin = 4;
var player_bbox_top = bbox_top;
var player_bbox_bottom = bbox_bottom;
var player_bbox_left = bbox_left;
var player_bbox_right = bbox_right;
var exit_dir = "none";

// Out of Bounds (Vertical)
if (player_bbox_bottom > room_height + sprite_get_height(sprite_index) || player_bbox_top < 0 - sprite_get_height(sprite_index)) {
    // show_debug_message("GAME OVER - Out of Bounds (Vertical)");
    // room_restart();
    y = clamp(y, 0, room_height);
    v_speed = 0;
}
// Out of Bounds (Horizontal) - Note: move_and_collide in script should prevent most OOB if tilemap extends to edges.
// This is more of a fallback or for rooms without edge tiles.
if (player_bbox_right > room_width && dir_x > 0) { // Check against room_width directly
    // show_debug_message("GAME OVER - Out of Bounds (Right)");
    // room_restart();
    x = room_width - (bbox_right - x); // Correctly position at edge
} else if (player_bbox_left < 0 && dir_x < 0) {  // Check against 0 directly
    // show_debug_message("GAME OVER - Out of Bounds (Left)");
    // room_restart();
    x = 0 - (bbox_left - x); // Correctly position at edge
}

// Room Transitions (Horizontal) - uses current_h_speed_intent
if (current_h_speed_intent != 0) {
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
                room_goto(dest);
                exit;
            }
        }
    }
}

// --- Random Encounter ---
// Uses dir_x (input intent) and v_speed (current state after movement script)
if (dir_x != 0 || v_speed != 0) { // If player intended to move or is moving vertically
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
                    room_goto(rm_battle);
                    exit;
                }
            }
        }
    }
}
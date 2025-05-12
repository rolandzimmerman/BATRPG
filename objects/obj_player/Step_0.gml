/// obj_player :: Step Event

// Get reference to the game manager
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;

// Abort if game manager missing or paused
if (_gm == noone || _gm.game_state != "playing") {
    exit;
}
// Abort if in battle or dialog
if (room == rm_battle || instance_exists(obj_dialog)) {
    exit;
}

// --- Pause Handling ---
var pause_input = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_start);
if (pause_input && !instance_exists(obj_pause_menu)) {
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
// Horizontal Movement Input
var key_x_keyboard = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var joy_x_gamepad = gamepad_axis_value(0, gp_axislh);
if (abs(joy_x_gamepad) < 0.25) joy_x_gamepad = 0; // Deadzone
var dir_x = (key_x_keyboard != 0) ? key_x_keyboard : sign(joy_x_gamepad);

// Flap/Action Key (Pressed this step - used for flapping, phasing, detaching)
var key_action_initiated_this_step = keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);

// Up/Down Keys (Held state - for Phasing)
var key_up_held = keyboard_check(vk_up) || keyboard_check(ord("W")) || (gamepad_axis_value(0, gp_axislv) < -0.5) || gamepad_button_check(0, gp_padu);
var key_down_held = keyboard_check(vk_down) || keyboard_check(ord("S")) || (gamepad_axis_value(0, gp_axislv) > 0.5) || gamepad_button_check(0, gp_padd);

// NPC Interaction Input
var interact_key_pressed = keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(0, gp_face4); // Y/Triangle
var npc_at_player = instance_place(x, y, obj_npc_parent);
var can_interact_with_npc = instance_exists(npc_at_player) && variable_instance_exists(npc_at_player, "can_talk") && npc_at_player.can_talk;

// --- Process High-Level Actions (NPC Interaction has priority) ---
if (can_interact_with_npc && interact_key_pressed) {
    with (npc_at_player) {
        event_perform(ev_other, ev_user0); // Perform the NPC's interaction event
    }
    // If interaction occurs, key_action_initiated_this_step is still passed to script.
    // The script should ideally handle not flapping/phasing if an interaction just started,
    // or the dialog check at the top of the step event handles this by exiting.
}
// The 'else if (key_action_initiated_this_step)' block that was here and set
// 'perform_flap_action_for_physics' is no longer needed because
// 'key_action_initiated_this_step' is passed directly to the movement script.

// --- Call Main Movement & State Script ---
// Pass current horizontal input, the action key press, and up/down held states
scr_player_update_state_and_movement(dir_x, key_action_initiated_this_step, key_up_held, key_down_held);


// --- Define Flap Key States for Animation (specifically for FLYING animation) ---
var anim_flap_key_pressed = key_action_initiated_this_step; // Uses the same "action pressed" variable
var anim_flap_key_held = keyboard_check(vk_space) || gamepad_button_check(0, gp_face1);
var anim_flap_key_released = keyboard_check_released(vk_space) || gamepad_button_check_released(0, gp_face1);

// --- Animation ---
// Instance variable 'self.face_dir' is updated based on 'dir_x' (current frame's horizontal input)
if (dir_x != 0) {
    self.face_dir = dir_x;
}

switch (self.player_state) { // self.player_state is an instance variable set by the movement script
    case PLAYER_STATE.FLYING:
        image_speed = 0; // Manual frame control for flying
        if (self.face_dir == 1) {
            sprite_index = spr_player_walk_right; // Replace with your actual flying_right sprite
        } else {
            sprite_index = spr_player_walk_left;  // Replace with your actual flying_left sprite
        }

        // Flap/Fall frame animation for flying state
        if (anim_flap_key_released) { image_index = 0; }
        else if (anim_flap_key_pressed) { image_index = 1; }
        else if (anim_flap_key_held) { image_index = 1; }
        else { image_index = 0; }
        break;

    case PLAYER_STATE.WALKING_FLOOR: // Ensure your enum uses this exact name if you corrected it before
        if (dir_x != 0) { // If moving horizontally (based on current frame's input)
            image_speed = self.walk_animation_speed; // walk_animation_speed is an instance variable
        } else {
            image_speed = 0;
            image_index = 0; // Show first frame of walk cycle when still
        }
        if (self.face_dir == 1) {
            sprite_index = spr_player_walk_right_ground; // Replace with your actual sprite
        } else {
            sprite_index = spr_player_walk_left_ground;  // Replace with your actual sprite
        }
        break;

    case PLAYER_STATE.WALKING_CEILING: // Ensure your enum uses this exact name
        if (dir_x != 0) { // If moving horizontally
            image_speed = self.walk_animation_speed;
        } else {
            image_speed = 0;
            image_index = 0;
        }
        if (self.face_dir == 1) {
            sprite_index = spr_player_walk_right_ceiling; // Replace with your actual sprite
        } else {
            sprite_index = spr_player_walk_left_ceiling;  // Replace with your actual sprite
        }
        break;
}
// — Fire echo missile on X (keyboard “X” or controller Face3) —
if (keyboard_check_pressed(ord("X"))
 || gamepad_button_check_pressed(0, gp_face3))
{
    // Only allow if player has at least 1 Echo Gem
    if (scr_HaveItem("echo_gem", 1)) {
        // 1) Create the missile
        var m = instance_create_depth(x, y, 0, obj_echo_missile);

        // 2) Set its horizontal speed using hspeed
        m.hspeed    = missile_speed * face_dir;  
        m.origin_x  = x;                         
        m.max_dist  = missile_max_distance;      

        // 3) Choose the correct animated sprite
        if (face_dir > 0) {
            m.sprite_index = spr_echo_right;
        } else {
            m.sprite_index = spr_echo_left;
        }
        // 4) Kick off its built-in animation
        m.image_speed = 0.4;
        m.image_index = 0;
    } else { }
}




// --- Room Transitions & Out of Bounds ---
// horizontal_move_speed is an instance variable defined in Create Event
var current_h_speed_intent = dir_x * horizontal_move_speed;
var exit_margin = 4;
// Bbox variables are built-in and reflect current state after movement script
var player_bbox_top = bbox_top;
var player_bbox_bottom = bbox_bottom;
var player_bbox_left = bbox_left;
var player_bbox_right = bbox_right;
var exit_dir = "none";

// Out of Bounds (Vertical)
if (player_bbox_bottom > room_height + sprite_get_height(sprite_index) || player_bbox_top < 0 - sprite_get_height(sprite_index)) {
    y = clamp(y, 0, room_height);
    v_speed = 0; // v_speed is an instance variable
    // Optionally, force to FLYING state if pushed out of bounds while walking
    // if(player_state != PLAYER_STATE.FLYING) player_state = PLAYER_STATE.FLYING;
}

// Horizontal Room Transitions / Out of Bounds
// Only check for room transition if actually trying to move towards an edge
if (dir_x < 0 && player_bbox_left <= exit_margin) { // Moving left and at/past left margin
    exit_dir = "left";
} else if (dir_x > 0 && player_bbox_right >= room_width - exit_margin) { // Moving right and at/past right margin
    exit_dir = "right";
}
// The following out-of-bounds clamps are fallbacks if no room transition occurs
if (player_bbox_right > room_width && dir_x > 0) {
    x = room_width - (bbox_right - x); // Correctly position at edge
} else if (player_bbox_left < 0 && dir_x < 0) {
    x = 0 - (bbox_left - x); // Correctly position at edge
}


if (exit_dir != "none") {
    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        var conn_map = ds_map_find_value(global.room_map, room);
        if (ds_exists(conn_map, ds_type_map) && ds_map_exists(conn_map, exit_dir)) {
            var dest = ds_map_find_value(conn_map, exit_dir);
            if (room_exists(dest)) {
                global.entry_direction = exit_dir;
                // Potentially store return_x/y based on specific entry points in the new room,
                // rather than current x/y if that's more appropriate for your game.
                // global.return_x = x;
                // global.return_y = y;
                room_goto(dest);
                exit; // IMPORTANT to exit script after room_goto
            }
        }
    }
}


// --- Random Encounter ---
// v_speed is an instance variable updated by the movement script
if (dir_x != 0 || v_speed != 0) { // If player intended to move or is moving vertically
    if (!variable_global_exists("encounter_timer")) global.encounter_timer = 0;
    global.encounter_timer++;
}

var encounter_threshold = 300;
var encounter_chance = 100;

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
                    global.return_x = x; // Current x
                    global.return_y = y; // Current y
                    // Player state might need to be reset to PLAYER_STATE.FLYING upon returning from battle.
                    room_goto(rm_battle);
                    exit; // IMPORTANT
                }
            }
        }
    }
}







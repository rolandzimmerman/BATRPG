/// obj_player :: Step Event

// --- Invulnerability and Flashing Logic ---
if (invulnerable_timer > 0) {
    invulnerable_timer -= 1;

    flash_cycle_timer -= 1;
    if (flash_cycle_timer <= 0) {
        flash_cycle_timer = flash_interval;
        is_flashing_visible = !is_flashing_visible;
    }

    // Your existing debug message for Step event is good here:
    // show_debug_message("Player Step (Invulnerable): Timer: " + string(invulnerable_timer) + 
    //                   ", FlashCycleTimer: " + string(flash_cycle_timer) + 
    //                   ", IsVisiblePhase: " + string(is_flashing_visible));

    if (invulnerable_timer == 0) {
        is_flashing_visible = true; // Ensure fully visible when invulnerability ends
        // show_debug_message("Player invulnerability ended. Forced visible.");
    }
} else {
    if (!is_flashing_visible) { // If left in a non-visible state
        is_flashing_visible = true;
    }
}

// --- KNOCKBACK HANDLING (New Block - Place this high in the Step Event) ---
if (variable_instance_exists(id, "is_in_knockback") && is_in_knockback) {
    if (knockback_timer > 0) {
        knockback_timer -= 1;

        // Apply knockback movement using your existing collision system
        // We are effectively overriding player input for this frame
        // We'll directly use knockback_hspeed and knockback_vspeed
        // Your scr_player_update_state_and_movement needs to respect these if they are set,
        // OR we apply a simplified move here.
        // For now, let's make scr_player_update_state_and_movement take direct dx, dy.
        // This requires modifying scr_player_update_state_and_movement.

        // --- OPTION 1: Modify scr_player_update_state_and_movement to accept dx, dy ---
        // (See below for how to modify the script)
        // scr_player_update_state_and_movement_with_direct_velocity(knockback_hspeed, knockback_vspeed);

        // --- OPTION 2: Simpler direct move with basic collision (if modifying the script is too much now) ---
        // This is a basic move; your main script is more complex.
        // For a quick test, this can show the push.
        var _kb_dx = knockback_hspeed;
        var _kb_dy = knockback_vspeed;
        
        // Simplified collision for knockback movement (can be improved)
        // Horizontal
        if (tilemap != -1 && place_meeting(x + _kb_dx, y, tilemap)) {
            while(!place_meeting(x + sign(_kb_dx), y, tilemap)) { x += sign(_kb_dx); }
            knockback_hspeed = 0; // Stop horizontal movement on collision
        } else {
            x += _kb_dx;
        }
        // Vertical
        if (tilemap != -1 && place_meeting(x, y + _kb_dy, tilemap)) {
            while(!place_meeting(x, y + sign(_kb_dy), tilemap)) { y += sign(_kb_dy); }
            knockback_vspeed = 0; // Stop vertical movement on collision
            v_speed = 0;          // Also kill any regular falling/rising speed
        } else {
            y += _kb_dy;
        }
        // --- End Option 2 ---

        // Apply friction to the knockback speeds
        knockback_hspeed *= knockback_friction;
        knockback_vspeed *= knockback_friction;

        // If speeds are very low, end knockback early
        if (abs(knockback_hspeed) < 0.1 && abs(knockback_vspeed) < 0.1) {
            knockback_timer = 0;
        }

        if (knockback_timer == 0) {
            is_in_knockback = false;
            knockback_hspeed = 0; // Ensure speeds are zeroed out
            knockback_vspeed = 0;
            // Potentially reset player_state to FLYING if they were knocked into the air
            // if (player_state == PLAYER_STATE.WALKING_FLOOR || player_state == PLAYER_STATE.WALKING_CEILING) {
            //     if (!place_meeting(x, y + 2, tilemap) && !place_meeting(x, y - 2, tilemap)) { // Check if not on ground/ceiling
            //         player_state = PLAYER_STATE.FLYING;
            //     }
            // }
            show_debug_message("Player " + string(id) + " knockback effect ended.");
        }
        
        // IMPORTANT: Skip normal player input and movement logic while being knocked back
        // Update animation based on knockback (optional, e.g., a "hit" sprite)
        // For now, let the existing animation code run, or add specific knockback animation here.
        // Example: sprite_index = spr_player_hit; image_speed = 0; 
        //          if(knockback_hspeed != 0) image_xscale = sign(knockback_hspeed) * original_scale;

        exit; // Exit the Step event to prevent normal movement/input processing
    } else {
        is_in_knockback = false; // Timer ran out, ensure flag is false
        knockback_hspeed = 0;
        knockback_vspeed = 0;
    }
}
// --- END KNOCKBACK HANDLING ---
/// ——— Dive Mode Handler ———
// 1) ——— Dash Mode Handler ———
if (isDashing) {
    // Move
    var move_x = dash_speed * dash_dir;
    var targets = [ tilemap ];
    if (tilemap_phase_id != -1) array_push(targets, tilemap_phase_id);
    array_push(targets, obj_destructible_block, obj_gate);
    move_and_collide(move_x, 0, targets);

    // Force sprite (but don't reset image_index!)
    sprite_index = (dash_dir < 0) 
                 ? spr_player_dash_left 
                 : spr_player_dash_right;
    image_speed = 1;

    // Countdown
    dash_timer -= 1;
    if (dash_timer <= 0) {
        isDashing    = false;
        player_state = PLAYER_STATE.FLYING;
        // back to your normal sprite
        sprite_index = spr_player_walk_right; 
        image_speed  = 0;
        image_index  = 0;
    }

    // IMPORTANT: stop here so we never hit input or other logic
    exit;
}

// 2) ——— Dash Input ———
// Make sure this runs *before* any other exit
var dash_left  = keyboard_check_pressed(ord("Q")) 
              || gamepad_button_check_pressed(0, gp_shoulderl);
var dash_right = keyboard_check_pressed(ord("E")) 
              || gamepad_button_check_pressed(0, gp_shoulderr);
if (!isDiving && !isDashing) {
    if (dash_left)  scr_player_dash(-1);
    else if (dash_right) scr_player_dash(+1);
}

// 3) ——— Dive Mode Handler ———
if (isDiving) {
    v_speed = dive_max_speed;
    var collision_targets = [ tilemap ];
    if (tilemap_phase_id != -1) array_push(collision_targets, tilemap_phase_id);
    array_push(collision_targets, obj_destructible_block);
    var cols = move_and_collide(0, v_speed, collision_targets);

    sprite_index = spr_dive;
    image_speed  = 1;

    if (array_length(cols) > 0 || place_meeting(x, y + 1, tilemap)) {
        isDiving     = false;
        player_state = PLAYER_STATE.FLYING;
        image_speed  = 0;
        image_index  = 0;

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
dir_x = (key_x_keyboard != 0) ? key_x_keyboard : sign(joy_x_gamepad); // Assign to INSTANCE variable

// Vertical Movement Input (Example - adjust to your game's controls)
// This is for direct up/down input. If your flying uses flap and gravity, 
// dir_y might represent an "intent" if you allow moving towards top/bottom edges while flying.
// If your game doesn't have active vertical input for transitions (e.g., only falling off bottom),
// then dir_y might always be 0 unless a specific action sets it for transition.
var key_y_keyboard = keyboard_check(ord("S")) - keyboard_check(ord("W")); // Example: S for down, W for up
var joy_y_gamepad_v = gamepad_axis_value(0, gp_axislv);
if (abs(joy_y_gamepad_v) < 0.25) joy_y_gamepad_v = 0; // Deadzone
dir_y = (key_y_keyboard != 0) ? key_y_keyboard : sign(joy_y_gamepad_v); // Assign to INSTANCE variable

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
    // --- Dive Input (Y key or gamepad Y) ---
var key_dive = keyboard_check_pressed(ord("B"))
             || gamepad_button_check_pressed(0, gp_face2);
if (key_dive && !isDiving) {
    scr_player_dive();
}

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
// Place this ENTIRE block in obj_player :: Step Event.
// It should run AFTER player's x/y for the current step have been determined by movement scripts,
// AND AFTER the instance variables 'dir_x' and 'dir_y' have been updated with current frame's input.

show_debug_message("--- Transition Block START ---");

// Ensure dir_x and dir_y instance variables exist and get their values
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

show_debug_message("  Inputs - HDir: " + string(_current_h_input_dir) + ", VDir: " + string(_current_v_input_dir));
show_debug_message("  Position - X: " + string(x) + ", Y: " + string(y));
show_debug_message("  BBox - L: " + string(bbox_left) + ", R: " + string(bbox_right) + ", T: " + string(bbox_top) + ", B: " + string(bbox_bottom));
show_debug_message("  Room - W: " + string(room_width) + ", H: " + string(room_height));


// --- THIS LINE DECLARES _exit_dir ---
// var _exit_dir = "none"; // This can be removed if the second transition block is gone.
var _exit_margin = 3;
var conn = ds_map_find_value(global.room_map, room);

if (ds_exists(conn, ds_type_map)) {
// LEFT exit
if (bbox_left <= _exit_margin) {
    show_debug_message("LEFT EXIT: Checking room: " + room_get_name(room) + ", bbox_left: " + string(bbox_left));
    if (ds_exists(conn, ds_type_map)) { // conn = ds_map_find_value(global.room_map, room);
        if (ds_map_exists(conn, "left")) {
            var dest = ds_map_find_value(conn, "left");
            var dest_name = (dest == noone) ? "noone" : ((asset_get_type(dest) == asset_room) ? room_get_name(dest) : "INVALID_ASSET_TYPE");
            show_debug_message("LEFT EXIT: 'left' key exists. dest asset: " + string(dest) + " (" + dest_name + ")");

            if (dest != noone && asset_get_type(dest) == asset_room && room_exists(dest)) {
                show_debug_message("LEFT EXIT: Destination is VALID. Transitioning to " + room_get_name(dest));
                global.entry_direction = "none";
                global.next_spawn_object = obj_spawn_point_right;
                room_goto(dest);
                exit;
            } else {
                show_debug_message("LEFT EXIT: Transition FAILED. dest: " + string(dest) + " (" + dest_name + "), asset_type_is_room: " + string(asset_get_type(dest) == asset_room) + ", room_exists(dest): " + string(room_exists(dest)));
                // Player remains in current room. Clamps will apply.
            }
        } else {
            show_debug_message("LEFT EXIT: No 'left' connection in ds_map for " + room_get_name(room));
        }
    } else {
         show_debug_message("LEFT EXIT: Current room " + room_get_name(room) + " not found as key in global.room_map OR its value isn't a map.");
    }
}

    // RIGHT exit
    if (bbox_right >= room_width - _exit_margin) {
        if (ds_map_exists(conn, "right")) {
            var dest = ds_map_find_value(conn, "right");
            if (room_exists(dest)) {
                global.entry_direction = "none"; // PREVENT INTERFERENCE
                global.next_spawn_object = obj_spawn_point_left; // Arriving at new room's LEFT side
                room_goto(dest);
                exit; // Essential
            }
        }
    }

    // ABOVE exit
    if (bbox_top <= _exit_margin) {
        if (ds_map_exists(conn, "above")) {
            var dest = ds_map_find_value(conn, "above");
            if (room_exists(dest)) {
                global.entry_direction = "none"; // PREVENT INTERFERENCE
                global.next_spawn_object = obj_spawn_point_bottom; // Arriving at new room's BOTTOM side
                room_goto(dest);
                exit; // Essential
            }
        }
    }

    // BELOW exit
    if (bbox_bottom >= room_height - _exit_margin) {
        if (ds_map_exists(conn, "below")) {
            var dest = ds_map_find_value(conn, "below");
            if (room_exists(dest)) {
                global.entry_direction = "none"; // PREVENT INTERFERENCE
                global.next_spawn_object = obj_spawn_point_top; // Arriving at new room's TOP side
                room_goto(dest);
                exit; // Essential
            }
        }
    }
}


// --- Fallback: Hard Clamps to Room Edges (Revised) ---
// This logic runs if no room_goto() and exit; was called by the transition logic above it.

var _player_bbox_left = bbox_left;
var _player_bbox_right = bbox_right;
var _player_bbox_top = bbox_top;
var _player_bbox_bottom = bbox_bottom;

// Horizontal Clamping
if (_player_bbox_left < 0) {
    x = x - _player_bbox_left; // Adjust x so bbox_left is 0
} else if (_player_bbox_right > room_width) {
    x = x - (_player_bbox_right - room_width); // Adjust x so bbox_right is room_width
}

// Vertical Clamping (you might want this too, especially if you have vertical movement without defined top/bottom exits)
if (_player_bbox_top < 0) {
    y = y - _player_bbox_top;
} else if (_player_bbox_bottom > room_height) {
    y = y - (_player_bbox_bottom - room_height);
}

show_debug_message("--- Transition Block END (No transition occurred, clamps applied if needed) ---");




// --- Random Encounter ---
// v_speed is an instance variable updated by the movement script
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

// ——— Soft “push out of solid” fallback ———
// If you somehow still end up inside a tile, nudge you 1px up
if ((tilemap != -1 && place_meeting(x, y, tilemap))
 || (tilemap_phase_id != -1 && place_meeting(x, y, tilemap_phase_id)))
{
    // only nudge upward by 1 pixel
    y -= 1;
}






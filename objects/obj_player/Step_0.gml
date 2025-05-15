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
// Place this in obj_player :: Step Event, AFTER input has set instance variables 'dir_x' and 'dir_y'
// AND AFTER your main movement script (e.g., scr_player_update_state_and_movement) has updated x/y.

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

var _exit_margin = 55;      
var _room_edge_buffer = 16; 
var _exit_dir = "none";     

// --- Vertical Out of Bounds (Basic clamp - adjust if needed) ---
var _vertical_oob_buffer = 32; 
if (bbox_bottom > room_height + _vertical_oob_buffer) { 
    y -= (bbox_bottom - (room_height + _vertical_oob_buffer)); 
    if(variable_instance_exists(id,"v_speed")) self.v_speed = 0; 
    show_debug_message("  Clamped at bottom. New Y: " + string(y));
}
if (bbox_top < -_vertical_oob_buffer) { 
    y += (-_vertical_oob_buffer - bbox_top); 
    if(variable_instance_exists(id,"v_speed")) self.v_speed = 0; 
    show_debug_message("  Clamped at top. New Y: " + string(y));
}

// --- Horizontal Room Transition Detection ---
if (_current_h_input_dir < 0 && bbox_left <= _exit_margin) { 
    _exit_dir = "left";
    show_debug_message("  Horizontal Check: Potential LEFT exit. (BboxLeft: " + string(bbox_left) + " <= Margin: " + string(_exit_margin) + ")");
} else if (_current_h_input_dir > 0 && bbox_right >= room_width - _exit_margin) { 
    _exit_dir = "right";
    show_debug_message("  Horizontal Check: Potential RIGHT exit. (BboxRight: " + string(bbox_right) + " >= RoomWidth-Margin: " + string(room_width - _exit_margin) + ")");
}

// --- Vertical Room Transition Detection ---
if (_exit_dir == "none") { // Only check if no horizontal exit was already determined
    if (_current_v_input_dir < 0 && bbox_top <= _exit_margin) { 
        _exit_dir = "above";
        show_debug_message("  Vertical Check: Potential ABOVE exit. (BboxTop: " + string(bbox_top) + " <= Margin: " + string(_exit_margin) + ")");
    } else if (_current_v_input_dir > 0 && bbox_bottom >= room_height - _exit_margin) { 
        _exit_dir = "below";
        show_debug_message("  Vertical Check: Potential BELOW exit. (BboxBottom: " + string(bbox_bottom) + " >= RoomHeight-Margin: " + string(room_height - _exit_margin) + ")");
    }
}

// --- Attempt Room Transition ---
if (_exit_dir != "none") {
    show_debug_message("  Attempting Transition! Direction: " + _exit_dir);

    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        var _connection_map_for_current_room = ds_map_find_value(global.room_map, room);

        if (ds_exists(_connection_map_for_current_room, ds_type_map)) {
            if (ds_map_exists(_connection_map_for_current_room, _exit_dir)) {
                var _destination_room_id = ds_map_find_value(_connection_map_for_current_room, _exit_dir);
                
                show_debug_message("    Connection lookup: CurrentRoomKey=" + string(room) + 
                                   ", ExitDirKey='" + _exit_dir + 
                                   "', FoundDestID_RawValue=" + string(_destination_room_id) +
                                   ", Type of DestID: " + typeof(_destination_room_id));

                if (_destination_room_id != noone && room_exists(_destination_room_id)) {
                    show_debug_message("    Valid connection found: " + _exit_dir + " -> " + room_get_name(_destination_room_id) + " (Asset ID: " + string(_destination_room_id) + ")");
                    global.entry_direction = _exit_dir; 
                    global.original_room = room;   

                    var _spawn_x = x; 
                    var _spawn_y = y; 
                    var _player_current_bbox_left = bbox_left;
                    var _player_current_bbox_top = bbox_top; 
                    var _player_visual_width = bbox_right - _player_current_bbox_left;
                    var _player_visual_height = bbox_bottom - _player_current_bbox_top; 
                    var _offset_origin_to_bbox_left = (x - _player_current_bbox_left);
                    var _offset_origin_to_bbox_top = (y - _player_current_bbox_top); 
                    
                    var _dest_room_info = room_get_info(_destination_room_id);
                    var _dest_room_actual_width = -1;
                    var _dest_room_actual_height = -1;

                    if (is_struct(_dest_room_info)) {
                        if (variable_struct_exists(_dest_room_info, "width")) _dest_room_actual_width = _dest_room_info.width;
                        if (variable_struct_exists(_dest_room_info, "height")) _dest_room_actual_height = _dest_room_info.height;
                        show_debug_message("      Destination Room Info: Width=" + string(_dest_room_actual_width) + ", Height=" + string(_dest_room_actual_height));
                    } else {
                        show_debug_message("      ERROR: room_get_info(" + string(_destination_room_id) + ") did not return a valid struct. Cannot determine destination room dimensions.");
                        _exit_dir = "none"; 
                    }
                    
                    if (_exit_dir != "none") { 
                        switch (_exit_dir) {
                            case "left": 
                                var _target_bbox_left_in_new_room = _dest_room_actual_width - _room_edge_buffer - _player_visual_width;
                                _spawn_x = _target_bbox_left_in_new_room + _offset_origin_to_bbox_left;
                                break;
                            case "right": 
                                var _target_bbox_left_in_new_room = _room_edge_buffer;
                                _spawn_x = _target_bbox_left_in_new_room + _offset_origin_to_bbox_left;
                                break;
                            case "above": 
                                var _target_bbox_top_in_new_room = _dest_room_actual_height - _room_edge_buffer - _player_visual_height;
                                _spawn_y = _target_bbox_top_in_new_room + _offset_origin_to_bbox_top;
                                break;
                            case "below": 
                                var _target_bbox_top_in_new_room = _room_edge_buffer;
                                _spawn_y = _target_bbox_top_in_new_room + _offset_origin_to_bbox_top;
                                break;
                        }
                        global.return_x = _spawn_x;
                        global.return_y = _spawn_y; 
                        
                        show_debug_message("    Transitioning to " + room_get_name(_destination_room_id) + 
                                           ". Player spawn target x=" + string(global.return_x) + ", y=" + string(global.return_y));
                                           
                        room_goto(_destination_room_id);
                        exit; 
                    }
                } else {
                    if (_destination_room_id == noone) { show_debug_message("    No room connection defined for '" + _exit_dir + "' (destination is 'noone'). Player stays."); }
                    else { show_debug_message("    Destination room ID '" + string(_destination_room_id) + "' (for direction '" + _exit_dir + "') does not exist as a valid room. Player stays."); }
                    if (_destination_room_id == noone) _exit_dir = "none"; 
                }
            } else { _exit_dir = "none"; show_debug_message("    Current room's connection map does not have an entry for exit_dir: '" + _exit_dir + "'. Player stays.");}
        } else { _exit_dir = "none"; show_debug_message("    No connection map (or not a map) found in global.room_map for current room ID: " + string(room) + ". Player stays.");}
    } else { _exit_dir = "none"; show_debug_message("    CRITICAL: global.room_map does not exist or is not a ds_map. Player stays. Check obj_init.");}
}

// --- Fallback: Hard Clamps if No Valid Room Transition Occurred ---
if (_exit_dir == "none") {
    var _sprite_x_origin_clamp = sprite_get_xoffset(sprite_index);
    var _sprite_width_clamp = sprite_get_width(sprite_index);
    if (x + (_sprite_width_clamp - _sprite_x_origin_clamp) > room_width) {
        x = room_width - (_sprite_width_clamp - _sprite_x_origin_clamp);
    } else if (x - _sprite_x_origin_clamp < 0) {
        x = _sprite_x_origin_clamp;
    }
    // Add similar vertical clamps if desired using room_height, sprite_get_yoffset, sprite_get_height
}
show_debug_message("--- Transition Block END (ExitDir: " + _exit_dir + ") ---");



// --- Random Encounter ---
// v_speed is an instance variable updated by the movement script
if (dir_x != 0 || v_speed != 0) { // If player intended to move or is moving vertically
    if (!variable_global_exists("encounter_timer")) global.encounter_timer = 0;
    global.encounter_timer++;
}

var encounter_threshold = 300;
var encounter_chance = 15;

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






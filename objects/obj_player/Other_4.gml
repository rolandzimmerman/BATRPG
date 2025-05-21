/// obj_player :: Room Start Event

// This flag is set to true by scr_apply_post_load_state if it handled player's position and state.
var was_loaded_by_system = (variable_global_exists("player_state_loaded_this_frame") && global.player_state_loaded_this_frame == true);

if (was_loaded_by_system) {
    show_debug_message("Player Room Start (SYSTEM LOAD): Position/State handled by scr_apply_post_load_state. Coords: ("
                       + string(x) + "," + string(y) + "). Player State: " + get_player_state_name(player_state) + ", Face Dir: " + string(face_dir));

    global.player_state_loaded_this_frame = false; // Reset the flag

    // Animation setup based on loaded state (already discussed this, ensure it's robust)
    switch (self.player_state) {
        case PLAYER_STATE.FLYING:
            image_speed = 0;
            image_index = 0; // Or a specific frame if your idle flap has one
            sprite_index = (self.face_dir == 1) ? spr_player_walk_right : spr_player_walk_left;
            break;
        case PLAYER_STATE.WALKING_FLOOR:
            image_speed = 0; // Assuming idle on ground is frame 0 of walk anim
            image_index = 0;
            sprite_index = (self.face_dir == 1) ? spr_player_walk_right_ground : spr_player_walk_left_ground;
            break;
        case PLAYER_STATE.WALKING_CEILING:
            image_speed = 0;
            image_index = 0;
            sprite_index = (self.face_dir == 1) ? spr_player_walk_right_ceiling : spr_player_walk_left_ceiling;
            break;
        default:
            show_debug_message("Player Room Start (SYSTEM LOAD): Unknown player_state for animation: " + string(self.player_state));
            sprite_index = spr_player_walk_right; // Fallback sprite
            image_speed = 0;
            image_index = 0;
            break;
    }
    show_debug_message("Player Room Start (SYSTEM LOAD): Animation set. Sprite: " + sprite_get_name(sprite_index));
}
// ----------------------------------------------------------------------------
// Normal transition‐based spawn logic (if not loaded by the system)
// ----------------------------------------------------------------------------
show_debug_message("Player Room Start: Proceeding with normal transition spawn logic for room " 
                   + room_get_name(room));

// Refresh tilemap IDs
var tilemap_col_id = layer_tilemap_get_id(layer_get_id("Tiles_Col"));
var tilemap_phase_id = layer_tilemap_get_id(layer_get_id("Tiles_Phase"));
if (tilemap_col_id == -1) show_debug_message("⚠️ Player Room Start: Tiles_Col layer not found in " + room_get_name(room));
if (tilemap_phase_id == -1) show_debug_message("⚠️ Player Room Start: Tiles_Phase layer not found in " + room_get_name(room));

var _player_positioned = false;

// A) Battle Return
if (variable_global_exists("original_room") && global.original_room == room &&
    variable_global_exists("return_x") && !is_undefined(global.return_x) &&
    variable_global_exists("return_y") && !is_undefined(global.return_y))
{
    show_debug_message("Player Room Start: BATTLE RETURN DETECTED");
    x = global.return_x;
    y = global.return_y;
    show_debug_message("  Positioned at (" + string(x) + "," + string(y) + ")");

    // Clear battle return globals
    global.return_x = undefined;
    global.return_y = undefined;
    global.original_room = undefined;
    global.next_spawn_object = undefined; // Also clear these to prevent conflicts
    global.entry_direction = "none";      // with other spawn logic branches

    _player_positioned = true;
}

// B) In-battle room: bail out (assuming player object might exist but doesn't do spawn logic here)
if (room == rm_battle) { // Make sure rm_battle is the correct asset name
    show_debug_message("Player Room Start: In rm_battle, no spawn logic applied by player instance.");
    exit; // Exit further positioning logic if in battle room
}

// C) If battle return handled it, exit positioning logic
if (_player_positioned) {
    show_debug_message("Player Room Start: Exiting further spawn positioning (battle return handled).");
    // Finalize player state for normal spawn if needed, then exit.
    // Example: face_direction_based_on_entry_if_any();
    exit;
}

// D) Primary transition spawn via next_spawn_object
if (!_player_positioned && variable_global_exists("next_spawn_object") &&
    !is_undefined(global.next_spawn_object) && global.next_spawn_object != noone)
{
    var obj_asset_to_spawn_at = global.next_spawn_object;
    global.next_spawn_object = undefined; // Clear after use
    show_debug_message("Player Room Start (Primary): using next_spawn_object: " + object_get_name(obj_asset_to_spawn_at));

    if (object_exists(obj_asset_to_spawn_at) && instance_number(obj_asset_to_spawn_at) > 0) {
        var sp = instance_find(obj_asset_to_spawn_at, 0);
        x = sp.x; y = sp.y;
        _player_positioned = true;
        show_debug_message("Player Room Start (Primary): SUCCESS at (" 
                           + string(x) + "," + string(y) + ")");
        global.entry_direction = "none"; // Clear if this method was used
    } else {
        show_debug_message("Player Room Start (Primary): Spawn object " + object_get_name(obj_asset_to_spawn_at) + " not found in room.");
    }
}

// E) Fallback via entry_direction
if (!_player_positioned && variable_global_exists("entry_direction") &&
    global.entry_direction != "none" && global.entry_direction != undefined)
{
    var dir = global.entry_direction;
    show_debug_message("Player Room Start (Fallback1): entry_direction = " + dir);
    global.entry_direction = "none"; // Clear after use

    var spawn_obj_for_direction = noone;
    switch (dir) {
        case "left":  spawn_obj_for_direction = obj_spawn_point_left;   break; // Ensure these object names are correct
        case "right": spawn_obj_for_direction = obj_spawn_point_right;  break;
        case "above": spawn_obj_for_direction = obj_spawn_point_top;    break;
        case "below": spawn_obj_for_direction = obj_spawn_point_bottom; break;
    }

    if (spawn_obj_for_direction != noone && object_exists(spawn_obj_for_direction) && instance_number(spawn_obj_for_direction) > 0) {
        var sp2 = instance_find(spawn_obj_for_direction, 0);
        x = sp2.x; y = sp2.y;
        _player_positioned = true;
        show_debug_message("Player Room Start (Fallback1): SUCCESS at (" 
                           + string(x) + "," + string(y) + ")");
    } else {
        show_debug_message("Player Room Start (Fallback1): Spawn object for direction '" + dir + "' (" + (spawn_obj_for_direction != noone ? object_get_name(spawn_obj_for_direction) : "none") +") not found.");
    }
}

// F) Final fallback: default obj_spawn_point
if (!_player_positioned) {
    show_debug_message("Player Room Start (Fallback2): looking for default obj_spawn_point"); // Ensure obj_spawn_point is correct
    if (object_exists(obj_spawn_point) && instance_number(obj_spawn_point) > 0) {
        var sp3 = instance_find(obj_spawn_point, 0);
        x = sp3.x; y = sp3.y;
        _player_positioned = true;
        show_debug_message("Player Room Start (Fallback2): SUCCESS at (" 
                           + string(x) + "," + string(y) + ")");
    } else {
        show_debug_message("Player Room Start (Fallback2): FAILED. No default obj_spawn_point found. Player remains at creation/previous coords.");
    }
}

show_debug_message("Player Room Start: END OF NORMAL SPAWN LOGIC. Final Coords: (" 
                   + string(x) + "," + string(y) + ")");

// Any final setup after normal positioning (e.g., setting facing direction based on entry point)
// self.can_move = true; // Ensure player can move after normal spawn
// self.state = states.idle;
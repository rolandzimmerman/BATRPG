/// obj_player :: Room Start Event

show_debug_message("Player Room Start: ENTERED for room " + room_get_name(room) + ". Initial pos: (" + string(x) + "," + string(y) + ")");

// --- 1. ALWAYS Refresh Collision Tilemap IDs for the Current Room ---
// Assign directly to the instance variables used by your collision logic.
self.tilemap = layer_tilemap_get_id(layer_get_id("Tiles_Col"));
self.tilemap_phase_id = layer_tilemap_get_id(layer_get_id("Tiles_Phase"));

if (self.tilemap == -1) {
    show_debug_message("⚠️ Player Room Start: Instance variable 'tilemap' (for Tiles_Col) NOT found in " + room_get_name(room) + ". Collision may fail.");
} else {
    show_debug_message("Player Room Start: Instance variable 'tilemap' (Tiles_Col) set to ID: " + string(self.tilemap));
}
if (self.tilemap_phase_id == -1) {
    show_debug_message("⚠️ Player Room Start: Instance variable 'tilemap_phase_id' (for Tiles_Phase) NOT found in " + room_get_name(room) + ". Phasing collision may fail.");
} else {
    show_debug_message("Player Room Start: Instance variable 'tilemap_phase_id' (Tiles_Phase) set to ID: " + string(self.tilemap_phase_id));
}

// --- 2. Determine if This Room Entry is from a Game Load ---
var was_loaded_by_system = (variable_global_exists("player_state_loaded_this_frame") && global.player_state_loaded_this_frame == true);

if (was_loaded_by_system) {
    // --- PATH A: Game was Loaded ---
    // Player position and core state (player_state, face_dir) were already set by scr_apply_post_load_state.
    show_debug_message("Player Room Start (SYSTEM LOAD): Position/State was handled by scr_apply_post_load_state. Current Coords: ("
                       + string(x) + "," + string(y) + "). Player State: " + get_player_state_name(player_state) + ", Face Dir: " + string(face_dir));

    global.player_state_loaded_this_frame = false; // Reset the flag, it has served its purpose for this room entry

    // Animation setup based on loaded state
    switch (self.player_state) {
        case PLAYER_STATE.FLYING:
            image_speed = 0;
            image_index = 0;
            sprite_index = (self.face_dir == 1) ? spr_player_walk_right : spr_player_walk_left;
            break;
        case PLAYER_STATE.WALKING_FLOOR:
            image_speed = 0;
            image_index = 0;
            sprite_index = (self.face_dir == 1) ? spr_player_walk_right_ground : spr_player_walk_left_ground;
            break;
        case PLAYER_STATE.WALKING_CEILING:
            image_speed = 0;
            image_index = 0;
            sprite_index = (self.face_dir == 1) ? spr_player_walk_right_ceiling : spr_player_walk_left_ceiling;
            break;
        default:
            show_debug_message("Player Room Start (SYSTEM LOAD): Unknown player_state (" + string(self.player_state) + ") for animation.");
            sprite_index = spr_player_walk_right; // Sensible fallback
            image_speed = 0;
            image_index = 0;
            break;
    }
    show_debug_message("Player Room Start (SYSTEM LOAD): Animation set. Sprite: " + sprite_get_name(sprite_index));

    // Any other specific setup needed only after a system load can go here.

} else {
    // --- PATH B: Normal Room Transition (Not a Game Load) ---
    // This is where your original A-F spawn positioning logic goes.
    show_debug_message("Player Room Start: Proceeding with NORMAL transition spawn logic for room " + room_get_name(room));

    var _player_positioned = false;

    // A) Battle Return
    if (variable_global_exists("original_room") && global.original_room == room &&
        variable_global_exists("return_x") && !is_undefined(global.return_x) &&
        variable_global_exists("return_y") && !is_undefined(global.return_y))
    {
        show_debug_message("Player Room Start (Normal): BATTLE RETURN DETECTED");
        x = global.return_x;
        y = global.return_y;
        show_debug_message("  Positioned at (" + string(x) + "," + string(y) + ")");

        global.return_x = undefined;
        global.return_y = undefined;
        global.original_room = undefined;
        global.next_spawn_object = undefined;
        global.entry_direction = "none";
        _player_positioned = true;
    }

    // B) In-battle room: Player positioning is likely handled by a battle manager, or player is static
    if (room == rm_battle) { // Make sure rm_battle is the correct asset name
        show_debug_message("Player Room Start (Normal): In rm_battle. No further spawn logic by obj_player.");
        // Common final setup (section 3) will still run unless you 'exit' here.
        // If player should do nothing else in rm_battle's Room Start, uncomment:
        // exit; 
    }

    // C) If battle return OR already in battle room handled positioning/logic, skip further positioning attempts
    // This check ensures D, E, F don't run if A or B already determined the outcome/position.
    if (_player_positioned || room == rm_battle) {
        show_debug_message("Player Room Start (Normal): Exiting further spawn positioning attempts (handled by battle return or being in battle room).");
    } else {
        // D) Primary transition spawn via next_spawn_object
        if (variable_global_exists("next_spawn_object") && !is_undefined(global.next_spawn_object) && global.next_spawn_object != noone) {
            var obj_asset_to_spawn_at = global.next_spawn_object;
            global.next_spawn_object = undefined; // Clear after use
            show_debug_message("Player Room Start (Normal - Primary): using next_spawn_object: " + object_get_name(obj_asset_to_spawn_at));
            if (object_exists(obj_asset_to_spawn_at) && instance_number(obj_asset_to_spawn_at) > 0) {
                var sp = instance_find(obj_asset_to_spawn_at, 0);
                x = sp.x; y = sp.y;
                _player_positioned = true;
                show_debug_message("Player Room Start (Normal - Primary): SUCCESS at (" + string(x) + "," + string(y) + ")");
                global.entry_direction = "none"; // Clear if this method was used
            } else {
                show_debug_message("Player Room Start (Normal - Primary): Spawn object " + object_get_name(obj_asset_to_spawn_at) + " not found in room.");
            }
        }

        // E) Fallback via entry_direction
        if (!_player_positioned && variable_global_exists("entry_direction") && global.entry_direction != "none" && global.entry_direction != undefined) {
            var dir = global.entry_direction;
            show_debug_message("Player Room Start (Normal - Fallback1): entry_direction = " + dir);
            global.entry_direction = "none"; // Clear after use
            var spawn_obj_for_direction = noone;
            switch (dir) {
                case "left":  spawn_obj_for_direction = obj_spawn_point_left;   break;
                case "right": spawn_obj_for_direction = obj_spawn_point_right;  break;
                case "above": spawn_obj_for_direction = obj_spawn_point_top;    break;
                case "below": spawn_obj_for_direction = obj_spawn_point_bottom; break;
            }
            if (spawn_obj_for_direction != noone && object_exists(spawn_obj_for_direction) && instance_number(spawn_obj_for_direction) > 0) {
                var sp2 = instance_find(spawn_obj_for_direction, 0);
                x = sp2.x; y = sp2.y;
                _player_positioned = true;
                show_debug_message("Player Room Start (Normal - Fallback1): SUCCESS at (" + string(x) + "," + string(y) + ")");
            } else {
                show_debug_message("Player Room Start (Normal - Fallback1): Spawn object for direction '" + dir + "' (" + (spawn_obj_for_direction != noone ? object_get_name(spawn_obj_for_direction) : "none") +") not found.");
            }
        }

        // F) Final fallback: default obj_spawn_point
        if (!_player_positioned) {
            show_debug_message("Player Room Start (Normal - Fallback2): looking for default obj_spawn_point");
            if (object_exists(obj_spawn_point) && instance_number(obj_spawn_point) > 0) {
                var sp3 = instance_find(obj_spawn_point, 0);
                x = sp3.x; y = sp3.y;
                _player_positioned = true; // Mark as positioned
                show_debug_message("Player Room Start (Normal - Fallback2): SUCCESS at (" + string(x) + "," + string(y) + ")");
            } else {
                show_debug_message("Player Room Start (Normal - Fallback2): FAILED. No default obj_spawn_point found. Player remains at instance creation/previous coords.");
            }
        }
    } // End of "else not _player_positioned and not rm_battle" for D, E, F logic

    show_debug_message("Player Room Start (Normal): END OF NORMAL SPAWN POSITIONING LOGIC. Final Coords: (" + string(x) + "," + string(y) + ")");

} // End of "else not was_loaded_by_system"

// --- 3. Common Final Setup (Runs after either PATH A or PATH B determined position/state) ---
// This is a good place for logic that must happen every time the player starts in a room,
// AFTER its position and state have been determined.
// For example, if you have a function to update which sprite to use based on current state and direction,
// or to ensure input flags are correctly set for gameplay.
// self.can_process_input = true; // (If you use such a variable)
// update_player_visuals(); // Example call to a script that finalizes sprite, image_speed etc. if needed

show_debug_message("Player Room Start: EXITING EVENT. Final pos: (" + string(x) + "," + string(y) + "), TilemapID: " + string(self.tilemap) + ", PhaseID: " + string(self.tilemap_phase_id));
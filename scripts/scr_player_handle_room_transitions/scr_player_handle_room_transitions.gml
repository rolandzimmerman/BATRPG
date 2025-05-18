// Ensure dir_x and dir_y instance variables exist (or are passed if needed, but usually instance vars are fine)
// var _current_h_input_dir = self.dir_x; // If dir_x is an instance variable
// var _current_v_input_dir = self.dir_y; // If dir_y is an instance variable
// This script doesn't seem to use _current_h_input_dir or _current_v_input_dir from your original snippet,
// the transitions are purely bbox based.

var _exit_margin = 3; // Make this an instance variable 'self.exit_trigger_margin' or pass as argument for flexibility
var _conn = ds_map_find_value(global.room_map, room); // Assuming global.room_map is set up

if (ds_exists(_conn, ds_type_map)) {
    // LEFT exit
    if (bbox_left <= _exit_margin) {
        if (ds_map_exists(_conn, "left")) {
            var _dest = ds_map_find_value(_conn, "left");
            if (_dest != noone && asset_get_type(_dest) == asset_room && room_exists(_dest)) {
                show_debug_message("Player Transition: Valid LEFT exit to " + room_get_name(_dest));
                global.entry_direction = "none"; // This might need to be "right" for the next room
                global.next_spawn_object = obj_spawn_point_right;
                room_goto(_dest);
                return true; // Transition occurred
            } // else: log failure
        } // else: log no left connection
    }

    // RIGHT exit
    if (bbox_right >= room_width - _exit_margin) {
        if (ds_map_exists(_conn, "right")) {
            var _dest = ds_map_find_value(_conn, "right");
            if (room_exists(_dest)) {
                show_debug_message("Player Transition: Valid RIGHT exit to " + room_get_name(_dest));
                global.entry_direction = "none"; // This might need to be "left"
                global.next_spawn_object = obj_spawn_point_left; 
                room_goto(_dest);
                return true; // Transition occurred
            }
        }
    }

    // ABOVE exit
    if (bbox_top <= _exit_margin) {
        if (ds_map_exists(_conn, "above")) {
            var _dest = ds_map_find_value(_conn, "above");
            if (room_exists(_dest)) {
                show_debug_message("Player Transition: Valid ABOVE exit to " + room_get_name(_dest));
                global.entry_direction = "none"; // This might need to be "below"
                global.next_spawn_object = obj_spawn_point_bottom; 
                room_goto(_dest);
                return true; // Transition occurred
            }
        }
    }

    // BELOW exit
    if (bbox_bottom >= room_height - _exit_margin) {
        if (ds_map_exists(_conn, "below")) {
            var _dest = ds_map_find_value(_conn, "below");
            if (room_exists(_dest)) {
                show_debug_message("Player Transition: Valid BELOW exit to " + room_get_name(_dest));
                global.entry_direction = "none"; // This might need to be "above"
                global.next_spawn_object = obj_spawn_point_top;
                room_goto(_dest);
                return true; // Transition occurred
            }
        }
    }
} // else: log current room not in ds_map

// --- Fallback: Hard Clamps to Room Edges (Revised) ---
// This logic runs if no room_goto() was called.
var _clamp_applied = false;
if (bbox_left < 0) { x = x - bbox_left; _clamp_applied = true; }
else if (bbox_right > room_width) { x = x - (bbox_right - room_width); _clamp_applied = true; }

if (bbox_top < 0) { y = y - bbox_top; _clamp_applied = true; }
else if (bbox_bottom > room_height) { y = y - (bbox_bottom - room_height); _clamp_applied = true; }

// if (_clamp_applied) show_debug_message("Player Transition: Clamped to room edges.");

return false; // No transition occurred
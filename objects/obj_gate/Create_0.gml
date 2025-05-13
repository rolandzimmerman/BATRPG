/// obj_gate :: Create Event

// group_id MUST be set per-instance in the Room Editor.
if (!variable_instance_exists(id, "group_id")) {
    group_id = -1; 
    show_debug_message("CRITICAL WARNING: obj_gate (ID: " + string(id) + ") is MISSING a 'group_id' in its Creation Code. Defaulting to -1. Persistence and response to switches will likely fail for this instance.");
} else {
    show_debug_message("obj_gate (ID: " + string(id) + ") initialized with group_id: " + string(group_id));
}

// Default initial state (closed)
opened = false;
opening = false;
sprite_index = spr_gate_closed; 
image_speed = 0;
image_index = 0; 
mask_index = sprite_index; 
solid = true;

// Check persistent state based on its group_id
if (group_id != -1) { // Only proceed if group_id is valid
    if (variable_global_exists("gate_states_map")) {
        if (ds_exists(global.gate_states_map, ds_type_map)) {
            if (ds_map_exists(global.gate_states_map, group_id)) {
                var _is_activated_from_map = global.gate_states_map[? group_id];
                show_debug_message("Gate (ID: " + string(id) + ", Group: " + string(group_id) + ") - Found group in map. Saved state for group: " + string(_is_activated_from_map));
                if (_is_activated_from_map == true) {
                    opened = true;
                    opening = false;
                    sprite_index = spr_gate_open;
                    image_index = 0; 
                    image_speed = 0;
                    mask_index = -1; 
                    solid = false;
                    show_debug_message("Gate (ID: " + string(id) + ", Group: " + string(group_id) + ") - Initializing as OPEN based on saved group state.");
                } else {
                    show_debug_message("Gate (ID: " + string(id) + ", Group: " + string(group_id) + ") - Group state in map is not 'true'. Initializing as CLOSED.");
                }
            } else {
                show_debug_message("Gate (ID: " + string(id) + ", Group: " + string(group_id) + ") - Group ID not found in gate_states_map. Initializing as CLOSED.");
                // global.gate_states_map[? group_id] = false; // Initialize as explicitly false
            }
        } else {
            show_debug_message("CRITICAL ERROR: global.gate_states_map exists but is NOT A DS_MAP for Gate (ID: " + string(id) + ", Group: " + string(group_id) + "). Persistence WILL FAIL.");
        }
    } else {
        show_debug_message("CRITICAL ERROR: global.gate_states_map DOES NOT EXIST for Gate (ID: " + string(id) + ", Group: " + string(group_id) + "). Persistence WILL FAIL. Ensure it's created at game start.");
    }
} else {
    show_debug_message("Gate (ID: " + string(id) + ") has an invalid group_id (-1). Persistence check skipped. Gate will start CLOSED.");
}
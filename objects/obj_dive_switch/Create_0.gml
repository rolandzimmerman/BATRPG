/// obj_dive_switch :: Create Event

// group_id MUST be set per-instance in the Room Editor.
if (!variable_instance_exists(id, "group_id")) {
    group_id = -1; 
    show_debug_message("CRITICAL WARNING: obj_dive_switch (ID: " + string(id) + ") is MISSING a 'group_id' in its Creation Code. Defaulting to -1. Persistence and gate operation will likely fail for this instance.");
} else {
    show_debug_message("obj_dive_switch (ID: " + string(id) + ") initialized with group_id: " + string(group_id));
}

activated = false;
sprite_index = spr_switch_off;
mask_index = sprite_index; 
solid = false; 

// Check persistent state for this switch's group
if (group_id != -1) { // Only proceed if group_id is valid
    if (variable_global_exists("gate_states_map")) {
        if (ds_exists(global.gate_states_map, ds_type_map)) {
            if (ds_map_exists(global.gate_states_map, group_id)) {
                var _is_activated_from_map = global.gate_states_map[? group_id];
                show_debug_message("Switch (ID: " + string(id) + ", Group: " + string(group_id) + ") - Found group in map. Saved state: " + string(_is_activated_from_map));
                if (_is_activated_from_map == true) {
                    activated = true;
                    sprite_index = spr_switch_on;
                    show_debug_message("Switch (ID: " + string(id) + ", Group: " + string(group_id) + ") - Initializing as ON based on saved state.");
                } else {
                    show_debug_message("Switch (ID: " + string(id) + ", Group: " + string(group_id) + ") - State in map is not 'true'. Initializing as OFF.");
                }
            } else {
                show_debug_message("Switch (ID: " + string(id) + ", Group: " + string(group_id) + ") - Group ID not found in gate_states_map. Initializing as OFF.");
                // Optional: Initialize this group_id to false if you want every encountered group_id to have an entry
                // global.gate_states_map[? group_id] = false; 
            }
        } else {
            show_debug_message("CRITICAL ERROR: global.gate_states_map exists but is NOT A DS_MAP for Switch (ID: " + string(id) + ", Group: " + string(group_id) + "). Persistence WILL FAIL.");
        }
    } else {
        show_debug_message("CRITICAL ERROR: global.gate_states_map DOES NOT EXIST for Switch (ID: " + string(id) + ", Group: " + string(group_id) + "). Persistence WILL FAIL. Ensure it's created at game start.");
    }
} else {
    show_debug_message("Switch (ID: " + string(id) + ") has an invalid group_id (-1). Persistence check skipped. Switch will start OFF.");
}
/// obj_dive_switch :: Step Event

if (!activated) { // Only attempt to activate if not already set to 'on'
    var p = instance_place(x, y, obj_player);
    // Ensure 'p' exists and has 'isDiving' before accessing it
    if (p != noone && variable_instance_exists(p, "isDiving") && p.isDiving) {
        
        show_debug_message("Dive Switch (Group ID: " + string(group_id) + ", Instance: " + string(id) + ") activated by player!");
        activated = true;
        sprite_index = spr_switch_on;
        
        if (audio_exists(snd_sfx_switch)) {
            audio_play_sound(snd_sfx_switch, 1, 0);
        } else {
            show_debug_message("WARNING: snd_sfx_switch sound asset not found.");
        }

        // Stop the player’s dive
        with (p) {
            isDiving = false;
            // Ensure PLAYER_STATE and its members are defined and accessible
            if (variable_global_exists("PLAYER_STATE") && is_struct(global.PLAYER_STATE) && variable_struct_exists(global.PLAYER_STATE, "WALKING_FLOOR")) {
                player_state = global.PLAYER_STATE.WALKING_FLOOR;
            } else {
                player_state = 0; // Fallback if PLAYER_STATE enum is not set up as expected
                show_debug_message("WARNING: PLAYER_STATE.WALKING_FLOOR not defined as expected. Player state set to fallback.");
            }
            v_speed = 0;
        }

        // Update persistent state for this group if group_id is valid
        if (group_id != -1 && variable_global_exists("gate_states_map") && ds_exists(global.gate_states_map, ds_type_map)) {
            global.gate_states_map[? group_id] = true; // Mark this group as activated
            show_debug_message("Group ID: " + string(group_id) + " state saved as 'activated (true)' in global.gate_states_map.");
        } else if (group_id == -1) {
            show_debug_message("WARNING: Switch (Instance: " + string(id) + ") activated but has an invalid group_id (-1). Cannot save persistent state.");
        } else {
            show_debug_message("WARNING: Switch (Group ID: " + string(group_id) + ") activated but global.gate_states_map not found. Cannot save persistent state.");
        }

        // Trigger gates with the same group_id
        var gates_triggered_count = 0;
        with (obj_gate) {
            // Ensure the gate instance also has a group_id variable set
            if (variable_instance_exists(id, "group_id") && self.group_id == other.group_id) {
                show_debug_message("Switch (Group: " + string(other.group_id) + ") triggering User Event 0 for Gate (Instance: " + string(id) + ", Group: " + string(self.group_id) + ")");
                event_perform(ev_other, ev_user0); // This calls obj_gate's User Event 0
                gates_triggered_count++;
            }
        }
        if (gates_triggered_count == 0 && group_id != -1) {
            show_debug_message("Switch (Group ID: " + string(group_id) + ") activated, but no obj_gate instances found with a matching group_id.");
        }
    }
}
// If 'activated' is already true (from Create event or previous Step), this block is skipped,
// and the switch remains in its 'on' state.
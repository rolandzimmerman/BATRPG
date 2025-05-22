/// @function apply_npc_states(npc_data_struct)
/// @description Applies saved states to NPC instances in the current room.
/// @param npc_data_struct {struct} The struct containing NPC data, where keys are unique_npc_id.
function apply_npc_states(npc_data_struct) {
    if (!is_struct(npc_data_struct)) {
        show_debug_message("[ApplyNPCs] Error: npc_data_struct is not a valid struct.");
        return;
    }
    show_debug_message("[ApplyNPCs] Applying NPC states: " + string(npc_data_struct));

    // Get all the keys (unique IDs) in that struct
    var uids = variable_struct_get_names(npc_data_struct);

    for (var i = 0; i < array_length(uids); i++) {
        var uid = uids[i];
        // Safely pull the saved state struct
        var saved = variable_struct_get(npc_data_struct, uid);
        if (!is_struct(saved)) {
            show_debug_message("[ApplyNPCs] Skipping non-struct for UID " + uid);
            continue;
        }

        show_debug_message("[ApplyNPCs] Restoring UID " + uid + ": " + string(saved));

        // Find the instance with that unique_npc_id
        var inst = noone;
        with (obj_npc_parent) {
            if (variable_instance_exists(id, "unique_npc_id") &&
                string(unique_npc_id) == uid)
            {
                inst = id;
                break;
            }
        }

        if (instance_exists(inst)) {
            // Pull fields out of the saved struct
            var sx = variable_struct_exists(saved, "x")             ? variable_struct_get(saved, "x")             : inst.x;
            var sy = variable_struct_exists(saved, "y")             ? variable_struct_get(saved, "y")             : inst.y;
            var sv = variable_struct_exists(saved, "visible")       ? variable_struct_get(saved, "visible")       : inst.visible;
            var sp = variable_struct_exists(saved, "has_spoken_to") ? variable_struct_get(saved, "has_spoken_to") : inst.has_spoken_to;

            inst.x             = sx;
            inst.y             = sy;
            inst.visible       = sv;
            inst.has_spoken_to = sp;

            show_debug_message("[ApplyNPCs] Applied to instance " + string(inst) +
                               " → x:" + string(sx) +
                               " y:" + string(sy) +
                               " vis:" + string(sv) +
                               " spoken:" + string(sp));
        } else {
            show_debug_message("[ApplyNPCs] No instance found for UID " + uid);
        }
    }
    show_debug_message("[ApplyNPCs] Done.");
}

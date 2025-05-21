/// @function apply_npc_states(npc_data_struct)
/// @description Applies saved states to NPC instances in the current room.
/// @param npc_data_struct {struct} The struct containing NPC data, where keys are unique_npc_id.
function apply_npc_states(npc_data_struct) {
    if (!is_struct(npc_data_struct)) {
        show_debug_message("[ApplyNPCs] Error: npc_data_struct is not a valid struct.");
        return;
    }

    show_debug_message("[ApplyNPCs] Attempting to apply NPC states. Data: " + string(npc_data_struct));

    var npc_unique_ids_to_load = variable_struct_get_names(npc_data_struct);

    for (var i = 0; i < array_length(npc_unique_ids_to_load); i++) {
        var unique_id_to_find = npc_unique_ids_to_load[i];
        var saved_npc_state = npc_data_struct[$ unique_id_to_find];

        if (!is_struct(saved_npc_state)) {
            show_debug_message("[ApplyNPCs] Warning: Saved state for unique_id '" + unique_id_to_find + "' is not a struct. Skipping.");
            continue;
        }

        show_debug_message("[ApplyNPCs] Processing NPC with unique_id: " + unique_id_to_find);

        var npc_instance_in_room = noone;
        // Find the NPC instance in the current room that has this unique_npc_id
        // Make sure your NPCs that should be loaded have a 'unique_npc_id' variable!
        // And that they inherit from obj_npc_parent (or whatever parent object you use for NPCs).
        with (obj_npc_parent) { // Or your common NPC parent object
            if (variable_instance_exists(id, "unique_npc_id") && self.unique_npc_id == unique_id_to_find) {
                npc_instance_in_room = id;
                break; // Found the NPC instance
            }
        }

        if (instance_exists(npc_instance_in_room)) {
            show_debug_message("[ApplyNPCs] Found instance " + string(npc_instance_in_room) + " for unique_id '" + unique_id_to_find + "'. Applying state.");
            npc_instance_in_room.x = saved_npc_state.x;
            npc_instance_in_room.y = saved_npc_state.y;
            npc_instance_in_room.visible = saved_npc_state.visible;

            if (variable_struct_exists(saved_npc_state, "has_spoken_to")) {
                // Ensure the variable exists on the instance before setting
                if (!variable_instance_exists(npc_instance_in_room.id, "has_spoken_to")) {
                     variable_instance_set(npc_instance_in_room.id, "has_spoken_to", false); // Initialize if missing
                }
                npc_instance_in_room.has_spoken_to = saved_npc_state.has_spoken_to;
                show_debug_message("  -> Restored has_spoken_to: " + string(npc_instance_in_room.has_spoken_to));
            }
             show_debug_message("  -> Restored x: " + string(npc_instance_in_room.x) + ", y: " + string(npc_instance_in_room.y) + ", visible: " + string(npc_instance_in_room.visible));
        } else {
            show_debug_message("[ApplyNPCs] Warning: Could not find NPC instance in current room with unique_id: " + unique_id_to_find);
            // Optional: Handle creating this NPC if it was saved but not found in the room,
            // if your game design requires that. For now, it just logs a warning.
        }
    }
    show_debug_message("[ApplyNPCs] Finished applying NPC states.");
}
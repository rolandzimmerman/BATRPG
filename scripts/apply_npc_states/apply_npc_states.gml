/// @function apply_npc_states(saved_npcs_data)
/// @description Applies saved states to NPCs in the current room.
///              Hides or destroys room NPCs not found in save data.
/// @param {Struct} saved_npcs_data A struct where keys are unique_npc_ids
///                                and values are structs of NPC properties.
function apply_npc_states(saved_npcs_data) {
    show_debug_message("[ApplyNPCs] Applying NPC states. Saved NPC UIDs: " + string(variable_struct_get_names(saved_npcs_data)));

    // Step 1: Create a temporary map of all relevant NPC instances currently in the room,
    // keyed by their unique_npc_id.
    var room_npcs_map = ds_map_create();
    with (obj_npc_parent) { // Or your specific NPC parent object
        if (variable_instance_exists(id, "unique_npc_id") && unique_npc_id != "") {
            if (!ds_map_exists(room_npcs_map, unique_npc_id)) {
                ds_map_add(room_npcs_map, unique_npc_id, id); // Store instance ID
            } else {
                // This means you have duplicate unique_npc_ids in the room before loading! This is a problem.
                //show_debug_message("[ApplyNPCs] CRITICAL WARNING: Duplicate unique_npc_id '" + unique_npc_id + "' found in room for instance " + string(id) + " and " + string(ds_map_find_value(room_npcs_map, unique_npc_id)) + ". This will cause issues.");
                // To prevent a crash, you might only store the first one, but the root issue needs fixing.
            }
        } else {
            // This NPC instance doesn't have a valid unique_npc_id, so it can't be matched with save data.
            // Decide what to do: hide it, destroy it, or ignore it. For now, let's mark it for hiding/destruction.
            // Adding it with a special key or to a separate list might be better.
            // For simplicity here, we'll handle it in Step 3 if it's not updated.
             show_debug_message("[ApplyNPCs] Note: NPC instance " + string(id) + " has no valid unique_npc_id. It won't be updated from save.");
        }
    }
    show_debug_message("[ApplyNPCs] Found " + string(ds_map_size(room_npcs_map)) + " uniquely identifiable NPCs in the current room.");

    // Step 2: Iterate through the saved NPC data.
    var saved_npc_uids = variable_struct_get_names(saved_npcs_data);
    for (var i = 0; i < array_length(saved_npc_uids); i++) {
        var current_uid = saved_npc_uids[i];
        var npc_props = variable_struct_get(saved_npcs_data, current_uid); // Struct of saved properties {x, y, visible, ...}

        var instance_to_update = ds_map_find_value(room_npcs_map, current_uid);

        if (instance_exists(instance_to_update)) {
            // Found an existing NPC in the room with this UID. Update it.
            show_debug_message("[ApplyNPCs] Updating existing NPC instance " + string(instance_to_update) + " (UID: " + current_uid + ")");
            with (instance_to_update) {
                if (variable_struct_exists(npc_props, "x")) x = npc_props.x;
                if (variable_struct_exists(npc_props, "y")) y = npc_props.y;
                if (variable_struct_exists(npc_props, "visible")) visible = npc_props.visible; else visible = true; // Default to visible if not specified
                if (variable_struct_exists(npc_props, "has_spoken_to")) has_spoken_to = npc_props.has_spoken_to;
                // Apply other saved properties here
            }
            // Remove this NPC from the room_npcs_map, as it has been accounted for.
            ds_map_delete(room_npcs_map, current_uid);
        } else {
            // This NPC is in the save file but not currently in the room with a matching UID.
            // This scenario is complex:
            // - Was it in a different room and shouldn't be created here?
            // - Was it destroyed by game logic and shouldn't reappear?
            // - Does it need to be dynamically created? If so, you need to know its object_index.
            // For now, we'll assume NPCs are placed in rooms and we only update existing ones.
            show_debug_message("[ApplyNPCs] WARNING: NPC with UID '" + current_uid + "' found in save data, but no matching instance found in the current room.");
            // If you have a system to spawn NPCs by UID and object type, you could do it here.
            // e.g., var obj_type = get_npc_object_type_by_uid(current_uid);
            // if (obj_type != noone) { var new_npc = instance_create_layer(npc_props.x, npc_props.y, "Instances", obj_type); ... apply props ... }
        }
    }

    // Step 3: Any NPCs remaining in room_npcs_map were present in the room but NOT in the save data.
    var remaining_room_npc_keys = ds_map_keys_to_array(room_npcs_map);
    if (array_length(remaining_room_npc_keys) > 0) {
        //show_debug_message("[ApplyNPCs] Processing " + string(array_length(remaining_room_npc_keys)) + " NPCs found in room but not in current save data's NPC list for this location.");
        for (var i = 0; i < array_length(remaining_room_npc_keys); i++) {
            var uid_to_remove = remaining_room_npc_keys[i];
            
            // ***** THIS LINE WAS LIKELY MISSING OR COMMENTED OUT *****
            var instance_to_remove = ds_map_find_value(room_npcs_map, uid_to_remove); 
            // **********************************************************

            // Now the 'if (instance_exists(instance_to_remove))' check will have a defined variable
            if (instance_exists(instance_to_remove)) { // This was your line 71
                //show_debug_message("[ApplyNPCs] DEBUG: Would remove/hide unmatched room NPC instance " + string(instance_to_remove) + " (UID: " + uid_to_remove + "). Temporarily leaving it alone.");
                // instance_destroy(instance_to_remove); // Still commented for your test
                // instance_to_remove.visible = false;    // Still commented for your test
            } else {
                 //show_debug_message("[ApplyNPCs] DEBUG: Instance for UID '" + uid_to_remove + "' (which was in room_npcs_map but not save data) no longer exists.");
            }
        }
    }

    ds_map_destroy(room_npcs_map); // Clean up the temporary map
    show_debug_message("[ApplyNPCs] Done applying NPC states.");
}

// Helper (if you need to spawn NPCs dynamically and store their object type)
/*
function get_npc_object_type_by_uid(uid) {
    // This function would need to map UIDs to actual GameMaker object assets.
    // Example:
    // switch (uid) {
    //    case "shopkeeper_town1": return obj_npc_shopkeeper;
    //    case "questgiver_forest": return obj_npc_quest_for_item;
    // }
    // return noone;
}
*/
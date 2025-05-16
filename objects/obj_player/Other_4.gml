/// obj_player :: Room Start Event

// 0) Refresh collision layers (Your existing code is fine)
tilemap = layer_tilemap_get_id(layer_get_id("Tiles_Col"));
tilemap_phase_id = layer_tilemap_get_id(layer_get_id("Tiles_Phase"));
if (tilemap == -1) show_debug_message("⚠️ Player RoomStart: Tiles_Col layer not found in " + room_get_name(room));
if (tilemap_phase_id == -1) show_debug_message("⚠️ Player RoomStart: Tiles_Phase layer not found in " + room_get_name(room));

// Check if position was already handled by Game Manager's battle return logic
if (variable_global_exists("player_position_handled_by_battle_return") && global.player_position_handled_by_battle_return == true) {
    show_debug_message("Player Room Start: Position already handled by battle return. Skipping normal spawn logic.");
    global.player_position_handled_by_battle_return = false; // Consume/reset the flag
    exit; // IMPORTANT: Skip the rest of this event's spawn logic
}

// If we’re in the battle room, skip spawn-point logic entirely
if (room == rm_battle) {
    exit;
}

// 1. PRIMARY SPAWN METHOD for transitions: Use global.next_spawn_object
if (variable_global_exists("next_spawn_object") && !is_undefined(global.next_spawn_object) && global.next_spawn_object != noone) {
    var spawn_object_asset = global.next_spawn_object;
    global.next_spawn_object = undefined; // Consume immediately

    if (object_exists(spawn_object_asset)) {
        var sp = instance_find(spawn_object_asset, 0); // Find the first instance of this specific object type
        if (instance_exists(sp)) {
            x = sp.x;
            y = sp.y;
            show_debug_message("Player Room Start: Spawned via next_spawn_object (" + object_get_name(spawn_object_asset) + ") at (" + string(x) + "," + string(y) + ")");
            // Crucial: If successful, no other spawn logic in THIS SCRIPT should run.
            // Also, ensure global.entry_direction is clean for other systems if they run after.
            if (variable_global_exists("entry_direction")) {
                global.entry_direction = "none";
            }
            exit; // Successfully positioned, exit Player Room Start event.
        } else {
            show_debug_message("Player Room Start WARNING: next_spawn_object (" + object_get_name(spawn_object_asset) + ") was set, but no instance found in room " + room_get_name(room) + ". Proceeding to fallbacks.");
        }
    } else {
        show_debug_message("Player Room Start ERROR: next_spawn_object (" + string(spawn_object_asset) + ") is not a valid object index. Proceeding to fallbacks.");
    }
}

// 2. FALLBACK SPAWN METHOD: Use global.entry_direction (if player step didn't clear it or it was set by another system)
// This block is reached ONLY IF global.next_spawn_object was not set, or it was set to an invalid/missing object.
if (variable_global_exists("entry_direction") && global.entry_direction != "none") {
    var entry_dir_value = global.entry_direction; // Store before consuming
    show_debug_message("Player Room Start: next_spawn_object failed or not set. Trying entry_direction: " + entry_dir_value);
    global.entry_direction = "none"; // Consume

    var target_spawn_object_type = noone;
    var used_entry_direction = entry_dir_value; // For debug message

    // This logic assumes global.entry_direction refers to THE SIDE THE PLAYER IS ON,
    // or the side of the spawn point object, not the direction of entry *into* the room.
    // Your existing switch cases look like: "left" means use obj_spawn_point_left.
    switch (entry_dir_value) {
        case "left":  target_spawn_object_type = obj_spawn_point_left;   break;
        case "right": target_spawn_object_type = obj_spawn_point_right;  break;
        case "above": target_spawn_object_type = obj_spawn_point_top;    break;
        case "below": target_spawn_object_type = obj_spawn_point_bottom; break;
        default:
            show_debug_message("Player Room Start: Unrecognized entry_direction value: " + entry_dir_value);
            used_entry_direction = "none (invalid original value)";
    }

    if (target_spawn_object_type != noone && object_exists(target_spawn_object_type)) {
        var sp_dir = instance_find(target_spawn_object_type, 0);
        if (instance_exists(sp_dir)) {
            x = sp_dir.x;
            y = sp_dir.y;
            show_debug_message("Player Room Start: Spawned via entry_direction ('" + used_entry_direction + "' -> " + object_get_name(target_spawn_object_type) + ") at (" + string(x) + "," + string(y) + ")");
            exit; // Successfully positioned, exit Player Room Start event.
        } else {
            show_debug_message("Player Room Start WARNING: entry_direction ('" + used_entry_direction + "') intended " + object_get_name(target_spawn_object_type) + " but no instance found.");
        }
    }
}

// 3. FINAL FALLBACK in Player Room Start: Use a generic default spawn object if all else fails
// (This uses obj_spawn_point, your general default, NOT obj_player_spawn_point_save which is in Create)
show_debug_message("Player Room Start: All prior spawn methods failed. Looking for default obj_spawn_point.");
if (object_exists(obj_spawn_point)) {
    var D = instance_find(obj_spawn_point, 0);
    if (instance_exists(D)) {
        x = D.x;
        y = D.y;
        show_debug_message("Player Room Start: Spawned at default obj_spawn_point (" + string(x) + "," + string(y) + ")");
    } else {
        show_debug_message("Player Room Start ⚠️: obj_spawn_point (generic default) asset exists, but no instances found in " + room_get_name(room) + ". Player position unchanged by this fallback.");
    }
} else {
    show_debug_message("Player Room Start ⚠️: No obj_spawn_point asset in project for default spawn. Player position unchanged by this fallback.");
}
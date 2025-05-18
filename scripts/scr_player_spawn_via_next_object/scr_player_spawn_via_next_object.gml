// 1. PRIMARY SPAWN METHOD for transitions: Use global.next_spawn_object
if (variable_global_exists("next_spawn_object") && !is_undefined(global.next_spawn_object) && global.next_spawn_object != noone) {
    var spawn_object_asset = global.next_spawn_object;
    // (Keep your detailed logging for this block as refined in previous response)
    var _obj_name_to_find = (object_exists(spawn_object_asset)) ? object_get_name(spawn_object_asset) : "INVALID_OBJECT_ASSET_INDEX(" + string(spawn_object_asset) + ")";
    show_debug_message("RoomStart Primary: Attempting to use next_spawn_object: " + _obj_name_to_find);
    
    global.next_spawn_object = undefined; // Consume immediately

    if (object_exists(spawn_object_asset)) { 
        var _actual_instance_count = instance_number(spawn_object_asset);
        show_debug_message("RoomStart Primary: Instance count for " + _obj_name_to_find + " in " + room_get_name(room) + " is " + string(_actual_instance_count));
        if (_actual_instance_count > 0) {
            var sp = instance_find(spawn_object_asset, 0); 
            if (instance_exists(sp)) { 
                x = sp.x;
                y = sp.y;
                _player_positioned_this_event = true;
                show_debug_message("Player Room Start: SUCCESS Primary! Spawned via " + _obj_name_to_find + " at (" + string(x) + "," + string(y) + ")");
                if (variable_global_exists("entry_direction")) { global.entry_direction = "none"; } // Consume this too
                // No exit needed here, will be caught by _player_positioned_this_event check below
            } // else: ODD CASE warning
        } // else: NO INSTANCES FOUND warning
    } // else: ASSET DOES NOT EXIST error
} // else: global.next_spawn_object not set/invalid warning
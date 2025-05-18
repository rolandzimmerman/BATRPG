// 2. FALLBACK SPAWN METHOD: Use global.entry_direction (only if not already positioned)
if (!_player_positioned_this_event && variable_global_exists("entry_direction") && global.entry_direction != "none" && global.entry_direction != undefined) {
    var entry_dir_value = global.entry_direction; 
    // (Keep your detailed logging for this block)
    show_debug_message("Player Room Start: Primary failed. Trying Fallback entry_direction: " + entry_dir_value);
    global.entry_direction = "none"; // Consume
    var target_spawn_object_type = noone;
    // ... (your switch(entry_dir_value) to find target_spawn_object_type) ...
    switch (entry_dir_value) {
        case "left":  target_spawn_object_type = obj_spawn_point_left;   break;
        case "right": target_spawn_object_type = obj_spawn_point_right;  break;
        case "above": target_spawn_object_type = obj_spawn_point_top;    break;
        case "below": target_spawn_object_type = obj_spawn_point_bottom; break;
        default: show_debug_message("Player Room Start: Unrecognized entry_direction value: " + entry_dir_value);
    }

    if (target_spawn_object_type != noone && object_exists(target_spawn_object_type)) {
        var _obj_name_fallback = object_get_name(target_spawn_object_type);
        var _instance_count_fallback = instance_number(target_spawn_object_type);
        if (_instance_count_fallback > 0) {
            var sp_dir = instance_find(target_spawn_object_type, 0);
            if (instance_exists(sp_dir)) {
                x = sp_dir.x;
                y = sp_dir.y;
                _player_positioned_this_event = true;
                show_debug_message("Player Room Start: SUCCESS Fallback1! Spawned via " + _obj_name_fallback + " at (" + string(x) + "," + string(y) + ")");
            } // else: ODD CASE warning
        } // else: NO INSTANCE warning
    } // else: ASSET NON-EXISTENT warning
} // else: entry_direction not valid for fallback
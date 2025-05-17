/// obj_player :: Room Start Event (Revised for self-reliant battle return)

// 0) Refresh collision layers 
tilemap = layer_tilemap_get_id(layer_get_id("Tiles_Col"));
tilemap_phase_id = layer_tilemap_get_id(layer_get_id("Tiles_Phase"));
if (tilemap == -1) show_debug_message("⚠️ Player RoomStart: Tiles_Col layer not found in " + room_get_name(room));
if (tilemap_phase_id == -1) show_debug_message("⚠️ Player RoomStart: Tiles_Phase layer not found in " + room_get_name(room));

var _player_positioned_this_event = false;

// --- A. Check for BATTLE RETURN ---
// This block now takes full responsibility for battle return positioning.
if (variable_global_exists("original_room") && global.original_room == room &&
    variable_global_exists("return_x") && !is_undefined(global.return_x) &&
    variable_global_exists("return_y") && !is_undefined(global.return_y))
{
    show_debug_message("Player Room Start: BATTLE RETURN DETECTED for room " + room_get_name(room));
    x = global.return_x;
    y = global.return_y;
    show_debug_message("  Player position set to: (" + string(x) + "," + string(y) + ") from battle return globals.");

    // CRITICAL: Consume/clear these globals immediately after use
    global.return_x = undefined;
    global.return_y = undefined;
    global.original_room = undefined;
    
    // Also clear any transition-related globals that might be stale
    if (variable_global_exists("next_spawn_object")) global.next_spawn_object = undefined;
    if (variable_global_exists("entry_direction")) global.entry_direction = "none";

    _player_positioned_this_event = true;
    // No 'exit;' here yet, allow tilemap refresh etc. to complete. We'll exit at the end if positioned.
}

// --- B. If in the actual battle room, do nothing else for spawning ---
if (room == rm_battle) {
    show_debug_message("Player Room Start: In rm_battle. No spawn positioning needed from player.");
    exit; // Exit entirely from spawn logic
}

// --- C. If positioned by battle return, skip normal transition spawns ---
if (_player_positioned_this_event) {
    show_debug_message("Player Room Start: Exiting spawn logic as battle return handled positioning.");
    exit;
}

// --- D. NORMAL TRANSITION SPAWN LOGIC (if not a battle return) ---
show_debug_message("Player Room Start: Proceeding with normal transition spawn logic for room " + room_get_name(room));

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

// 3. FINAL FALLBACK (only if not already positioned)
if (!_player_positioned_this_event) {
    show_debug_message("Player Room Start: All prior spawn methods failed. Looking for default obj_spawn_point.");
    // (Your existing final fallback logic for obj_spawn_point)
    if (object_exists(obj_spawn_point)) {
        var D = instance_find(obj_spawn_point, 0);
        if (instance_exists(D)) {
            x = D.x;
            y = D.y;
            _player_positioned_this_event = true; // Though less critical to set it here as it's the last attempt
            show_debug_message("Player Room Start: SUCCESS Fallback2! Spawned at default obj_spawn_point (" + string(x) + "," + string(y) + ")");
        } // else: no instance warning
    } // else: asset non-existent warning
}

if (!_player_positioned_this_event) {
    show_debug_message("Player Room Start ⚠️: ALL SPAWN METHODS FAILED. Player position unchanged from: (" + string(x) + "," + string(y) + ")");
}
show_debug_message("RoomStart " + room_get_name(room) + ": END OF PLAYER SPAWN LOGIC. Final Coords: (" + string(x) + "," + string(y) + ")");
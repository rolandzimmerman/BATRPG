/// obj_player :: Room Start Event

// 0) Refresh collision layers
tilemap          = layer_tilemap_get_id(layer_get_id("Tiles_Col"));
tilemap_phase_id = layer_tilemap_get_id(layer_get_id("Tiles_Phase"));
if (tilemap == -1)          show_debug_message("⚠️ Tiles_Col layer not found");
if (tilemap_phase_id == -1) show_debug_message("⚠️ Tiles_Phase layer not found");

// Check if position was already set by Game Manager's battle return logic
if (variable_global_exists("player_position_handled_by_battle_return") && global.player_position_handled_by_battle_return == true) {
    show_debug_message("Player Room Start: Position already handled by battle return. Skipping normal spawn logic.");
    global.player_position_handled_by_battle_return = false; // Consume/reset the flag
    exit; // IMPORTANT: Skip the rest of this event's spawn logic
}
/// obj_player :: Room Start Event
// 0) If we’re in the battle room, skip spawn-point logic entirely
// If we’re in battle, skip spawn logic
if (room == rm_battle) {
    exit;
}

// Only run spawn-object logic if next_spawn_object is set and is a real object
if (variable_global_exists("next_spawn_object")
 && !is_undefined(global.next_spawn_object)
 && object_exists(global.next_spawn_object))
{
    var sp = instance_find(global.next_spawn_object, 0);
    if (instance_exists(sp)) {
        x = sp.x;
        y = sp.y;
    }
    // consume it
    global.next_spawn_object = undefined;
}

// 3) entry_direction?
if (variable_global_exists("entry_direction") && global.entry_direction != "none")
{
    switch (global.entry_direction) {
        case "left":
            if (object_exists(obj_spawn_point_left)) {
                var L = instance_find(obj_spawn_point_left, 0);
                if (instance_exists(L)) { x = L.x; y = L.y; }
            }
            break;
        case "right":
            if (object_exists(obj_spawn_point_right)) {
                var R = instance_find(obj_spawn_point_right, 0);
                if (instance_exists(R)) { x = R.x; y = R.y; }
            }
            break;
        case "above":
            if (object_exists(obj_spawn_point_top)) {
                var T = instance_find(obj_spawn_point_top, 0);
                if (instance_exists(T)) { x = T.x; y = T.y; }
            }
            break;
        case "below":
            if (object_exists(obj_spawn_point_bottom)) {
                var B = instance_find(obj_spawn_point_bottom, 0);
                if (instance_exists(B)) { x = B.x; y = B.y; }
            }
            break;
    }
    show_debug_message("Spawned via entry_direction '" + global.entry_direction + "'");
    global.entry_direction = "none";
    return;
}

// 4) Fallback default spawn
if (object_exists(obj_spawn_point)) {
    var D = instance_find(obj_spawn_point, 0);
    if (instance_exists(D)) {
        x = D.x; y = D.y;
        show_debug_message("Spawned at default spawn → (" + string(x) + "," + string(y) + ")");
    } else {
        show_debug_message("⚠️ obj_spawn_point_default exists but no instances found");
    }
} else {
    show_debug_message("⚠️ No obj_spawn_point_default object in project—using editor position");
}

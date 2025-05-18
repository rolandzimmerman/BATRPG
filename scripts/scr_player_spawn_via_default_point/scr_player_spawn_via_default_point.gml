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
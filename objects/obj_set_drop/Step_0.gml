/// obj_loot_drop :: Step Event

show_debug_message("Loot Step (id:" + string(id) + ") BEGIN: y=" + string(y) + " v_spd=" + string(v_speed) + " landed=" + string(landed));

if (!landed) {
    // --- Falling + landing logic ---
    v_speed = min(v_speed + gravity_force, terminal_v_speed);

    var _collision_tilemaps = [];
    if (tm_solid    != -1) array_push(_collision_tilemaps, tm_solid);
    if (tm_phasable != -1) array_push(_collision_tilemaps, tm_phasable);

    if (array_length(_collision_tilemaps) > 0) {
        var collision_info_array = move_and_collide(0, v_speed, _collision_tilemaps);
        if (v_speed > 0 && array_length(collision_info_array) > 0) {
            y = floor(y);
            v_speed = 0;
            landed = true;
            pickup_delay_frames_actual = 3;
            show_debug_message("Loot Step (id:" + string(id) + "): LANDED! y=" + string(y));
        }
    } else {
        y += v_speed;
        show_debug_message("Loot Step (id:" + string(id) + "): FALLING (no tilemaps). y=" + string(y));
    }
} else {
    // --- Already landed: lock v_speed to zero ---
    if (v_speed != 0) v_speed = 0;
}

// --- Player pickup logic using drop_item_key & ItemDatabase ---
if (landed) {
    if (pickup_delay_frames_actual > 0) {
        pickup_delay_frames_actual -= 1;
    } else {
        var p = instance_place(x, y, obj_player);
        if (p != noone) {
            // If no drop key, just destroy
            if (!variable_instance_exists(id, "drop_item_key") || string_length(drop_item_key) == 0) {
                show_debug_message("Loot Step (id:" + string(id) + "): No drop_item_key; destroying.");
                instance_destroy();
                exit;
            }

            // Look up the proper display name
            var db    = scr_ItemDatabase();
            var entry = ds_map_find_value(db, drop_item_key);
            var niceName = (is_struct(entry) && variable_struct_exists(entry, "name"))
                         ? entry.name
                         : drop_item_key;

            // Give the item
            var added = (script_exists(asset_get_index("scr_AddInventoryItem")))
                      ? scr_AddInventoryItem(drop_item_key, 1)
                      : false;

            // Build and show message
            var msg = (added == true)
                    ? "You got " + niceName + "!"
                    : "You got " + niceName + ", but inventory full.";

            if (script_exists(asset_get_index("create_dialog"))) {
                create_dialog([{ name: "", msg: msg }]);
            } else {
                show_debug_message(msg);
            }

            show_debug_message("Loot Step (id:" + string(id) + "): Picked up '" + drop_item_key + "'. Destroying.");
            // record so it never respawns
if (variable_instance_exists(id, "loot_key")) {
    ds_map_add(global.loot_drops_map, loot_key, true);
}

// now destroy
instance_destroy();
exit;
            exit;
        }
    }
}

if (instance_exists(id)) {
    show_debug_message("Loot Step (id:" + string(id) + ") END: y=" + string(y) + " v_spd=" + string(v_speed) + " landed=" + string(landed));
}

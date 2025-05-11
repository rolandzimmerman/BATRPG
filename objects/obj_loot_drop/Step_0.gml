/// obj_loot_drop :: Step Event

show_debug_message("Loot Step (id:" + string(id) + ") BEGIN: y=" + string(y) + " v_spd=" + string(v_speed) + " landed=" + string(landed));

if (!landed) {
    // Apply gravity to vertical speed
    v_speed = min(v_speed + gravity_force, terminal_v_speed);

    // Prepare collision targets array
    var _collision_tilemaps = [];
    if (tm_solid != -1) {
        array_push(_collision_tilemaps, tm_solid);
    }
    if (tm_phasable != -1) {
        // For loot, you might only want it to land on solid, not phasable,
        // or perhaps both. Adjust as needed. Here, we include both if they exist.
        array_push(_collision_tilemaps, tm_phasable);
    }

    var _current_y_before_move = y; // For debug

    if (array_length(_collision_tilemaps) > 0) {
        // Attempt to move and collide
        // move_and_collide(xspd, yspd, collision_objects_or_tilemaps_array, ...)
        // It moves the instance and stops it at the collision, adjusting x/y.
        // It returns an array of collision_data_tile structs if tile collisions occurred.
        var collision_info_array = move_and_collide(0, v_speed, _collision_tilemaps);

        if (v_speed > 0 && array_length(collision_info_array) > 0) {
            // Was moving downwards and a collision occurred with one of the tilemaps
            // move_and_collide already placed the instance at the collision point.
            y = floor(y); // Optional: snap y to integer pixels after collision for tile crispness
            v_speed = 0;
            landed = true;
            pickup_delay_frames_actual = 3; // Start pickup delay
            show_debug_message("Loot Step (id:" + string(id) + "): ***** LANDED via move_and_collide! ***** Final y=" + string(y) + " v_spd=" + string(v_speed) + " landed=" + string(landed));
        }
        // If v_speed was 0 or negative, or no collision, 'y' was already updated by move_and_collide (or not moved if v_speed was 0).
        // If v_speed is still > 0 and no collision, it means it's still falling freely.
        
    } else {
        // No collision tilemaps defined, so just apply gravity (free fall)
        y += v_speed;
        show_debug_message("Loot Step (id:" + string(id) + "): FALLING (no collision tilemaps). New y=" + string(y));
    }
    
    if (!landed && v_speed > 0) { // Still falling
         show_debug_message("Loot Step (id:" + string(id) + ") FALLING: Old y=" + string(_current_y_before_move) + " v_spd=" + string(v_speed) + " -> New y=" + string(y));
    }

} else { // landed IS true
    // Object is landed. v_speed should be 0.
    // No y modification needed here if move_and_collide placed it correctly.
    // Ensure v_speed remains 0 if external forces were an issue (less likely now)
    if (v_speed != 0) {
        //show_debug_message("Loot Step (id:" + string(id) + "): LANDED but v_speed (" + string(v_speed) + ") != 0. Forcing v_speed = 0.");
        v_speed = 0;
    }
    //show_debug_message("Loot Step (id:" + string(id) + "): Confirmed LANDED state. y=" + string(y));
}

// --- Player pickup logic ---
if (landed) {
    if (pickup_delay_frames_actual > 0) {
        pickup_delay_frames_actual -= 1;
    } else {
        var p = instance_place(x, y, obj_player); 
        if (p != noone) {
            if (array_length(loot_table) > 0) {
                 var idx  = irandom(array_length(loot_table) - 1);
                 var item = loot_table[idx];
                 var added_status_or_message; 
                 if (script_exists(asset_get_index("scr_AddInventoryItem"))) { 
                     added_status_or_message = scr_AddInventoryItem(item.item_key, 1);
                 } else {
                     show_debug_message("ERROR (id:" + string(id) + "): scr_AddInventoryItem DNE!");
                     added_status_or_message = "Error: Inv script missing."; 
                 }
                var final_pickup_message = is_bool(added_status_or_message) ? ((added_status_or_message == true) ? "You got " + string(item.name) + "!" : "You got " + string(item.name) + ", but inventory full.") : string(added_status_or_message);
                var messages_to_show = [{ name: "", msg: final_pickup_message }];
                if (script_exists(asset_get_index("create_dialog"))) { 
                     create_dialog(messages_to_show);
                } else {
                    show_debug_message("ERROR (id:" + string(id) + "): create_dialog DNE! Msg: " + final_pickup_message);
                }
                show_debug_message("Loot Step (id:" + string(id) + "): Picked up '" + item.name + "'. Destroying instance.");
                instance_destroy();
                exit; 
            } else {
                 show_debug_message("Loot Step (id:" + string(id) + "): Loot table empty! Destroying instance.");
                 instance_destroy();
                 exit;
            }
        }
    }
}

if (instance_exists(id)) { 
    show_debug_message("Loot Step (id:" + string(id) + ") END: y=" + string(y) + " v_spd=" + string(v_speed) + " landed=" + string(landed));
}
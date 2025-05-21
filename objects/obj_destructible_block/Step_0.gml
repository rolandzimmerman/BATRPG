/// obj_destructible_block :: Step

// Use the unique key defined in the Create Event (or re-calculate it THE SAME WAY if not stored on self)
// For consistency, it's good if self.block_unique_key was set in Create.
// If not, ensure calculation is identical:
var current_block_key = "block_" + room_get_name(room) + "_" + string(x) + "_" + string(y);
// If you stored it as self.block_unique_key in Create, you can just use that:
// var current_block_key = self.block_unique_key;


if (!isBreaking) {
    // 1) Check for echo missile collision
    var m = instance_place(x, y, obj_echo_missile);
    if (m != noone) {
        with (m) instance_destroy(); // Destroy the missile

        isBreaking   = true;
        sprite_index = spr_destructible_block_break;
        image_index  = 0;
        image_speed  = 1;
        mask_index   = -1; // no collision during break
        solid        = false;
        show_debug_message("Block " + current_block_key + " starts breaking.");
    }
} else {
    // 2) Wait until the break animation finishes
    if (image_index >= image_number - 1) {
        // (4) Record that this block is broken using the unique key
        if (ds_exists(global.broken_blocks_map, ds_type_map)) {
            ds_map_add(global.broken_blocks_map, current_block_key, true);
            show_debug_message("Block " + current_block_key + " finished breaking. Added to global.broken_blocks_map. New map size: " + string(ds_map_size(global.broken_blocks_map)));
        } else {
            show_debug_message("Block " + current_block_key + " finished breaking, BUT global.broken_blocks_map is missing or invalid! State NOT saved.");
        }
        instance_destroy();
    }
}
/// obj_destructible_block :: Step

// compute the same key each Step
var block_key = "block_" + string(x) + "_" + string(y);

if (!isBreaking) {
    // 1) Check for echo missile collision
    var m = instance_place(x, y, obj_echo_missile);
    if (m != noone) {
        // Destroy the missile
        with (m) instance_destroy();

        // Begin break
        isBreaking   = true;
        sprite_index = spr_destructible_block_break;
        image_index  = 0;
        image_speed  = 1;

        // Update mask to match new sprite (or clear it entirely)
        mask_index   = -1;   // no collision during break
        solid        = false;
    }
} else {
    // 2) Wait until the break animation finishes
    if (image_index >= image_number - 1) {
        // (4) Record that this block is broken
        ds_map_add(global.broken_blocks_map, block_key, true);

        // …and finally destroy
        instance_destroy();
    }
}

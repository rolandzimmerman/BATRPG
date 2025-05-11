/// obj_destructible_block :: Step

if (!isBreaking) {
    // 1) Check for echo missile collision
    var m = instance_place(x, y, obj_echo_missile);
    if (m != noone) {
        // Destroy the missile
        with (m) instance_destroy();

        // Begin break
        isBreaking    = true;
        sprite_index  = spr_destructible_block_break;
        image_index   = 0;
        image_speed   = 0.5;

        // Update mask to match new sprite (or clear it entirely)
        mask_index    = -1;   // no collision during break
        solid         = false;
    }
} else {
    // 2) Wait until the break animation finishes
    if (image_index >= image_number - 1) {
        instance_destroy();
    }
}

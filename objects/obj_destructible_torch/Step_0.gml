/// obj_destructible_torch :: Step

// 1) See if an echo missile hit us
var hit = instance_place(x, y, obj_echo_missile);
if (hit != noone) {
    
    // Destroy the missile
    with (hit) instance_destroy();
    
    // 2) Roll for loot drop
    if (random(1) < loot_drop_chance) {
        // spawn the loot on the ground at the torch's position
        var loot = instance_create_depth(
            x, y,
            0,               // same depth as torch
            obj_loot_drop
        );
        // assign its sprite
        loot.sprite_index = spr_loot_drop;
    }
    
    // 3) Finally, destroy the torch itself
    instance_destroy();
    return;
}

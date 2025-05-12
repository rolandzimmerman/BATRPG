/// obj_destructible_block :: Create

// (1) Prepare global map once
if (!variable_global_exists("broken_blocks_map")) {
    global.broken_blocks_map = ds_map_create();
}

// (2) Compute a key unique to this block
var block_key = "block_" + string(x) + "_" + string(y);

// (3) If we’ve broken this one already, destroy immediately
if (ds_map_exists(global.broken_blocks_map, block_key)) {
    instance_destroy();
    exit;
}

// State
isBreaking = false;

// Intact visuals & collision
sprite_index = spr_destructible_block;
image_speed   = 0;
mask_index    = sprite_index;
solid         = true;

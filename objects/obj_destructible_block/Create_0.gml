/// obj_destructible_block :: Create

// (1) Prepare global map once
if (!variable_global_exists("broken_blocks_map")) {
    global.broken_blocks_map = ds_map_create();
}

// (2) Unique key
var block_key = "block_" + string(x) + "_" + string(y);

// (3) Already broken?
if (ds_map_exists(global.broken_blocks_map, block_key)) {
    instance_destroy();
    exit;
}

// State
isBreaking = false;

// Visual sprite
sprite_index = spr_destructible_block;
image_speed   = 0;

// **Use your new mask sprite here**  
mask_index    = spr_destructible_block_mask;
solid         = true;

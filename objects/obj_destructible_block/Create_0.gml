/// obj_destructible_block :: Create

// (1) Global map is now reliably initialized by obj_game_manager.
// This check is now more of a safety guard during development.
if (!variable_global_exists("broken_blocks_map") || !ds_exists(global.broken_blocks_map, ds_type_map)) {
    show_debug_message("CRITICAL ERROR in obj_destructible_block Create: global.broken_blocks_map is not initialized or not a DS Map! Please ensure obj_game_manager runs its Create event first.");
    // As a temporary fallback for testing IF THIS IS THE ISSUE, you could create it here,
    // but the primary creation should be in obj_game_manager.
    // if (!variable_global_exists("broken_blocks_map")) global.broken_blocks_map = ds_map_create();
    instance_destroy(); // Cannot function without the map
    exit;
}

// (2) Unique key - CRITICAL CHANGE: Include the room name for global uniqueness
self.block_unique_key = "block_" + room_get_name(room) + "_" + string(x) + "_" + string(y);
// Using "self.block_unique_key" to store it on the instance if needed by other events without re-calculating.

show_debug_message("Block Create: ID " + string(id) + ", Key='" + self.block_unique_key + "'. Checking map (ID: " + string(global.broken_blocks_map) + ", Size: " + string(ds_map_size(global.broken_blocks_map)) + ")");

// (3) Already broken?
if (ds_map_exists(global.broken_blocks_map, self.block_unique_key)) {
    show_debug_message(" -> Block " + self.block_unique_key + " is already broken. Destroying.");
    instance_destroy();
    exit; // Important: Stop further create event code if destroyed
} else {
    show_debug_message(" -> Block " + self.block_unique_key + " is intact.");
}

// State
isBreaking = false;

// Visual sprite
sprite_index = spr_destructible_block;
image_speed  = 0;
mask_index   = spr_destructible_block_mask;
solid        = true;
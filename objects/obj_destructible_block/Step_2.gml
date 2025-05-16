// obj_destructible_block :: End Step Event for debugging only
var block_key = "block_" + string(x) + "_" + string(y);
if (id == block_key) { // Optional: Focus on one block
    show_debug_message("Block ID: " + string(id) + 
                       " | isBreaking: " + string(isBreaking) + 
                       " | mask_index: " + string(mask_index) +
                       " | image_index: " + string(image_index) +
                       " | image_speed: " + string(image_speed) +
                       " | sprite_index: " + asset_get_name(sprite_index));
}
// If you don't know the ID, you can make it conditional on player proximity:
// if (instance_exists(obj_player) && distance_to_object(obj_player) < 32) { ... debug message ... }
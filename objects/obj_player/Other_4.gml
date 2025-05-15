/// obj_player :: Room Start Event

// 0) Refresh collision layers every transition
tilemap           = layer_tilemap_get_id(layer_get_id("Tiles_Col"));
tilemap_phase_id  = layer_tilemap_get_id(layer_get_id("Tiles_Phase"));
if (tilemap == -1)           show_debug_message("⚠️ Tiles_Col missing");
if (tilemap_phase_id == -1)  show_debug_message("⚠️ Tiles_Phase missing");


if (variable_global_exists("next_spawn_object")) {
    var sp = instance_find(global.next_spawn_object, 0);
    if (instance_exists(sp)) {
        x = sp.x;
        y = sp.y;
    }
    global.next_spawn_object = undefined;
}

// 0) Refresh collision layers 
tilemap = layer_tilemap_get_id(layer_get_id("Tiles_Col"));
tilemap_phase_id = layer_tilemap_get_id(layer_get_id("Tiles_Phase"));
if (tilemap == -1) show_debug_message("⚠️ Player RoomStart: Tiles_Col layer not found in " + room_get_name(room));
if (tilemap_phase_id == -1) show_debug_message("⚠️ Player RoomStart: Tiles_Phase layer not found in " + room_get_name(room));

var _player_positioned_this_event = false;
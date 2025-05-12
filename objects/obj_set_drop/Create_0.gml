/// obj_loot_drop :: Create Event

show_debug_message("--- obj_loot_drop Created (Instance: " + string(id) + ") ---");

// --- Physics Parameters ---
self.v_speed                   = 0;    // Current vertical speed
self.gravity_force             = 0.4;  // Downward acceleration
self.terminal_v_speed          = 8;    // Max fall speed
self.landed                    = false;
self.pickup_delay_frames_actual = 0;

// --- Tilemap Collision IDs ---
var col_layer_id    = layer_get_id("Tiles_Col");
self.tm_solid       = (col_layer_id != -1) 
                       ? layer_tilemap_get_id(col_layer_id) 
                       : -1;

var phase_layer_id  = layer_get_id("Tiles_Phase");
self.tm_phasable    = (phase_layer_id != -1) 
                       ? layer_tilemap_get_id(phase_layer_id) 
                       : -1;

show_debug_message("Loot Create (id:" + string(id) + "): Spawn(x=" + string(x) + ", y=" + string(y) + ")");
show_debug_message("Loot Create: Solid TM ID = " + string(self.tm_solid) 
                   + ", Phase TM ID = " + string(self.tm_phasable));

// --- Forced Drop via set_drop ---
if (variable_instance_exists(id, "set_drop") && string_length(string(set_drop)) > 0) {
    // strip any stray quotation marks
    var key = string(set_drop);
    key = string_replace_all(key, "\"", "");

    // (Optional) validate against your item DB here...
    self.drop_item_key = key;
    show_debug_message("Loot Create: Forced drop -> " + drop_item_key);
} else {
    // No override provided—warn and default to nothing
    self.drop_item_key = "";
    show_debug_message("Warning: obj_loot_drop has no valid set_drop; drop_item_key is empty.");
}
// ——— Prevent respawn ———
if (!variable_global_exists("loot_drops_map")) {
    global.loot_drops_map = ds_map_create();
}
var loot_key = string(room) + "_" + string(x) + "_" + string(y);
if (ds_map_exists(global.loot_drops_map, loot_key)) {
    // we already picked this up before
    instance_destroy();
    exit;
}
// store for Step to record later
self.loot_key = loot_key;

// --- Finished initialization ---
show_debug_message("--- obj_loot_drop Create Event Finished. drop_item_key = " + drop_item_key + " ---");

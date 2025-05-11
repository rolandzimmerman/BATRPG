/// obj_loot_drop :: Create Event
show_debug_message("--- obj_loot_drop Created (Instance: " + string(id) + ") ---");

// --- Physics Parameters ---
self.v_speed = 0;            // Current vertical speed
self.gravity_force = 0.4;    // Rate of acceleration downwards (renamed for clarity if you use 'gravity' built-in elsewhere)
self.terminal_v_speed = 8;   // Maximum falling speed
self.landed = false;           // Has the loot landed on the ground?
self.pickup_delay_frames_actual = 0; // Timer for delaying pickup after landing

// --- Get Tilemap IDs for Collision ---
// Ensure layer names "Tiles_Col" and "Tiles_Phase" are correct for your room.
var col_layer_id = layer_get_id("Tiles_Col");
self.tm_solid = (col_layer_id != -1) ? layer_tilemap_get_id(col_layer_id) : -1;

var phase_layer_id = layer_get_id("Tiles_Phase");
self.tm_phasable = (phase_layer_id != -1) ? layer_tilemap_get_id(phase_layer_id) : -1;

show_debug_message("Loot Create (id:" + string(id) + "): Spawn(x=" + string(x) + ",y=" + string(y) + ")");
show_debug_message("Loot Create (id:" + string(id) + "): Solid Tilemap ID (Tiles_Col): " + string(self.tm_solid));
show_debug_message("Loot Create (id:" + string(id) + "): Phasable Tilemap ID (Tiles_Phase): " + string(self.tm_phasable));
show_debug_message("Loot Create (id:" + string(id) + "): IMPORTANT: Landing position will now be determined by sprite's collision mask and tile collisions.");

// --- Loot Table Definition ---
self.loot_table = [
    { name: "Potion",   item_key: "potion"   },
    { name: "Antidote", item_key: "antidote" },
    { name: "Bomb",     item_key: "bomb"     }
];
// Note: If you still want the "spawn high and fall" visual, you'd manually place the
// obj_loot_drop instance at a higher Y coordinate in the room editor, or in its creation code.
// The old "snap_y - 32" logic isn't used here as snap_y for landing is removed.

show_debug_message("--- obj_loot_drop Create Event Finished (Instance: " + string(id) + ") ---");
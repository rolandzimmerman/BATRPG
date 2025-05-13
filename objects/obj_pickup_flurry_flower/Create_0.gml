/// obj_pickup_flurry_flower :: Create

// --- MODIFICATION FOR NON-RESPAWN ---
// Ensure global.has_collected_main_flurry_flower is initialized (should be done at game start)
if (!variable_global_exists("has_collected_main_flurry_flower")) {
    global.has_collected_main_flurry_flower = false; // Fallback initialization
    show_debug_message("WARNING: global.has_collected_main_flurry_flower was not initialized by game start script. Setting to false for obj_pickup_flurry_flower.");
}

if (global.has_collected_main_flurry_flower == true) {
    show_debug_message("obj_pickup_flurry_flower: Already collected globally. Destroying instance.");
    instance_destroy(); // Destroy immediately if already collected
    exit; // Exit create event
}
// --- END MODIFICATION ---

// Ensure we only pick up once (this is for single interaction within the room instance's lifetime)
picked_up = false;
image_xscale = 2;
image_yscale = 2;
// Dialog message: "You got the Flurry Flower! Press the left and right bumpers to dash with Flower Flurry."

show_debug_message("obj_pickup_flurry_flower: Instance created and not yet collected globally.");
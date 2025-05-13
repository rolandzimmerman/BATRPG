/// obj_pickup_echo_gem :: Create

// --- MODIFICATION FOR NON-RESPAWN ---
// Ensure global.has_collected_main_echo_gem is initialized (e.g., in a game start script to false)
if (!variable_global_exists("has_collected_main_echo_gem")) {
    global.has_collected_main_echo_gem = false;
    show_debug_message("WARNING: global.has_collected_main_echo_gem was not initialized. Setting to false.");
}

if (global.has_collected_main_echo_gem == true) {
    show_debug_message("obj_pickup_echo_gem: Already collected. Destroying instance.");
    instance_destroy(); // Destroy immediately if already collected
    exit; // Exit create event to prevent further initialization
}
// --- END MODIFICATION ---

// Ensure we only pick up once (this is for single interaction within the room instance's lifetime)
picked_up = false;
image_xscale = 2;
image_yscale = 2;

show_debug_message("obj_pickup_echo_gem: Instance created and not yet collected globally.");
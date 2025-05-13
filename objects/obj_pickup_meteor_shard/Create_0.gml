/// obj_pickup_meteor_shard :: Create

// --- MODIFICATION FOR NON-RESPAWN ---
// Ensure global.has_collected_main_meteor_shard is initialized (should be done at game start)
if (!variable_global_exists("has_collected_main_meteor_shard")) {
    global.has_collected_main_meteor_shard = false; // Fallback initialization
    show_debug_message("WARNING: global.has_collected_main_meteor_shard was not initialized by game start script. Setting to false for obj_pickup_meteor_shard.");
}

if (global.has_collected_main_meteor_shard == true) {
    show_debug_message("obj_pickup_meteor_shard: Already collected globally. Destroying instance.");
    instance_destroy(); // Destroy immediately if already collected
    exit; // Exit create event
}
// --- END MODIFICATION ---

// Ensure we only pick up once (this is for single interaction within the room instance's lifetime)
picked_up = false;
image_xscale = 2;
image_yscale = 2;
// Dialog message: "You got the Meteor Shard! Press Y to use Meteor Dive."

show_debug_message("obj_pickup_meteor_shard: Instance created and not yet collected globally.");
/// obj_pickup_echo_gem :: Create Event

// 1) Non-respawn guard
if (!variable_global_exists("has_defeated_ogre")) {
    global.has_defeated_ogre = false;
}
if (global.has_defeated_ogre) {
    // We already picked it up on an earlier run of this room
    instance_destroy();
    exit;
}

// 2) Persist through the battle room
persistent = true;

// 3) Our one-time trigger flag
picked_up = false;

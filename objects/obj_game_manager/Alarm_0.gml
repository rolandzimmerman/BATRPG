/// obj_game_manager :: Alarm 0
// this fires one frame after the room start above
/*if (global.start_as_load) {
    // teleport the player
    if (instance_exists(obj_player)) {
        obj_player.x = global.load_x;
        obj_player.y = global.load_y;
    }
    // clear the flag that skips normal spawn logic
    global.start_as_load = false;

    // re-enable all instances (in case you globally deactivate input during loading)
    // no arguments → activates everything
    instance_activate_all();

    // finally ensure the game is un-paused
    global.game_paused = false;
}

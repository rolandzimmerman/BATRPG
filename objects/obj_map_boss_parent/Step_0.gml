/// obj_pickup_echo_gem :: Step Event

// ————————————————
// PART A: once triggered, wait for dialogue → destroy
// ————————————————
if (picked_up) {
    // When your dialogue object is finally gone, lamp dies
    if (!instance_exists(obj_dialog)) {
        instance_destroy();
    }
    return;
}

// ————————————————
// PART B: first overlap → fire dialogue & mark global
// ————————————————
if (instance_place(x, y, obj_player) != noone) {
    picked_up = true;
    global.has_defeated_ogre = true;

    if (script_exists(create_dialog)) {
        create_dialog([
            {
                name: "Ogre",
                msg: "AHHH! DUM SORD DON'T BREAK ROK! ME STUCK! BREAK STUPID HEAD!",
                script_to_run: scr_StartFixedEncounter,
                script_args: [[obj_enemy_nut_thief]]
            }
        ]);
    } else {
        show_debug_message("WARNING: create_dialog missing—starting encounter now.");
        scr_StartFixedEncounter([obj_enemy_nut_thief]);
    }
}

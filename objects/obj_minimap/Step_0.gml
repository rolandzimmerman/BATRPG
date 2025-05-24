/// In the Step Event of the object that handles the Map Toggle (e.g., obj_map_ui or obj_game_manager)

// Assuming player_index 0 for gamepad inputs by default
var toggle_map_pressed = input_check_pressed(INPUT_ACTION.TOGGLE_MAP_OR_INFO);

if (toggle_map_pressed) {
    // This 'visible' likely refers to the map UI object's own visibility.
    // If this code is in obj_map_ui, 'visible = !visible;' is correct.
    // If this code is in obj_game_manager, it would need to be:
    // if (instance_exists(obj_map_ui_instance)) {
    //     obj_map_ui_instance.visible = !obj_map_ui_instance.visible;
    // }
    visible = !visible; 
    show_debug_message("Map UI Visibility Toggled to: " + string(visible));
    // audio_play_sound(snd_map_toggle_ui, 0, false); // Optional sound
}
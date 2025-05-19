// In obj_game_manager :: Alarm 1 Event (for hiding the temporary effect layer)

show_debug_message("obj_game_manager Alarm 1: Attempting to hide layer '" + layer_to_hide_on_alarm + "'");

if (layer_to_hide_on_alarm != "") {
    if (layer_exists(layer_to_hide_on_alarm)) {
        layer_set_visible(layer_to_hide_on_alarm, false); // Make the layer invisible again
        show_debug_message(" -> Layer '" + layer_to_hide_on_alarm + "' set to INVISIBLE.");
    } else {
        show_debug_message("WARNING: Layer '" + layer_to_hide_on_alarm + "' did not exist when trying to hide it.");
    }
    layer_to_hide_on_alarm = ""; // Reset for next use
}
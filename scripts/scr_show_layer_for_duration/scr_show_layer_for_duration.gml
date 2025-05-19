// Script: scr_show_layer_for_duration
/// @function scr_show_layer_for_duration(_layer_name_string, _duration_frames)
/// @description Makes a given layer visible for a set duration, then hides it again.
/// @param {String} _layer_name_string   The name of the layer to make visible.
/// @param {Real}   _duration_frames     How many frames the layer should stay visible.
function scr_show_layer_for_duration(_layer_name_string, _duration_frames) {
    show_debug_message("scr_show_layer_for_duration: Called for layer '" + _layer_name_string + "' for " + string(_duration_frames) + " frames.");

    if (!layer_exists(_layer_name_string)) {
        show_debug_message("ERROR: Layer '" + _layer_name_string + "' does not exist. Cannot show it.");
        return;
    }

    // Make the layer visible
    layer_set_visible(_layer_name_string, true);
    show_debug_message(" -> Layer '" + _layer_name_string + "' set to VISIBLE.");

    // Set an alarm in obj_game_manager to hide the layer again
    if (instance_exists(obj_game_manager)) {
        // You might want to use a different alarm if Alarm 0 is busy, e.g., Alarm 1
        // Or use a more robust timer system if you have many timed events.
        // For now, let's assume Alarm 1 is free for this.
        obj_game_manager.layer_to_hide_on_alarm = _layer_name_string;
        obj_game_manager.alarm[1] = _duration_frames; // Using Alarm 1
    } else {
        show_debug_message("WARNING: obj_game_manager not found! Layer '" + _layer_name_string + "' will remain visible.");
    }
}
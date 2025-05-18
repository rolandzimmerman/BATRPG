var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;
if (_gm == noone || (variable_instance_exists(_gm, "game_state") && _gm.game_state != "playing")) {
    return false; // Don't allow pausing if not in a "playing" state or no GM
}

var _pause_input = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_start);

if (_pause_input && !instance_exists(obj_pause_menu)) {
    _gm.game_state = "paused"; // Assuming _gm is valid and has game_state

    var _pause_layer_name = "Instances_GUI"; // Recommended GUI layer
    var _pause_layer = layer_get_id(_pause_layer_name);
    if (_pause_layer == -1) { // Fallback
        _pause_layer_name = "Instances";
        _pause_layer = layer_get_id(_pause_layer_name);
        if (_pause_layer == -1) { // Critical fallback
            show_debug_message("ERROR: Could not find a suitable layer for pause menu. Creating fallback layer.");
            _pause_layer = layer_create(-10000, "PauseMenuFallbackLayer");
             _pause_layer_name = layer_get_name(_pause_layer);
        }
    }
    show_debug_message("Player: Pausing game. Creating pause menu on layer: " + _pause_layer_name);
    var _menu = instance_create_layer(0, 0, _pause_layer, obj_pause_menu);

    // Deactivate appropriate instances
    instance_deactivate_object(id); // Deactivate self (obj_player)
    if (instance_exists(obj_npc_parent)) { // Assuming obj_npc_parent is your parent for NPCs
        instance_deactivate_object(obj_npc_parent);
    }
    // ... (deactivate other relevant gameplay objects)

    instance_activate_object(_menu); // Ensure the pause menu itself is active
    instance_activate_object(obj_game_manager); // Keep game manager active

    return true; // Game paused, caller should exit
}
return false;
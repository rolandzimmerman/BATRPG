/// obj_levelup_popup :: Step Event

// Assuming player_index 0 for gamepad inputs by default
var confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);

// — Wait for Confirm, then advance or finish —
if (confirm_pressed) {
    // audio_play_sound(snd_menu_select, 0, false); // Optional: Confirmation sound

    // Destroy this popup instance
    instance_destroy();

    // Advance to the next character's level-up info or finish
    if (variable_global_exists("battle_levelup_index")) { // Safety check for global
        global.battle_levelup_index += 1;

        if (variable_global_exists("battle_level_up_infos") && is_array(global.battle_level_up_infos)) { // Safety check
            if (global.battle_levelup_index < array_length(global.battle_level_up_infos)) {
                // Spawn the next popup on your UI layer
                // Ensure "Instances" is the correct layer name for this context, or use "Instances_GUI" if preferred
                var _layer_for_popup = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
                if (layer_exists(_layer_for_popup) && object_exists(obj_levelup_popup)) {
                     instance_create_layer(0, 0, _layer_for_popup, obj_levelup_popup);
                     show_debug_message("Level Up: Spawning next popup for index " + string(global.battle_levelup_index));
                } else {
                    show_debug_message("ERROR [obj_levelup_popup]: Layer '" + _layer_for_popup + "' or obj_levelup_popup missing for next popup.");
                    // If layer or object is missing, fallback to ending level up sequence
                    global.battle_state = "return_to_field";
                    if (instance_exists(obj_battle_manager)) { // Check obj_battle_manager exists
                         with (obj_battle_manager) alarm[0] = 60; // Consider a shorter alarm if UI is gone
                    }
                }
            } else {
                // No more level ups, return to field
                show_debug_message("Level Up: All level up popups shown. Returning to field.");
                global.battle_state = "return_to_field";
                if (instance_exists(obj_battle_manager)) { // Check obj_battle_manager exists
                    with (obj_battle_manager) alarm[0] = 60; // Time for player to see last message before battle results close
                }
            }
        } else {
            show_debug_message("ERROR [obj_levelup_popup]: global.battle_level_up_infos is missing or not an array.");
            global.battle_state = "return_to_field"; // Fallback
            if (instance_exists(obj_battle_manager)) {
                with (obj_battle_manager) alarm[0] = 1; // Quick return if data is bad
            }
        }
    } else {
        show_debug_message("ERROR [obj_levelup_popup]: global.battle_levelup_index is missing.");
        global.battle_state = "return_to_field"; // Fallback
        if (instance_exists(obj_battle_manager)) {
             with (obj_battle_manager) alarm[0] = 1;
        }
    }
}
/// obj_title_menu - Step Event
if (!active) {
    exit; // If not active, do nothing
}

// Input Cooldown
if (input_cooldown > 0) {
    input_cooldown--;
}

// --- Input Handling --- (Assuming this part is already as you like it from previous steps)
var _up_pressed = (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")) || (gamepad_button_check_pressed(0, gp_padu) && input_cooldown == 0));
var _down_pressed = (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")) || (gamepad_button_check_pressed(0, gp_padd) && input_cooldown == 0));
var _confirm_pressed = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);

// Navigation (Assuming this part is already as you like it)
if (_up_pressed) {
    menu_index = (menu_index - 1 + menu_item_count) mod menu_item_count;
    input_cooldown = input_cooldown_max;
    // audio_play_sound(snd_menu_blip, 0, false); 
}
if (_down_pressed) {
    menu_index = (menu_index + 1) mod menu_item_count;
    input_cooldown = input_cooldown_max;
    // audio_play_sound(snd_menu_blip, 0, false); 
}

// Action on Confirm
if (_confirm_pressed) {
    input_cooldown = input_cooldown_max;
    var selected_option = menu_items[menu_index];
    // audio_play_sound(snd_menu_select, 0, false); 

    switch (selected_option) {
        case "New Game":
            show_debug_message("Title Menu: Selected New Game");
            if (variable_global_exists("start_as_new_game")) {
                global.start_as_new_game = true;
            }
            if (variable_global_exists("return_x")) global.return_x = undefined;
            if (variable_global_exists("return_y")) global.return_y = undefined;
            if (variable_global_exists("original_room")) global.original_room = undefined;

            if (room_exists(room_for_new_game)) {
                room_goto(room_for_new_game);
            } else {
                show_debug_message("ERROR: 'room_for_new_game' (" + room_get_name(room_for_new_game) + ") does not exist!");
            }
            break;

        case "Load Game":
            show_debug_message("Title Menu: Selected Load Game. Attempting to load from: " + default_save_filename);

            // Ensure the load game script actually exists in your project
            if (script_exists(scr_load_game)) {
                // Call your load game script
                var _load_initiated = scr_load_game(default_save_filename);

                if (_load_initiated) {
                    // scr_load_game handles the room_goto if successful.
                    // If obj_title_menu is not persistent, it will be destroyed.
                    // If it IS persistent, you might want to set active = false here.
                    show_debug_message("Load game process initiated successfully by scr_load_game.");
                    // No explicit active = false; here, as room_goto will destroy non-persistent instances.
                } else {
                    // scr_load_game returned false, indicating an issue (e.g., file not found, parse error).
                    // Your scr_load_game already outputs debug messages for these cases.
                    // You might want to display a user-friendly error message on the screen here.
                    show_debug_message("scr_load_game reported an issue. Load failed to start. Staying on title screen.");
                    // Potentially play an error sound or show a visual cue to the player.
                    input_cooldown = input_cooldown_max; // Prevent immediate re-selection if showing an error.
                }
            } else {
                show_debug_message("ERROR: scr_load_game script does not exist in the project!");
                input_cooldown = input_cooldown_max; // Prevent immediate re-selection.
            }
            break;

        case "Settings":
            show_debug_message("Title Menu: Selected Settings");
            active = false; 

            if (!instance_exists(obj_settings_menu)) {
                settings_menu_instance_id = instance_create_layer(0, 0, "Instances_GUI", obj_settings_menu);
            } else {
                settings_menu_instance_id = instance_find(obj_settings_menu, 0);
            }

            if (instance_exists(settings_menu_instance_id)) {
                settings_menu_instance_id.active = true;
                settings_menu_instance_id.opened_by_instance_id = id;
            } else {
                show_debug_message("ERROR: Failed to find or create obj_settings_menu.");
                active = true; 
            }
            break;
    }
}
/// obj_title_menu - Step Event
if (!active) {
    exit; // If not active, do nothing
}

// Input Cooldown
if (input_cooldown > 0) {
    input_cooldown--;
}

// --- Input Handling ---
var gp_idx = global.gamepad_player_map[0]; // Assuming player 0 for menus
var map_menu_up = global.input_mappings[INPUT_ACTION.MENU_UP];
var map_menu_down = global.input_mappings[INPUT_ACTION.MENU_DOWN];

// Up Pressed - with specific cooldown logic
var _kb_up_pressed = false;
if (variable_struct_exists(map_menu_up, "kb_keys")) {
    for (var i = 0; i < array_length(map_menu_up.kb_keys); ++i) {
        if (keyboard_check_pressed(map_menu_up.kb_keys[i])) {
            _kb_up_pressed = true;
            break;
        }
    }
}
var _gp_up_pressed_raw = false;
if (gamepad_is_connected(gp_idx) && variable_struct_exists(map_menu_up, "gp_buttons")) {
    for (var i = 0; i < array_length(map_menu_up.gp_buttons); ++i) {
        if (gamepad_button_check_pressed(gp_idx, map_menu_up.gp_buttons[i])) {
            _gp_up_pressed_raw = true;
            break;
        }
    }
}
var _up_pressed = _kb_up_pressed || (_gp_up_pressed_raw && input_cooldown == 0);

// Down Pressed - with specific cooldown logic
var _kb_down_pressed = false;
if (variable_struct_exists(map_menu_down, "kb_keys")) {
    for (var i = 0; i < array_length(map_menu_down.kb_keys); ++i) {
        if (keyboard_check_pressed(map_menu_down.kb_keys[i])) {
            _kb_down_pressed = true;
            break;
        }
    }
}
var _gp_down_pressed_raw = false;
if (gamepad_is_connected(gp_idx) && variable_struct_exists(map_menu_down, "gp_buttons")) {
    for (var i = 0; i < array_length(map_menu_down.gp_buttons); ++i) {
        if (gamepad_button_check_pressed(gp_idx, map_menu_down.gp_buttons[i])) {
            _gp_down_pressed_raw = true;
            break;
        }
    }
}
var _down_pressed = _kb_down_pressed || (_gp_down_pressed_raw && input_cooldown == 0);

// Confirm Pressed - uses standard input check (no special cooldown in its condition)
var _confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM, 0);


// Navigation
if (_up_pressed) { // Uses the combined logic from above
    menu_index = (menu_index - 1 + menu_item_count) mod menu_item_count;
    input_cooldown = input_cooldown_max; // Reset cooldown regardless of source
    // audio_play_sound(snd_menu_blip, 0, false); 
}
if (_down_pressed) { // Uses the combined logic from above
    menu_index = (menu_index + 1) mod menu_item_count;
    input_cooldown = input_cooldown_max; // Reset cooldown regardless of source
    // audio_play_sound(snd_menu_blip, 0, false); 
}

// Action on Confirm
if (_confirm_pressed) {
    input_cooldown = input_cooldown_max; // Reset cooldown as per original logic
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
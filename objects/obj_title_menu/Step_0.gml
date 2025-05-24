/// obj_title_menu - Step Event
if (!active) {
    exit; // If not active, do nothing
}

// Input Cooldown
if (input_cooldown > 0) {
    input_cooldown--;
}

// --- Input Handling (Simplified - Cooldown applies to the action universally) ---
// Assuming player_index 0 for all menu inputs
var up_action_pressed = input_check_pressed(INPUT_ACTION.MENU_UP, 0);
var down_action_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN, 0);
var confirm_action_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM, 0);

// Apply cooldown to navigation actions
var _up_pressed = up_action_pressed && (input_cooldown == 0);
var _down_pressed = down_action_pressed && (input_cooldown == 0);
var _confirm_pressed = confirm_action_pressed; // Confirm might have its own cooldown logic or not need it here

// Navigation
if (_up_pressed) {
    menu_index = (menu_index - 1 + menu_item_count) mod menu_item_count;
    input_cooldown = input_cooldown_max; // Reset cooldown
    // audio_play_sound(snd_menu_blip, 0, false); 
}
if (_down_pressed) {
    menu_index = (menu_index + 1) mod menu_item_count;
    input_cooldown = input_cooldown_max; // Reset cooldown
    // audio_play_sound(snd_menu_blip, 0, false); 
}

// Action on Confirm
if (_confirm_pressed) {
    // input_cooldown = input_cooldown_max; // Reset cooldown if confirm also shares it
    // Your original code reset cooldown here even if confirm didn't check it for its condition.
    // If confirm should also wait for cooldown, the condition would be:
    // if (_confirm_pressed && input_cooldown == 0) { ... input_cooldown = input_cooldown_max; ... }
    // For now, matching your original structure where confirm action resets cooldown:
    input_cooldown = input_cooldown_max;

    var selected_option = menu_items[menu_index]; // Ensure menu_index is valid
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
            if (script_exists(scr_load_game)) {
                var _load_initiated = scr_load_game(default_save_filename);
                if (_load_initiated) {
                    show_debug_message("Load game process initiated successfully by scr_load_game.");
                } else {
                    show_debug_message("scr_load_game reported an issue. Load failed to start. Staying on title screen.");
                    // input_cooldown = input_cooldown_max; // Already set if confirm was pressed
                }
            } else {
                show_debug_message("ERROR: scr_load_game script does not exist in the project!");
                // input_cooldown = input_cooldown_max; // Already set
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
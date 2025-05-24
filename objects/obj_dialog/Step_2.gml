/// obj_dialog :: End Step

if (current_message < 0 || current_message >= array_length(messages)) { // Added check for messages array
    // If current_message is invalid (e.g. -1 from Create or out of bounds after advancing)
    // and there are no messages, or if it's already been destroyed, exit.
    // This can prevent errors if instance_destroy was called but End Step still runs once.
    if (!instance_exists(id) || array_length(messages) == 0) {
        exit;
    }
    // If current_message is somehow invalid but messages exist, try to recover or destroy.
    // For now, this implies the dialog might be finishing or in an error state.
    // If current_message became >= array_length(messages) it means it should destroy in the advance logic.
    // If it's still < 0 it means it hasn't started.
    if (current_message < 0) exit; // Not yet started
}


var _str = messages[current_message].msg;
var _len = string_length(_str);

// Input for skipping crawl or advancing dialog (using player_index 0 by default)
var advance_input_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);

// --- Text Crawling ---
if (current_char < _len) {
    var speed_multiplier = 1;
    if (advance_input_pressed) { // Pressing confirm speeds up text crawl
        speed_multiplier = 10; // Or use a variable for "skip crawl speed"
         // audio_play_sound(snd_text_skip, 0, false); // Optional feedback
    }
    current_char += char_speed * speed_multiplier;
    current_char = min(current_char, _len); // Clamp to actual length
    draw_message = string_copy(_str, 0, ceil(current_char)); // Use ceil to ensure full chars are copied
}
// --- Advance Dialogue (if text is fully crawled AND confirm is pressed again) ---
else if (advance_input_pressed) { // current_char >= _len
    // audio_play_sound(snd_dialog_next, 0, false); // Optional sound for advancing

    // --- SCRIPT EXECUTION ---
    var _completed_message_index = current_message; // Store before incrementing
    var _msg_data = messages[_completed_message_index];

    if (variable_struct_exists(_msg_data, "script_to_run")) {
        var _script_asset = _msg_data.script_to_run; // 'script' renamed

        if (script_exists(_script_asset)) {
            var _args_array = variable_struct_get(_msg_data, "script_args"); // Get args, will be 'undefined' if not present
            if (!is_array(_args_array) && !is_undefined(_args_array)) { // If it exists but isn't an array
                show_debug_message("Dialog Warning: script_args for message " + string(_completed_message_index) + " is not an array. Ignoring args.");
                _args_array = undefined; // Treat as no args
            }

            show_debug_message("Dialog: Executing script '" + script_get_name(_script_asset) + "' after message index " + string(_completed_message_index) + 
                               ((_args_array != undefined) ? (" with args: " + string(_args_array)) : " (no args)."));

            if (_args_array != undefined) { // Has arguments
                var _num_args = array_length(_args_array);
                switch (_num_args) {
                    case 0: script_execute(_script_asset); break;
                    case 1: script_execute(_script_asset, _args_array[0]); break;
                    case 2: script_execute(_script_asset, _args_array[0], _args_array[1]); break;
                    case 3: script_execute(_script_asset, _args_array[0], _args_array[1], _args_array[2]); break;
                    // Add more cases as needed for your game
                    // case 4: script_execute(_script_asset, _args_array[0], _args_array[1], _args_array[2], _args_array[3]); break;
                    default:
                        show_debug_message("Dialog Warning: Script '" + script_get_name(_script_asset) + "' called with " + string(_num_args) + 
                                           " arguments. Max handled in switch is 3. Attempting with first 3 or fewer.");
                        // Fallback for more than 3 args, or adapt as needed
                        if (_num_args >= 3) script_execute(_script_asset, _args_array[0], _args_array[1], _args_array[2]);
                        else if (_num_args == 2) script_execute(_script_asset, _args_array[0], _args_array[1]);
                        else if (_num_args == 1) script_execute(_script_asset, _args_array[0]);
                        else script_execute(_script_asset); // Should be caught by case 0
                        break;
                }
            } else { // No arguments defined for the script
                script_execute(_script_asset);
            }
        } else if (!is_undefined(_script_asset) && _script_asset != -1 && _script_asset != noone) { // script_to_run was defined but script doesn't exist
             show_debug_message("Dialog Warning: Script specified for message " + string(_completed_message_index) + 
                               " (asset value: " + string(_script_asset) + ") does not exist!");
        }
    }

    // --- Advance to next message or end dialog ---
    current_message++; // Advance internal message counter

    if (current_message >= array_length(messages)) { // All messages shown
        instance_destroy(); // Destroy the dialog object
        // Any post-dialog actions (like reactivating player if dialog pauses game)
        // should be handled by the script that was run, or by the object that created the dialog.
    } else { // More messages to show
        current_char = 0; // Reset character crawl for the new message
        draw_message = ""; // Clear the drawn message
    }
}
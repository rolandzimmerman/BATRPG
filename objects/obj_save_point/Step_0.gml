/// obj_save_point :: Step Event

// Assuming player_index 0 for gamepad inputs by default in input functions
var interact_pressed = input_check_pressed(INPUT_ACTION.INTERACT); // For initial interaction
var left_pressed = input_check_pressed(INPUT_ACTION.MENU_LEFT);     // For YES/NO
var right_pressed = input_check_pressed(INPUT_ACTION.MENU_RIGHT);    // For YES/NO
var confirm_menu_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM); // For menu choices

switch (state) {
    case "idle":
        // Player needs to be close and press interact
        if (interact_pressed && place_meeting(x, y, obj_player)) {
            state = "fading_out";
            fade_alpha = 0;
            menu_choice = 0; // Default to "YES" (Save)
            if (audio_exists(snd_sleep)) audio_play_sound(snd_sleep, 1, false);
        }
        break;

    case "fading_out":
        fade_alpha = min(fade_alpha + 0.05, 1);
        if (fade_alpha >= 1) {
            state = "menu";
            // Optional: Deactivate player here if not already handled by a global pause
            // if (instance_exists(obj_player)) instance_deactivate_object(obj_player);
        }
        break;

    case "menu":
        // Navigate YES (0) / NO (1) choice
        // Using left_pressed for YES and right_pressed for NO as per original logic
        if (left_pressed && menu_choice == 1) { // If on NO, move to YES
             menu_choice = 0;
             // audio_play_sound(snd_menu_cursor, 0, false);
        }
        if (right_pressed && menu_choice == 0) { // If on YES, move to NO
             menu_choice = 1;
             // audio_play_sound(snd_menu_cursor, 0, false);
        }
        
        // Confirm choice (Save or Don't Save/Heal)
        if (confirm_menu_pressed) {
            if (menu_choice == 0) { // YES - Save Game
                if (script_exists(scr_save_game)) { // Check if script exists
                    if (scr_save_game(save_filename)) { // save_filename should be defined in Create
                        show_debug_message("Save Point: Game Saved to " + save_filename);
                        // Potentially show a "Game Saved!" message via dialog or on-screen text
                    } else {
                        show_debug_message("Save Point: Save FAILED!");
                        // Potentially show a "Save Failed!" message
                    }
                } else {
                     show_debug_message("Save Point: scr_save_game script not found!");
                }
            }
            // Whether saved (menu_choice == 0) or not (menu_choice == 1), still heal the party.
            // The original code healed regardless of save choice if confirm was pressed.
            show_debug_message("Save Point: Healing party.");
            var stats_map_id = global.party_current_stats; // Use direct global reference if it's always a ds_map ID

            // Check if global.party_current_stats is a valid ds_map
            if (ds_exists(stats_map_id, ds_type_map)) {
                var current_char_key = ds_map_find_first(stats_map_id);
                while (!is_undefined(current_char_key)) {
                    var char_stats_struct = ds_map_find_value(stats_map_id, current_char_key);
                    if (is_struct(char_stats_struct)) { // Ensure 's' is a struct
                        if (variable_struct_exists(char_stats_struct, "maxhp")) {
                            char_stats_struct.hp = char_stats_struct.maxhp;
                        }
                        if (variable_struct_exists(char_stats_struct, "maxmp")) {
                            char_stats_struct.mp = char_stats_struct.maxmp;
                        }
                        // No need to ds_map_replace if char_stats_struct is the actual struct from the map,
                        // as modifications to it directly change the struct in the map.
                    }
                    current_char_key = ds_map_find_next(stats_map_id, current_char_key);
                }
                show_debug_message("Save Point: Party healing applied.");
            } else {
                 show_debug_message("Save Point: global.party_current_stats is not a valid ds_map or does not exist. Cannot heal party.");
            }
            
            state = "fading_in";
            // audio_play_sound(snd_menu_select, 0, false); // Or a save confirmation sound
        }
        
        // Optional: Allow cancelling from the YES/NO menu to go back to fading_in without saving/healing
        // var cancel_menu_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL);
        // if (cancel_menu_pressed) {
        //     state = "fading_in";
        //     // audio_play_sound(snd_menu_cancel, 0, false);
        // }
        break;

    case "fading_in":
        fade_alpha = max(fade_alpha - 0.05, 0);
        if (fade_alpha <= 0) {
            state = "idle";
            // Optional: Reactivate player here if it was deactivated in "fading_out"
            // if (instance_exists(obj_player)) instance_activate_object(obj_player);
        }
        break;
}
/// obj_party_menu :: Step Event
if (!active) return; // Assuming 'active' is an instance variable initialized in Create

// input (assuming player_index 0 for gamepad inputs by default)
var up_pressed = input_check_pressed(INPUT_ACTION.MENU_UP);
var down_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN);
var confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);
var back_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL);

// Ensure global.party_members exists and is an array before trying to get its length
var count = 0;
if (variable_global_exists("party_members") && is_array(global.party_members)) {
    count = array_length(global.party_members);
} else {
    show_debug_message("ERROR [obj_party_menu]: global.party_members does not exist or is not an array!");
    // Fallback or error handling if party_members isn't set up
    if (instance_exists(calling_menu)) calling_menu.active = true;
    else if (instance_exists(obj_game_manager)) obj_game_manager.game_state = "playing"; // Fallback unpause
    instance_destroy();
    exit;
}

// Ensure menu_index and selected_index are initialized and valid
member_index = member_index ?? 0; // Should be initialized in Create
selected_index = selected_index ?? -1; // Should be initialized in Create, -1 indicates none selected yet

if (count > 0) {
    member_index = clamp(member_index, 0, count - 1);
    // selected_index will be validated when used
} else {
    // No members to choose from, pressing back should still work.
    if (back_pressed) {
        show_debug_message("Party Menu: Canceled (no party members).");
        if (instance_exists(calling_menu)) calling_menu.active = true;
        else if (instance_exists(obj_game_manager)) obj_game_manager.game_state = "playing";
        instance_destroy();
        exit;
    }
    // If confirm is pressed with no members, do nothing or give feedback
    if (confirm_pressed) {
        // audio_play_sound(snd_menu_error, 0, false);
    }
    // Prevent further processing if no members
    exit;
}


switch (menu_state) { // Assuming 'menu_state' is initialized in Create
    // ── Pick the first slot ───────────────────────────────────────────────
    case "choose_first":
        if (up_pressed) {
            member_index = (member_index - 1 + count) mod count;
            // audio_play_sound(snd_menu_cursor, 0, false);
        }
        if (down_pressed) {
            member_index = (member_index + 1) mod count;
            // audio_play_sound(snd_menu_cursor, 0, false);
        }

        if (confirm_pressed) {
            selected_index = member_index;
            menu_state = "choose_second";
            show_debug_message("Party Menu: First slot selected = index " + string(selected_index) + " (Member: " + string(global.party_members[selected_index]) + ")");
            // audio_play_sound(snd_menu_select, 0, false);
        }
        break;

    // ── Pick the second slot and swap ─────────────────────────────────────
    case "choose_second":
        if (up_pressed) {
            member_index = (member_index - 1 + count) mod count;
            // audio_play_sound(snd_menu_cursor, 0, false);
        }
        if (down_pressed) {
            member_index = (member_index + 1) mod count;
            // audio_play_sound(snd_menu_cursor, 0, false);
        }

        if (confirm_pressed) {
            if (member_index != selected_index) {
                show_debug_message("Party Menu: Second slot selected = index " + string(member_index) + " (Member: " + string(global.party_members[member_index]) + ")");
                // Swap in the global array
                var temp_member = global.party_members[selected_index];
                global.party_members[selected_index] = global.party_members[member_index];
                global.party_members[member_index]  = temp_member;
                
                // audio_play_sound(snd_menu_confirm_swap, 1, false); // Different sound for swap
                show_debug_message("Party Menu: Swapped members at indices " + string(selected_index) + " and " + string(member_index));
            } else {
                show_debug_message("Party Menu: Same member selected twice. No swap.");
                // audio_play_sound(snd_menu_cancel, 0, false); // Or a "selection cleared" sound
            }
            
            // Return to the calling menu (e.g., pause menu) or unpause game
            if (instance_exists(calling_menu)) {
                 if (variable_instance_exists(calling_menu, "active")) calling_menu.active = true;
            } else if (instance_exists(obj_game_manager)) { // Fallback if no calling_menu
                obj_game_manager.game_state = "playing";
                instance_activate_all(); // Ensure player etc. are active
            }
            instance_destroy(); // Destroy party menu
            exit; // Exit step event
        }
        break;
    
    default: // Should not happen if menu_state is initialized properly
        show_debug_message("ERROR [obj_party_menu]: Unknown menu_state: " + string(menu_state));
        menu_state = "choose_first"; // Reset to a known state
        break;
}

// Cancel action (back to pause menu or unpause game)
if (back_pressed) {
    show_debug_message("Party Menu: 'Back' pressed. Current state: " + menu_state);
    // audio_play_sound(snd_menu_cancel, 0, false);
    
    if (menu_state == "choose_second") {
        // If choosing the second member, "back" should return to choosing the first member
        menu_state = "choose_first";
        member_index = selected_index; // Optionally reset cursor to the first selected member
        selected_index = -1; // Clear first selection
        show_debug_message(" -> Returned to 'choose_first' state.");
    } else { // If in "choose_first" state, or any other, exit the party menu
        if (instance_exists(calling_menu)) {
            if (variable_instance_exists(calling_menu, "active")) calling_menu.active = true;
        } else if (instance_exists(obj_game_manager)) { // Fallback
            obj_game_manager.game_state = "playing";
            instance_activate_all();
        }
        instance_destroy(); // Destroy party menu
        exit; // Exit step event
    }
}
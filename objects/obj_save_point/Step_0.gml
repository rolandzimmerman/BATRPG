/// obj_save_point :: Step Event
/// Handle fade-out, left/right to select, Confirm (A button) to save/heal, then fade-in.
/// Interact (Y button) to start.

// --- Input Definitions ---
// For navigating Yes/No choice in the menu
var _nav_left_pressed = keyboard_check_pressed(vk_left) || gamepad_button_check_pressed(0, gp_padl);
var _nav_right_pressed = keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(0, gp_padr);

// For INITIATING interaction with the save point (Y button / Enter)
var _interact_pressed = keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(0, gp_face4);

// For CONFIRMING a choice within the save menu (A button / Space)
var _confirm_choice_pressed = keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
// Optional: Allow Enter to also confirm choices in the menu if desired
// var _confirm_choice_pressed = keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(0, gp_face1);


switch (state) { // Assuming 'state' is an instance variable initialized in Create Event

    case "idle":
        // Overlap & Y button (or Enter) to start fade-out
        if (place_meeting(x, y, obj_player) && _interact_pressed) {
            state = "fading_out";
            fade_alpha = 0; // Assuming 'fade_alpha' is an instance variable
            // Assuming 'menu_choice' is initialized (e.g., to 0 for "Yes") when menu opens
            menu_choice = 0; // Default to "Yes" when menu is about to open
            audio_play_sound(snd_sleep, 1, false); // Ensure snd_sleep exists
        }
        break;

    case "fading_out":
        // Fade to black
        fade_alpha = min(fade_alpha + 0.05, 1);
        if (fade_alpha >= 1) {
            state = "menu";
        }
        break;

    case "menu":
        // LEFT/RIGHT to toggle Yes(0)/No(1)
        if (_nav_left_pressed) {
            menu_choice = max(0, menu_choice - 1); // Navigate left, clamp at "Yes" (0)
        }
        if (_nav_right_pressed) {
            menu_choice = min(1, menu_choice + 1); // Navigate right, clamp at "No" (1)
        }

        // A button (or Space) to confirm choice
        if (_confirm_choice_pressed) {
            // If Yes, save game
            if (menu_choice == 0) { // "Yes" selected
                if (script_exists(scr_save_game)) {
                    scr_save_game(save_filename); // Ensure 'save_filename' instance var is set
                    show_debug_message("Game Saved to: " + save_filename);
                } else {
                    show_debug_message("ERROR: scr_save_game script missing!");
                }
            }
            // Else ("No" selected), it will just proceed to heal and fade in.

            // Heal DS-map entries for party stats
            if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
                var m = global.party_current_stats;
                var cnt = ds_map_size(m);
                var key = (cnt > 0) ? ds_map_find_first(m) : undefined;
                repeat(cnt) {
                    if (key == undefined) break; // Safety break
                    var st = ds_map_find_value(m, key);
                    if (is_struct(st)) {
                        if (variable_struct_exists(st, "maxhp")) st.hp = st.maxhp;
                        if (variable_struct_exists(st, "maxmp")) st.mp = st.maxmp;
                        // No need to ds_map_replace if 'st' is a direct reference to the struct in the map,
                        // but if it's a copy, then ds_map_replace(m, key, st) would be needed.
                        // Assuming direct modification works for structs in DS maps in your GM version.
                    }
                    key = ds_map_find_next(m, key);
                }
                show_debug_message("Party stats in DS Map healed.");
            }

            // Heal live party instances (if they exist, e.g., in battle or if player object is complex)
            // This part seems more relevant if this save point could be accessed during/after battle
            // before returning to map, or if party members are actual instances on the map.
            // For a typical overworld save point, usually only DS map stats are relevant.
            if (variable_global_exists("party_members") && is_array(global.party_members)) {
                for (var i = 0; i < array_length(global.party_members); i++) {
                    // This assumes global.party_members holds INSTANCE IDs of active party objects.
                    // If it holds character keys, you'd iterate through active player objects.
                    var p_instance_id_or_key = global.party_members[i];
                    var p_instance = noone;

                    if (is_real(p_instance_id_or_key) && instance_exists(p_instance_id_or_key)) {
                        p_instance = p_instance_id_or_key;
                    } 
                    // Else, if it stores keys, you might need a way to find the player instance by key.
                    // For now, assuming direct instance IDs if this code is to work as written.

                    if (instance_exists(p_instance) && 
                        variable_instance_exists(p_instance, "data") && 
                        is_struct(p_instance.data)) {
                        
                        if (variable_struct_exists(p_instance.data, "maxhp")) p_instance.data.hp = p_instance.data.maxhp;
                        if (variable_struct_exists(p_instance.data, "maxmp")) p_instance.data.mp = p_instance.data.maxmp;
                        show_debug_message("Healed live instance: " + string(p_instance));
                    }
                }
            }

            // Immediately fade back in
            state = "fading_in";
        }
        break;

    case "fading_in":
        // Fade back to gameplay
        fade_alpha = max(fade_alpha - 0.05, 0);
        if (fade_alpha <= 0) {
            fade_alpha = 0;
            state = "idle";
        }
        break;
}
/// obj_save_point Step Event
var _interact = keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(0, gp_face4);

switch (state) {
    case "idle":
        if (_interact && place_meeting(x, y, obj_player)) {
            state = "fading_out";
            fade_alpha = 0;
            menu_choice = 0;
            if (audio_exists(snd_sleep)) audio_play_sound(snd_sleep,1,false);
        }
        break;

    case "fading_out":
        fade_alpha = min(fade_alpha + 0.05, 1);
        if (fade_alpha >= 1) state = "menu";
        break;

    case "menu":
        // Left/Right to choose Yes(0)/No(1)
        if (keyboard_check_pressed(vk_left)  || gamepad_button_check_pressed(0, gp_padl)) menu_choice = 0;
        if (keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(0, gp_padr)) menu_choice = 1;
        // Confirm
        if (keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1)) {
            if (menu_choice == 0) {
                if (scr_save_game(save_filename)) show_debug_message("Game Saved!");
                else show_debug_message("Save FAILED!");
            }
            // Heal party
            var stats_id = variable_global_get("party_current_stats");
            if (is_real(stats_id) && ds_exists(stats_id, ds_type_map)) {
                var key = ds_map_find_first(stats_id);
                while (!is_undefined(key)) {
                    var s = ds_map_find_value(stats_id, key);
                    if (variable_struct_exists(s,"maxhp")) s.hp = s.maxhp;
                    if (variable_struct_exists(s,"maxmp")) s.mp = s.maxmp;
                    key = ds_map_find_next(stats_id, key);
                }
            }
            state = "fading_in";
        }
        break;

    case "fading_in":
        fade_alpha = max(fade_alpha - 0.05, 0);
        if (fade_alpha <= 0) state = "idle";
        break;
}

// (Keep your existing Draw GUI code here)

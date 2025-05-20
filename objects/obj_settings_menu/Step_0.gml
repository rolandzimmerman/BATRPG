/// obj_settings_menu :: Step Event

// If the menu is not active, don't process any input or logic for it
if (!active) { // 'active' is an instance variable, should be initialized in Create Event
    exit;
}

// Input cooldown for D-pad/key repeat to prevent overly fast scrolling
input_cooldown = max(0, input_cooldown - 1); // 'input_cooldown' is an instance variable

// --- Input Handling ---
// Local variables for this step's input states
var _up_pressed = (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")) || (gamepad_button_check_pressed(0, gp_padu) && input_cooldown == 0));
var _down_pressed = (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")) || (gamepad_button_check_pressed(0, gp_padd) && input_cooldown == 0));
var _left_pressed = (keyboard_check_pressed(vk_left) || keyboard_check_pressed(ord("A")) || (gamepad_button_check_pressed(0, gp_padl)));
var _right_pressed = (keyboard_check_pressed(vk_right) || keyboard_check_pressed(ord("D")) || (gamepad_button_check_pressed(0, gp_padr)));
var _confirm_pressed = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
var _back_pressed = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_face2);

var _nav_cooldown_time = 8; // Local constant for cooldown duration

// --- Handle Dropdown Navigation First (if a dropdown is open) ---
// Instance variables: dropdown_display_open, dropdown_display_index, dropdown_display_options,
// dropdown_resolution_open, global.resolution_index, global.resolution_options, dropdown_hover_index
if (dropdown_display_open) {
    if (_up_pressed) {
        dropdown_display_index = (dropdown_display_index - 1 + array_length(dropdown_display_options)) mod array_length(dropdown_display_options);
        dropdown_hover_index = dropdown_display_index;
        input_cooldown = _nav_cooldown_time;
    }
    if (_down_pressed) {
        dropdown_display_index = (dropdown_display_index + 1) mod array_length(dropdown_display_options);
        dropdown_hover_index = dropdown_display_index;
        input_cooldown = _nav_cooldown_time;
    }
    if (_confirm_pressed) {
        global.display_mode = dropdown_display_options[dropdown_display_index];
        if (script_exists(apply_display_mode)) apply_display_mode(global.display_mode);
        if (script_exists(save_settings_ini)) save_settings_ini();
        dropdown_display_open = false; 
        dropdown_hover_index = -1;
    }
    if (_back_pressed) {
        dropdown_display_open = false; 
        dropdown_hover_index = -1;
    }
    if (_up_pressed || _down_pressed || _confirm_pressed || _back_pressed) {
        exit; 
    }
} else if (dropdown_resolution_open) {
    if (_up_pressed) {
        global.resolution_index = (global.resolution_index - 1 + array_length(global.resolution_options)) mod array_length(global.resolution_options);
        dropdown_hover_index = global.resolution_index;
        input_cooldown = _nav_cooldown_time;
    }
    if (_down_pressed) {
        global.resolution_index = (global.resolution_index + 1) mod array_length(global.resolution_options);
        dropdown_hover_index = global.resolution_index;
        input_cooldown = _nav_cooldown_time;
    }
    if (_confirm_pressed) {
        var res = global.resolution_options[global.resolution_index]; // res is local
        if (script_exists(apply_resolution)) apply_resolution(res[0], res[1]);
        if (script_exists(save_settings_ini)) save_settings_ini();
        dropdown_resolution_open = false;
        dropdown_hover_index = -1;
    }
    if (_back_pressed) {
        dropdown_resolution_open = false;
        dropdown_hover_index = -1;
    }
    if (_up_pressed || _down_pressed || _confirm_pressed || _back_pressed) {
        exit; 
    }
}

// --- Main Menu Navigation (if no dropdowns are active) ---
// Instance variables: settings_index, menu_item_count
if (_up_pressed) {
    settings_index = (settings_index - 1 + menu_item_count) mod menu_item_count;
    input_cooldown = _nav_cooldown_time;
}
if (_down_pressed) {
    settings_index = (settings_index + 1) mod menu_item_count;
    input_cooldown = _nav_cooldown_time;
}

/// — Handle Confirm (“A”/Enter) ——
if (_confirm_pressed) {
    input_cooldown = 8;
    var item = settings_items[settings_index];
    switch (item) {
        case "Back":
            show_debug_message("Settings: Back confirmed.");
            active = false;

            // reactivate pause menu
            if (instance_exists(opened_by_instance_id)) {
                with (opened_by_instance_id) {
                    active = true;
                }
                show_debug_message("Settings: reactivated pause_menu id=" + string(opened_by_instance_id));
            }
            else {
                // fallback to title
                var fb = instance_find(obj_title_menu, 0);
                if (fb != noone) {
                    with (fb) active = true;
                    show_debug_message("Settings: fallback reactivated title_menu id=" + string(fb));
                }
            }

            // now remove settings
            instance_destroy();
            exit;
            break;

        case "Display Mode":
            dropdown_display_open    = !dropdown_display_open;
            dropdown_resolution_open = false;
            dropdown_hover_index     = dropdown_display_open ? dropdown_display_index : -1;
            break;

        case "Resolution":
            dropdown_resolution_open = !dropdown_resolution_open;
            dropdown_display_open    = false;
            dropdown_hover_index     = dropdown_resolution_open ? global.resolution_index : -1;
            break;
    }
}

/// — Handle ESC/B (“Back” button) exactly like above —
if (_back_pressed && !dropdown_display_open && !dropdown_resolution_open) {
    show_debug_message("Settings: ESC/B pressed.");
    active = false;

    if (instance_exists(opened_by_instance_id)) {
        with (opened_by_instance_id) active = true;
    } else {
        var fb2 = instance_find(obj_title_menu, 0);
        if (fb2 != noone) with (fb2) active = true;
    }

    instance_destroy();
    exit;
}

// Handle Left/Right for sliders (Volume controls)
if (_left_pressed || _right_pressed) {
    var change_amount = 0.05; // local
    // VVVV CORRECTED VARIABLE NAME VVVV
    var _lr_direction = _right_pressed - _left_pressed; // Will be 1 for right, -1 for left
    var current_setting_item = settings_items[settings_index];
    switch (current_setting_item) {
        case "SFX Volume":
            global.sfx_volume = clamp(global.sfx_volume + (_lr_direction * change_amount), 0, 1);
            // audio_play_sound(snd_ui_tick, 0, false); // Example sound
            if (script_exists(save_settings_ini)) save_settings_ini();
            // input_cooldown = _nav_cooldown_time / 2; // Optional: Shorter cooldown for sliders
            break;

        case "Music Volume":
            global.music_volume = clamp(global.music_volume + (_lr_direction * change_amount), 0, 1);
            // audio_play_sound(snd_ui_tick, 0, false);
            if (script_exists(save_settings_ini)) save_settings_ini();
            // input_cooldown = _nav_cooldown_time / 2;
            break;
    }
}
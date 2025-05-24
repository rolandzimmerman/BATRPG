/// obj_settings_menu :: Step Event

// If the menu is not active, don't process any input or logic for it
if (!active) {
    exit;
}

// Input cooldown for D-pad/key repeat to prevent overly fast scrolling
input_cooldown = max(0, input_cooldown - 1); 
var _nav_cooldown_time = 8; // Local constant for cooldown duration

// --- Input Handling ---
var gp_idx = global.gamepad_player_map[0]; // Assuming player 0 for menus
var map_menu_up = global.input_mappings[INPUT_ACTION.MENU_UP];
var map_menu_down = global.input_mappings[INPUT_ACTION.MENU_DOWN];

// Up Pressed - with specific cooldown logic for gamepad
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
var _up_input_this_step = _kb_up_pressed || (_gp_up_pressed_raw && input_cooldown == 0); // Renamed to avoid conflict

// Down Pressed - with specific cooldown logic for gamepad
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
var _down_input_this_step = _kb_down_pressed || (_gp_down_pressed_raw && input_cooldown == 0); // Renamed

// Other inputs (no special cooldown logic in their definition lines)
var _left_input_this_step = input_check_pressed(INPUT_ACTION.MENU_LEFT, 0);    // Renamed
var _right_input_this_step = input_check_pressed(INPUT_ACTION.MENU_RIGHT, 0);   // Renamed
var _confirm_input_this_step = input_check_pressed(INPUT_ACTION.MENU_CONFIRM, 0); // Renamed
var _back_input_this_step = input_check_pressed(INPUT_ACTION.MENU_CANCEL, 0);     // Renamed


// --- Handle Dropdown Navigation First (if a dropdown is open) ---
if (dropdown_display_open) {
    if (_up_input_this_step) {
        dropdown_display_index = (dropdown_display_index - 1 + array_length(dropdown_display_options)) mod array_length(dropdown_display_options);
        dropdown_hover_index = dropdown_display_index;
        input_cooldown = _nav_cooldown_time; // Reset cooldown on successful navigation
    }
    if (_down_input_this_step) {
        dropdown_display_index = (dropdown_display_index + 1) mod array_length(dropdown_display_options);
        dropdown_hover_index = dropdown_display_index;
        input_cooldown = _nav_cooldown_time; // Reset cooldown
    }
    if (_confirm_input_this_step) {
        global.display_mode = dropdown_display_options[dropdown_display_index];
        if (script_exists(apply_display_mode)) apply_display_mode(global.display_mode);
        if (script_exists(save_settings_ini)) save_settings_ini();
        dropdown_display_open = false; 
        dropdown_hover_index = -1;
        input_cooldown = _nav_cooldown_time; // Cooldown after confirm as well
    }
    if (_back_input_this_step) {
        dropdown_display_open = false; 
        dropdown_hover_index = -1;
        input_cooldown = _nav_cooldown_time; // Cooldown after back
    }
    // If any dropdown navigation happened, exit to prevent main menu navigation
    if (_up_input_this_step || _down_input_this_step || _confirm_input_this_step || _back_input_this_step) {
        exit; 
    }
} else if (dropdown_resolution_open) {
    if (_up_input_this_step) {
        global.resolution_index = (global.resolution_index - 1 + array_length(global.resolution_options)) mod array_length(global.resolution_options);
        dropdown_hover_index = global.resolution_index;
        input_cooldown = _nav_cooldown_time; // Reset cooldown
    }
    if (_down_input_this_step) {
        global.resolution_index = (global.resolution_index + 1) mod array_length(global.resolution_options);
        dropdown_hover_index = global.resolution_index;
        input_cooldown = _nav_cooldown_time; // Reset cooldown
    }
    if (_confirm_input_this_step) {
        var res = global.resolution_options[global.resolution_index];
        if (script_exists(apply_resolution)) apply_resolution(res[0], res[1]);
        if (script_exists(save_settings_ini)) save_settings_ini();
        dropdown_resolution_open = false;
        dropdown_hover_index = -1;
        input_cooldown = _nav_cooldown_time; // Cooldown
    }
    if (_back_input_this_step) {
        dropdown_resolution_open = false;
        dropdown_hover_index = -1;
        input_cooldown = _nav_cooldown_time; // Cooldown
    }
    // If any dropdown navigation happened, exit
    if (_up_input_this_step || _down_input_this_step || _confirm_input_this_step || _back_input_this_step) {
        exit; 
    }
}

// --- Main Menu Navigation (if no dropdowns are active) ---
if (_up_input_this_step) { // Uses the specifically constructed var
    settings_index = (settings_index - 1 + menu_item_count) mod menu_item_count;
    input_cooldown = _nav_cooldown_time; // Reset cooldown
}
if (_down_input_this_step) { // Uses the specifically constructed var
    settings_index = (settings_index + 1) mod menu_item_count;
    input_cooldown = _nav_cooldown_time; // Reset cooldown
}

// --- Handle Confirm ("A"/Enter) ---
if (_confirm_input_this_step) {
    input_cooldown = _nav_cooldown_time; // Original code had 8, using _nav_cooldown_time for consistency
    var item = settings_items[settings_index];
    switch (item) {
        case "Back":
            show_debug_message("Settings: Back confirmed.");
            active = false;
            if (instance_exists(opened_by_instance_id)) {
                with (opened_by_instance_id) {
                    if (variable_instance_exists(id, "active")) active = true;
                }
                show_debug_message("Settings: reactivated instance id=" + string(opened_by_instance_id));
            } else {
                var fb = instance_find(obj_title_menu, 0);
                if (fb != noone) {
                    with (fb) if (variable_instance_exists(id, "active")) active = true;
                    show_debug_message("Settings: fallback reactivated title_menu id=" + string(fb));
                }
            }
            instance_destroy();
            exit;
            break;

        case "Display Mode":
            dropdown_display_open = !dropdown_display_open;
            dropdown_resolution_open = false; // Close other dropdown
            dropdown_hover_index = dropdown_display_open ? dropdown_display_index : -1;
            break;

        case "Resolution":
            dropdown_resolution_open = !dropdown_resolution_open;
            dropdown_display_open = false; // Close other dropdown
            dropdown_hover_index = dropdown_resolution_open ? global.resolution_index : -1;
            break;
    }
}

// --- Handle ESC/B (“Back” button) for main menu ---
if (_back_input_this_step && !dropdown_display_open && !dropdown_resolution_open) {
    show_debug_message("Settings: ESC/B pressed on main settings list.");
    active = false;
    if (instance_exists(opened_by_instance_id)) {
        with (opened_by_instance_id) if (variable_instance_exists(id, "active")) active = true;
    } else {
        var fb2 = instance_find(obj_title_menu, 0);
        if (fb2 != noone) with (fb2) if (variable_instance_exists(id, "active")) active = true;
    }
    instance_destroy();
    exit;
}

// Handle Left/Right for sliders (Volume controls)
// These do not use the up/down input_cooldown logic as per original
if (_left_input_this_step || _right_input_this_step) {
    var change_amount = 0.05; 
    var _lr_direction = _right_input_this_step - _left_input_this_step; // 1 for right, -1 for left, 0 if both (or none)
    
    if (_lr_direction != 0) { // Only proceed if a clear direction is pressed
        var current_setting_item = settings_items[settings_index];
        switch (current_setting_item) {
            case "SFX Volume":
                global.sfx_volume = clamp(global.sfx_volume + (_lr_direction * change_amount), 0, 1);
                // audio_play_sound(snd_ui_tick, 0, false); 
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
}
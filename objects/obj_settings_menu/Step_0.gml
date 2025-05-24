/// obj_settings_menu :: Step Event

// If the menu is not active, don't process any input or logic for it
if (!active) { // Assuming 'active' is an instance variable
    exit;
}

// Input cooldown for D-pad/key repeat to prevent overly fast scrolling
input_cooldown = max(0, input_cooldown - 1); 
var _nav_cooldown_time = 8; // Local constant for cooldown duration

// --- Input Handling (Simplified - Cooldown applies to the action universally for up/down) ---
// Assuming player_index 0 for all menu inputs
var up_action_pressed = input_check_pressed(INPUT_ACTION.MENU_UP, 0);
var down_action_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN, 0);
var left_action_pressed = input_check_pressed(INPUT_ACTION.MENU_LEFT, 0);
var right_action_pressed = input_check_pressed(INPUT_ACTION.MENU_RIGHT, 0);
var confirm_action_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM, 0);
var back_action_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL, 0);

// Apply cooldown to up/down navigation actions
var _up_input_this_step = up_action_pressed && (input_cooldown == 0);
var _down_input_this_step = down_action_pressed && (input_cooldown == 0);

// Other actions might not use this specific 'input_cooldown' for their condition,
// but might reset it upon action.
var _left_input_this_step = left_action_pressed; // Cooldown not applied here in original logic for left/right
var _right_input_this_step = right_action_pressed; // Cooldown not applied here
var _confirm_input_this_step = confirm_action_pressed;
var _back_input_this_step = back_action_pressed;


// --- Handle Dropdown Navigation First (if a dropdown is open) ---
if (dropdown_display_open) {
    if (_up_input_this_step) { // Cooldown is now included
        dropdown_display_index = (dropdown_display_index - 1 + array_length(dropdown_display_options)) mod array_length(dropdown_display_options);
        dropdown_hover_index = dropdown_display_index;
        input_cooldown = _nav_cooldown_time; 
    }
    if (_down_input_this_step) { // Cooldown is now included
        dropdown_display_index = (dropdown_display_index + 1) mod array_length(dropdown_display_options);
        dropdown_hover_index = dropdown_display_index;
        input_cooldown = _nav_cooldown_time; 
    }
    if (_confirm_input_this_step) {
        global.display_mode = dropdown_display_options[dropdown_display_index];
        if (script_exists(apply_display_mode)) apply_display_mode(global.display_mode);
        if (script_exists(save_settings_ini)) save_settings_ini();
        dropdown_display_open = false; 
        dropdown_hover_index = -1;
        input_cooldown = _nav_cooldown_time; 
    }
    if (_back_input_this_step) {
        dropdown_display_open = false; 
        dropdown_hover_index = -1;
        input_cooldown = _nav_cooldown_time; 
    }
    if (up_action_pressed || down_action_pressed || _confirm_input_this_step || _back_input_this_step) { // Check raw action press if exiting
        exit; 
    }
} else if (dropdown_resolution_open) {
    if (_up_input_this_step) { // Cooldown is now included
        global.resolution_index = (global.resolution_index - 1 + array_length(global.resolution_options)) mod array_length(global.resolution_options);
        dropdown_hover_index = global.resolution_index;
        input_cooldown = _nav_cooldown_time; 
    }
    if (_down_input_this_step) { // Cooldown is now included
        global.resolution_index = (global.resolution_index + 1) mod array_length(global.resolution_options);
        dropdown_hover_index = global.resolution_index;
        input_cooldown = _nav_cooldown_time; 
    }
    if (_confirm_input_this_step) {
        var res = global.resolution_options[global.resolution_index];
        if (script_exists(apply_resolution)) apply_resolution(res[0], res[1]);
        if (script_exists(save_settings_ini)) save_settings_ini();
        dropdown_resolution_open = false;
        dropdown_hover_index = -1;
        input_cooldown = _nav_cooldown_time; 
    }
    if (_back_input_this_step) {
        dropdown_resolution_open = false;
        dropdown_hover_index = -1;
        input_cooldown = _nav_cooldown_time; 
    }
    if (up_action_pressed || down_action_pressed || _confirm_input_this_step || _back_input_this_step) { // Check raw action press if exiting
        exit; 
    }
}

// --- Main Menu Navigation (if no dropdowns are active) ---
if (_up_input_this_step) { // Cooldown is now included
    settings_index = (settings_index - 1 + menu_item_count) mod menu_item_count;
    input_cooldown = _nav_cooldown_time; 
}
if (_down_input_this_step) { // Cooldown is now included
    settings_index = (settings_index + 1) mod menu_item_count;
    input_cooldown = _nav_cooldown_time; 
}

// --- Handle Confirm ("A"/Enter) ---
if (_confirm_input_this_step) {
    input_cooldown = _nav_cooldown_time; 
    var item = settings_items[settings_index];
    switch (item) {
        case "Back":
            // ... (Your existing Back logic - unchanged) ...
            show_debug_message("Settings: Back confirmed.");
            active = false;
            if (instance_exists(opened_by_instance_id)) {
                with (opened_by_instance_id) {
                    if (variable_instance_exists(id, "active")) active = true;
                }
            } else {
                var fb = instance_find(obj_title_menu, 0);
                if (fb != noone) { with (fb) if (variable_instance_exists(id, "active")) active = true; }
            }
            instance_destroy();
            exit;
            break;
        case "Display Mode":
            // ... (Your existing Display Mode logic - unchanged) ...
            dropdown_display_open = !dropdown_display_open;
            dropdown_resolution_open = false; 
            dropdown_hover_index = dropdown_display_open ? dropdown_display_index : -1;
            break;
        case "Resolution":
            // ... (Your existing Resolution logic - unchanged) ...
            dropdown_resolution_open = !dropdown_resolution_open;
            dropdown_display_open = false; 
            dropdown_hover_index = dropdown_resolution_open ? global.resolution_index : -1;
            break;
    }
}

// --- Handle ESC/B (“Back” button) for main menu ---
if (_back_input_this_step && !dropdown_display_open && !dropdown_resolution_open) {
    // ... (Your existing Back button logic - unchanged) ...
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
if (_left_input_this_step || _right_input_this_step) { // These did not use input_cooldown in their condition
    var change_amount = 0.05; 
    var _lr_direction = _right_input_this_step - _left_input_this_step; 
    
    if (_lr_direction != 0) { 
        var current_setting_item = settings_items[settings_index];
        switch (current_setting_item) {
            case "SFX Volume":
                // ... (Your existing SFX Volume logic - unchanged) ...
                global.sfx_volume = clamp(global.sfx_volume + (_lr_direction * change_amount), 0, 1);
                if (script_exists(save_settings_ini)) save_settings_ini();
                break;
            case "Music Volume":
                // ... (Your existing Music Volume logic - unchanged) ...
                global.music_volume = clamp(global.music_volume + (_lr_direction * change_amount), 0, 1);
                if (script_exists(save_settings_ini)) save_settings_ini();
                break;
        }
    }
}
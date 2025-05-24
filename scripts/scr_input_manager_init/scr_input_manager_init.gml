// Script: scr_input_manager_init (or your chosen name for the input system script)
// Contains INPUT_ACTION enum, global input variable setup,
// scr_init_input_mappings() function, and all input helper functions.

// --- Input Action Enums ---
// Defines all bindable actions in the game.
enum INPUT_ACTION {
    // Player Movement & Actions (obj_player)
    MOVE_HORIZONTAL_AXIS, // For dir_x: returns float, use sign() for digital (-1 to 1)
    MOVE_VERTICAL_AXIS,   // For dir_y: returns float, use sign() for digital (-1 to 1)
    JUMP_FLAP,            // For flap/action button (pressed, held, released)
    DASH_LEFT,            // Pressed
    DASH_RIGHT,           // Pressed
    DIVE,                 // Pressed
    INTERACT,             // Pressed
    FIRE_MISSILE,         // Pressed
    PAUSE,                // Pressed (Escape, Gamepad Start)
    ANY_UP_HELD,          // Corresponds to key_up_held in obj_player
    ANY_DOWN_HELD,        // Corresponds to key_down_held in obj_player

    // Battle Menu Navigation (obj_battle_player) & General Menus
    MENU_CONFIRM,         // Pressed (Space, Enter, Gamepad A/X)
    MENU_CANCEL,          // Pressed (Escape, Gamepad B/Circle) - Also used as "Back"
    MENU_SKILL,           // Pressed (X key, Gamepad X/Square) - For battle
    MENU_ITEM,            // Pressed (Y key, Gamepad Y/Triangle) - For battle
    MENU_UP,              // Pressed (Up Arrow, W, Gamepad D-Pad Up)
    MENU_DOWN,            // Pressed (Down Arrow, S, Gamepad D-Pad Down)
    MENU_LEFT,            // Pressed (Left Arrow, A, Gamepad D-Pad Left) - For general menu/list navigation
    MENU_RIGHT,           // Pressed (Right Arrow, D, Gamepad D-Pad Right) - For general menu/list navigation
    MENU_PREVIOUS_CHARACTER, // For equipment menu party switch (L-Shoulder, KB Left Arrow or custom)
    MENU_NEXT_CHARACTER,   // For equipment menu party switch (R-Shoulder, KB Right Arrow or custom)
    
    // Miscellaneous Actions
    TOGGLE_MAP_OR_INFO,   // Pressed (M key, Gamepad Select/Back/View)

    _count                // Utility: number of actions. Keep this last.
}

// --- Global Input Variables Initialization ---
// These are defined OUTSIDE any function to ensure they are set when the script is first parsed.
show_debug_message("Defining global input system variables (from " + script_get_name(script_execute) + ")...");

// Create the array that will hold the mapping configurations.
if (!variable_global_exists("input_mappings") || !is_array(global.input_mappings) || array_length(global.input_mappings) != INPUT_ACTION._count) {
    global.input_mappings = array_create(INPUT_ACTION._count, undefined); // Initialize with undefined
    show_debug_message("   -> global.input_mappings array created/re-created with size: " + string(INPUT_ACTION._count));
} else {
    show_debug_message("   -> global.input_mappings array already exists (Size: " + string(array_length(global.input_mappings)) + ", Expected: " + string(INPUT_ACTION._count) + ")");
    // If sizes don't match due to adding enums without restarting game/re-running init script, resize it.
    if (array_length(global.input_mappings) != INPUT_ACTION._count) {
        array_resize(global.input_mappings, INPUT_ACTION._count);
        // New elements will be undefined, scr_init_input_mappings will fill them.
        show_debug_message("   -> global.input_mappings array resized to: " + string(INPUT_ACTION._count));
    }
}

// Maps logical player (array index 0-3) to actual gamepad slot (device 0-3).
if (!variable_global_exists("gamepad_player_map")) {
    global.gamepad_player_map = [0, 1, 2, 3]; 
    show_debug_message("   -> global.gamepad_player_map initialized.");
}

// Default deadzone values for gamepad analog sticks
if (!variable_global_exists("input_gamepad_deadzone_light")) {
    global.input_gamepad_deadzone_light = 0.25;
    show_debug_message("   -> global.input_gamepad_deadzone_light initialized.");
}
if (!variable_global_exists("input_gamepad_deadzone_strong")) {
    global.input_gamepad_deadzone_strong = 0.5;
    show_debug_message("   -> global.input_gamepad_deadzone_strong initialized.");
}


/// @function scr_init_input_mappings()
/// @description Initializes/Re-initializes the default keyboard and gamepad mappings for all actions.
/// Call this from obj_init or whenever mappings need to be reset to default.
function scr_init_input_mappings() {
    show_debug_message("Executing scr_init_input_mappings()...");
    
    var m = global.input_mappings; // Shortcut to the globally defined array

    // --- Player Movement & Actions ---
    m[INPUT_ACTION.MOVE_HORIZONTAL_AXIS] = { is_axis: true, kb_positive_keys: [ord("D")], kb_negative_keys: [ord("A")], gp_axis: gp_axislh, gp_positive_buttons: [gp_padr], gp_negative_buttons: [gp_padl], deadzone: global.input_gamepad_deadzone_light };
    m[INPUT_ACTION.MOVE_VERTICAL_AXIS] = { is_axis: true, kb_positive_keys: [ord("S")], kb_negative_keys: [ord("W")], gp_axis: gp_axislv, gp_positive_buttons: [gp_padd], gp_negative_buttons: [gp_padu], deadzone: global.input_gamepad_deadzone_light };
    m[INPUT_ACTION.JUMP_FLAP] = { is_axis: false, kb_keys: [vk_space], gp_buttons: [gp_face1] }; // South button
    m[INPUT_ACTION.DASH_LEFT] = { is_axis: false, kb_keys: [ord("Q")], gp_buttons: [gp_shoulderl] }; // Left bumper
    m[INPUT_ACTION.DASH_RIGHT] = { is_axis: false, kb_keys: [ord("E")], gp_buttons: [gp_shoulderr] }; // Right bumper
    m[INPUT_ACTION.DIVE] = { is_axis: false, kb_keys: [ord("B")], gp_buttons: [gp_face2] }; // East button
    m[INPUT_ACTION.INTERACT] = { is_axis: false, kb_keys: [vk_enter], gp_buttons: [gp_face4] }; // North button
    m[INPUT_ACTION.FIRE_MISSILE] = { is_axis: false, kb_keys: [ord("X")], gp_buttons: [gp_face3] }; // West button
    m[INPUT_ACTION.PAUSE] = { is_axis: false, kb_keys: [vk_escape], gp_buttons: [gp_start] };
    m[INPUT_ACTION.ANY_UP_HELD] = { is_axis: false, kb_keys: [vk_up, ord("W")], gp_buttons: [gp_padu], gp_axis_check: { axis: gp_axislv, direction: -1, threshold: global.input_gamepad_deadzone_strong } };
    m[INPUT_ACTION.ANY_DOWN_HELD] = { is_axis: false, kb_keys: [vk_down, ord("S")], gp_buttons: [gp_padd], gp_axis_check: { axis: gp_axislv, direction: 1, threshold: global.input_gamepad_deadzone_strong } };
    
    // --- Battle Menu / General Menu Navigation ---
    m[INPUT_ACTION.MENU_CONFIRM] = { is_axis: false, kb_keys: [vk_space, vk_enter], gp_buttons: [gp_face1] }; // South button
    m[INPUT_ACTION.MENU_CANCEL] = { is_axis: false, kb_keys: [vk_escape], gp_buttons: [gp_face2] }; // East button (also "Back")
    m[INPUT_ACTION.MENU_SKILL] = { is_axis: false, kb_keys: [ord("X")], gp_buttons: [gp_face3] }; // West button (Battle specific)
    m[INPUT_ACTION.MENU_ITEM] = { is_axis: false, kb_keys: [ord("Y")], gp_buttons: [gp_face4] }; // North button (Battle specific)
    m[INPUT_ACTION.MENU_UP] = { is_axis: false, kb_keys: [vk_up, ord("W")], gp_buttons: [gp_padu] };
    m[INPUT_ACTION.MENU_DOWN] = { is_axis: false, kb_keys: [vk_down, ord("S")], gp_buttons: [gp_padd] };
    m[INPUT_ACTION.MENU_LEFT] = { is_axis: false, kb_keys: [vk_left, ord("A")], gp_buttons: [gp_padl] }; // For general list nav, YES/NO
    m[INPUT_ACTION.MENU_RIGHT] = { is_axis: false, kb_keys: [vk_right, ord("D")], gp_buttons: [gp_padr] }; // For general list nav, YES/NO
    
    // Mappings for party switching in Equipment Menu
    m[INPUT_ACTION.MENU_PREVIOUS_CHARACTER] = { is_axis: false, kb_keys: [vk_left], gp_buttons: [gp_shoulderl] }; 
    m[INPUT_ACTION.MENU_NEXT_CHARACTER] = { is_axis: false, kb_keys: [vk_right], gp_buttons: [gp_shoulderr] };
    // Note: If vk_left/vk_right for party switching conflicts with other uses of MENU_LEFT/MENU_RIGHT
    // in the equipment menu, consider changing kb_keys for PREVIOUS/NEXT_CHARACTER to something like ord("Q")/ord("E").

    // --- Miscellaneous Actions ---
    m[INPUT_ACTION.TOGGLE_MAP_OR_INFO] = { is_axis: false, kb_keys: [ord("M")], gp_buttons: [gp_select] }; // Gamepad Select/Back/View
    
    show_debug_message("scr_init_input_mappings() completed successfully.");
}


// --- Input Checking Helper Functions ---

/// @function input_check_pressed(action_enum, [player_index=0])
/// @description Checks if the specified action was just pressed.
/// @param {INPUT_ACTION} action The action to check.
/// @param {Real} [player_index=0] The logical player index (0-3).
/// @returns {Bool}
function input_check_pressed(action, player_index = 0) {
    if (action < 0 || action >= INPUT_ACTION._count) { // Basic bounds check
        show_debug_message("Warning [input_check_pressed]: Invalid action enum value: " + string(action));
        return false;
    }
    var map = global.input_mappings[action];
    if (is_undefined(map)) {
        show_debug_message("Warning [input_check_pressed]: Input map undefined for action: " + string(action) + " (" + script_get_name(action) /*GMS2.3+*/ + ")");
        return false;
    }

    // Keyboard
    if (variable_struct_exists(map, "kb_keys")) {
        for (var i = 0; i < array_length(map.kb_keys); ++i) {
            if (keyboard_check_pressed(map.kb_keys[i])) return true;
        }
    }

    // Gamepad
    var gp_idx = global.gamepad_player_map[player_index];
    if (gp_idx >= 0 && gp_idx < gamepad_get_device_count() && gamepad_is_connected(gp_idx)) {
        if (variable_struct_exists(map, "gp_buttons")) {
            for (var i = 0; i < array_length(map.gp_buttons); ++i) {
                if (gamepad_button_check_pressed(gp_idx, map.gp_buttons[i])) return true;
            }
        }
    }
    return false;
}

/// @function input_check(action_enum, [player_index=0])
/// @description Checks if the specified action is currently held down.
/// @param {INPUT_ACTION} action The action to check.
/// @param {Real} [player_index=0] The logical player index (0-3).
/// @returns {Bool}
function input_check(action, player_index = 0) {
    if (action < 0 || action >= INPUT_ACTION._count) {
        show_debug_message("Warning [input_check]: Invalid action enum value: " + string(action));
        return false;
    }
    var map = global.input_mappings[action];
    if (is_undefined(map)) {
        show_debug_message("Warning [input_check]: Input map undefined for action: " + string(action) + " (" + script_get_name(action) /*GMS2.3+*/ + ")");
        return false;
    }

    // Keyboard
    if (variable_struct_exists(map, "kb_keys")) {
        for (var i = 0; i < array_length(map.kb_keys); ++i) {
            if (keyboard_check(map.kb_keys[i])) return true;
        }
    }
    
    // Gamepad
    var gp_idx = global.gamepad_player_map[player_index];
    if (gp_idx >= 0 && gp_idx < gamepad_get_device_count() && gamepad_is_connected(gp_idx)) {
        if (variable_struct_exists(map, "gp_buttons")) {
            for (var i = 0; i < array_length(map.gp_buttons); ++i) {
                if (gamepad_button_check(gp_idx, map.gp_buttons[i])) return true;
            }
        }
        if (variable_struct_exists(map, "gp_axis_check")) {
            var axis_config = map.gp_axis_check;
            var axis_val = gamepad_axis_value(gp_idx, axis_config.axis);
            if (axis_config.direction == -1 && axis_val < -axis_config.threshold) return true;
            if (axis_config.direction == 1 && axis_val > axis_config.threshold) return true;
        }
    }
    return false;
}

/// @function input_check_released(action_enum, [player_index=0])
/// @description Checks if the specified action was just released.
/// @param {INPUT_ACTION} action The action to check.
/// @param {Real} [player_index=0] The logical player index (0-3).
/// @returns {Bool}
function input_check_released(action, player_index = 0) {
    if (action < 0 || action >= INPUT_ACTION._count) {
        show_debug_message("Warning [input_check_released]: Invalid action enum value: " + string(action));
        return false;
    }
    var map = global.input_mappings[action];
    if (is_undefined(map)) {
        show_debug_message("Warning [input_check_released]: Input map undefined for action: " + string(action) + " (" + script_get_name(action) /*GMS2.3+*/ + ")");
        return false;
    }

    // Keyboard
    if (variable_struct_exists(map, "kb_keys")) {
        for (var i = 0; i < array_length(map.kb_keys); ++i) {
            if (keyboard_check_released(map.kb_keys[i])) return true;
        }
    }
    
    // Gamepad
    var gp_idx = global.gamepad_player_map[player_index];
     if (gp_idx >= 0 && gp_idx < gamepad_get_device_count() && gamepad_is_connected(gp_idx)) {
        if (variable_struct_exists(map, "gp_buttons")) {
            for (var i = 0; i < array_length(map.gp_buttons); ++i) {
                if (gamepad_button_check_released(gp_idx, map.gp_buttons[i])) return true;
            }
        }
    }
    return false;
}

/// @function input_get_axis(action_enum, [player_index=0])
/// @description Gets the value of an axis-type action.
/// prioritizes keyboard, then gamepad digital buttons, then gamepad analog stick.
/// @param {INPUT_ACTION} action The axis action to check.
/// @param {Real} [player_index=0] The logical player index (0-3).
/// @returns {Real} Value between -1.0 and 1.0.
function input_get_axis(action, player_index = 0) {
    if (action < 0 || action >= INPUT_ACTION._count) {
        show_debug_message("Warning [input_get_axis]: Invalid action enum value: " + string(action));
        return 0;
    }
    var map = global.input_mappings[action];
    if (is_undefined(map) || !(map.is_axis ?? false)) { 
        if(is_undefined(map)) show_debug_message("Warning [input_get_axis]: Input map undefined for axis action: " + string(action) + " (" + script_get_name(action) /*GMS2.3+*/ + ")");
        else if (!(map.is_axis ?? false)) show_debug_message("Warning [input_get_axis]: Action " + string(action) + " (" + script_get_name(action) /*GMS2.3+*/ + ") is not defined as an axis.");
        return 0;
    }

    var kb_val = 0;
    var gp_val_axis = 0;
    var gp_val_buttons = 0;
    
    // Keyboard
    if (variable_struct_exists(map, "kb_positive_keys")) {
        for (var i = 0; i < array_length(map.kb_positive_keys); ++i) {
            if (keyboard_check(map.kb_positive_keys[i])) { kb_val = 1; break; }
        }
    }
    if (kb_val == 0 && variable_struct_exists(map, "kb_negative_keys")) {
        for (var i = 0; i < array_length(map.kb_negative_keys); ++i) {
            if (keyboard_check(map.kb_negative_keys[i])) { kb_val = -1; break; }
        }
    }

    if (kb_val != 0) {
        return kb_val;
    }

    // Gamepad (only if keyboard is neutral)
    var gp_idx = global.gamepad_player_map[player_index];
    if (gp_idx >= 0 && gp_idx < gamepad_get_device_count() && gamepad_is_connected(gp_idx)) {
        // Gamepad D-Pad/Buttons for axis
        if (variable_struct_exists(map, "gp_positive_buttons")) {
            for (var i = 0; i < array_length(map.gp_positive_buttons); ++i) {
                if (gamepad_button_check(gp_idx, map.gp_positive_buttons[i])) { gp_val_buttons = 1; break; }
            }
        }
        if (gp_val_buttons == 0 && variable_struct_exists(map, "gp_negative_buttons")) {
            for (var i = 0; i < array_length(map.gp_negative_buttons); ++i) {
                if (gamepad_button_check(gp_idx, map.gp_negative_buttons[i])) { gp_val_buttons = -1; break; }
            }
        }
        
        if (gp_val_buttons != 0) {
            return gp_val_buttons;
        }

        // Gamepad Analog Axis
        if (variable_struct_exists(map, "gp_axis")) {
            gp_val_axis = gamepad_axis_value(gp_idx, map.gp_axis);
            var deadzone = map.deadzone ?? global.input_gamepad_deadzone_light; 
            if (abs(gp_val_axis) < deadzone) {
                gp_val_axis = 0;
            }
            if (gp_val_axis != 0) {
                 return gp_val_axis; 
            }
        }
    }
    return 0; 
}
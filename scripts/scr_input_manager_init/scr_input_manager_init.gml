// Script: scr_input_manager_init
// Contains enum definitions and initialization for the input system.

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
    PAUSE,                // Pressed
    ANY_UP_HELD,          // Corresponds to key_up_held in obj_player
    ANY_DOWN_HELD,        // Corresponds to key_down_held in obj_player

    // Battle Menu Navigation (obj_battle_player)
    MENU_CONFIRM,         // Pressed
    MENU_CANCEL,          // Pressed
    MENU_SKILL,           // Pressed
    MENU_ITEM,            // Pressed
    MENU_UP,              // Pressed
    MENU_DOWN,            // Pressed

    _count                // Utility: number of actions. Keep this last.
}

// --- Global Input Variables ---
// Initialize these once at game start by calling scr_init_input_mappings()

// This array will hold the mapping configuration for each INPUT_ACTION
global.input_mappings = array_create(INPUT_ACTION._count);

// Maps logical player (array index 0-3) to actual gamepad slot (device 0-3).
// Example: global.gamepad_player_map[0] is the gamepad device for Player 1.
global.gamepad_player_map = [0, 1, 2, 3]; 

// Default deadzone values for gamepad analog sticks
global.input_gamepad_deadzone_light = 0.25;
global.input_gamepad_deadzone_strong = 0.5; // For specific checks like ANY_UP/ANY_DOWN_HELD axis part


/// @function scr_init_input_mappings()
/// @description Initializes the default keyboard and gamepad mappings for all actions.
/// Call this once at the beginning of the game.
function scr_init_input_mappings() {
    show_debug_message("Initializing Input Mappings...");
    var m = global.input_mappings; // Shortcut

    // --- Player Movement & Actions ---
    m[INPUT_ACTION.MOVE_HORIZONTAL_AXIS] = {
        is_axis: true,
        kb_positive_keys: [ord("D")],
        kb_negative_keys: [ord("A")],
        gp_axis: gp_axislh,
        gp_positive_buttons: [gp_padr], // D-pad right
        gp_negative_buttons: [gp_padl], // D-pad left
        deadzone: global.input_gamepad_deadzone_light
    };
    m[INPUT_ACTION.MOVE_VERTICAL_AXIS] = {
        is_axis: true,
        kb_positive_keys: [ord("S")], // Down for positive Y
        kb_negative_keys: [ord("W")], // Up for negative Y
        gp_axis: gp_axislv,
        gp_positive_buttons: [gp_padd], // D-pad down
        gp_negative_buttons: [gp_padu], // D-pad up
        deadzone: global.input_gamepad_deadzone_light
    };
    m[INPUT_ACTION.JUMP_FLAP] = {
        is_axis: false,
        kb_keys: [vk_space],
        gp_buttons: [gp_face1] // South button (A on Xbox, X on PS)
    };
    m[INPUT_ACTION.DASH_LEFT] = {
        is_axis: false,
        kb_keys: [ord("Q")],
        gp_buttons: [gp_shoulderl]
    };
    m[INPUT_ACTION.DASH_RIGHT] = {
        is_axis: false,
        kb_keys: [ord("E")],
        gp_buttons: [gp_shoulderr]
    };
    m[INPUT_ACTION.DIVE] = {
        is_axis: false,
        kb_keys: [ord("B")],
        gp_buttons: [gp_face2] // East button (B on Xbox, Circle on PS)
    };
    m[INPUT_ACTION.INTERACT] = {
        is_axis: false,
        kb_keys: [vk_enter],
        gp_buttons: [gp_face4] // North button (Y on Xbox, Triangle on PS)
    };
    m[INPUT_ACTION.FIRE_MISSILE] = {
        is_axis: false,
        kb_keys: [ord("X")],
        gp_buttons: [gp_face3] // West button (X on Xbox, Square on PS)
    };
    m[INPUT_ACTION.PAUSE] = {
        is_axis: false,
        kb_keys: [vk_escape],
        gp_buttons: [gp_start]
    };
    m[INPUT_ACTION.ANY_UP_HELD] = {
        is_axis: false, // Conceptually not an axis, but checks one
        kb_keys: [vk_up, ord("W")],
        gp_buttons: [gp_padu],
        gp_axis_check: { axis: gp_axislv, direction: -1, threshold: global.input_gamepad_deadzone_strong } // For axis value < -threshold
    };
    m[INPUT_ACTION.ANY_DOWN_HELD] = {
        is_axis: false,
        kb_keys: [vk_down, ord("S")],
        gp_buttons: [gp_padd],
        gp_axis_check: { axis: gp_axislv, direction: 1, threshold: global.input_gamepad_deadzone_strong } // For axis value > threshold
    };

    // --- Battle Menu Navigation ---
    m[INPUT_ACTION.MENU_CONFIRM] = {
        is_axis: false,
        kb_keys: [vk_space, vk_enter],
        gp_buttons: [gp_face1] // South button
    };
    m[INPUT_ACTION.MENU_CANCEL] = {
        is_axis: false,
        kb_keys: [vk_escape],
        gp_buttons: [gp_face2] // East button
    };
    m[INPUT_ACTION.MENU_SKILL] = {
        is_axis: false,
        kb_keys: [ord("X")],
        gp_buttons: [gp_face3] // West button
    };
    m[INPUT_ACTION.MENU_ITEM] = {
        is_axis: false,
        kb_keys: [ord("Y")],
        gp_buttons: [gp_face4] // North button
    };
    m[INPUT_ACTION.MENU_UP] = {
        is_axis: false,
        kb_keys: [vk_up],
        gp_buttons: [gp_padu]
    };
    m[INPUT_ACTION.MENU_DOWN] = {
        is_axis: false,
        kb_keys: [vk_down],
        gp_buttons: [gp_padd]
    };
    show_debug_message("Input Mappings Initialized successfully.");
}


// --- Input Checking Functions ---

/// @function input_check_pressed(action_enum, [player_index=0])
/// @description Checks if the specified action was just pressed.
/// @param {INPUT_ACTION} action The action to check.
/// @param {Real} [player_index=0] The logical player index (0-3).
/// @returns {Bool}
function input_check_pressed(action, player_index = 0) {
    var map = global.input_mappings[action];
    if (is_undefined(map)) return false;

    // Keyboard
    if (variable_struct_exists(map, "kb_keys")) {
        for (var i = 0; i < array_length(map.kb_keys); ++i) {
            if (keyboard_check_pressed(map.kb_keys[i])) return true;
        }
    }

    // Gamepad
    var gp_idx = global.gamepad_player_map[player_index];
    if (gp_idx < 0 || gp_idx >= gamepad_get_device_count() || !gamepad_is_connected(gp_idx)) {
        // No valid gamepad for this player, so gamepad part of check is false.
    } else {
        if (variable_struct_exists(map, "gp_buttons")) {
            for (var i = 0; i < array_length(map.gp_buttons); ++i) {
                if (gamepad_button_check_pressed(gp_idx, map.gp_buttons[i])) return true;
            }
        }
        // Pressed state for gp_axis_check (ANY_UP/DOWN) primarily comes from gp_buttons (d-pad)
    }
    return false;
}

/// @function input_check(action_enum, [player_index=0])
/// @description Checks if the specified action is currently held down.
/// @param {INPUT_ACTION} action The action to check.
/// @param {Real} [player_index=0] The logical player index (0-3).
/// @returns {Bool}
function input_check(action, player_index = 0) {
    var map = global.input_mappings[action];
    if (is_undefined(map)) return false;

    // Keyboard
    if (variable_struct_exists(map, "kb_keys")) {
        for (var i = 0; i < array_length(map.kb_keys); ++i) {
            if (keyboard_check(map.kb_keys[i])) return true;
        }
    }
    
    // Gamepad
    var gp_idx = global.gamepad_player_map[player_index];
    if (gp_idx < 0 || gp_idx >= gamepad_get_device_count() || !gamepad_is_connected(gp_idx)) {
        // No valid gamepad. If this action relies on gp_axis_check, it's false.
        if (variable_struct_exists(map, "gp_axis_check")) return false;
    } else { // Gamepad is connected
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
    var map = global.input_mappings[action];
    if (is_undefined(map)) return false;

    // Keyboard
    if (variable_struct_exists(map, "kb_keys")) {
        for (var i = 0; i < array_length(map.kb_keys); ++i) {
            if (keyboard_check_released(map.kb_keys[i])) return true;
        }
    }
    
    // Gamepad
    var gp_idx = global.gamepad_player_map[player_index];
     if (gp_idx < 0 || gp_idx >= gamepad_get_device_count() || !gamepad_is_connected(gp_idx)) {
        // No valid gamepad
    } else {
        if (variable_struct_exists(map, "gp_buttons")) {
            for (var i = 0; i < array_length(map.gp_buttons); ++i) {
                if (gamepad_button_check_released(gp_idx, map.gp_buttons[i])) return true;
            }
        }
        // Released state for gp_axis_check is not typically handled this way directly.
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
    var map = global.input_mappings[action];
    if (is_undefined(map) || !map.is_axis) return 0;

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

    // Return keyboard value immediately if non-zero (keyboard priority)
    if (kb_val != 0) {
        return kb_val;
    }

    // Gamepad (only if keyboard is neutral)
    var gp_idx = global.gamepad_player_map[player_index];
    var gamepad_active = (gp_idx >= 0 && gp_idx < gamepad_get_device_count() && gamepad_is_connected(gp_idx));

    if (gamepad_active) {
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
        
        // Return gamepad digital button value if non-zero (D-pad priority over stick)
        if (gp_val_buttons != 0) {
            return gp_val_buttons;
        }

        // Gamepad Analog Axis (only if D-pad is neutral)
        if (variable_struct_exists(map, "gp_axis")) {
            gp_val_axis = gamepad_axis_value(gp_idx, map.gp_axis);
            if (abs(gp_val_axis) < map.deadzone) {
                gp_val_axis = 0;
            }
            // Return analog value if non-zero
            if (gp_val_axis != 0) {
                 return gp_val_axis; // Returns float value
            }
        }
    }
    
    return 0; // No input detected for this axis
}
/// @function scr_player_gather_inputs()
/// @description Gathers all player inputs and sets instance variables.

// Horizontal Movement Input
var _key_x_keyboard = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var _joy_x_gamepad = gamepad_axis_value(0, gp_axislh);
if (abs(_joy_x_gamepad) < 0.25) _joy_x_gamepad = 0; // Deadzone
self.dir_x = (_key_x_keyboard != 0) ? _key_x_keyboard : sign(_joy_x_gamepad);

// Vertical Movement Input (for aiming transitions or direct flight control if applicable)
var _key_y_keyboard = keyboard_check(ord("S")) - keyboard_check(ord("W")); 
var _joy_y_gamepad_v = gamepad_axis_value(0, gp_axislv);
if (abs(_joy_y_gamepad_v) < 0.25) _joy_y_gamepad_v = 0; // Deadzone
self.dir_y = (_key_y_keyboard != 0) ? _key_y_keyboard : sign(_joy_y_gamepad_v);

// Flap/Action Key (Pressed this step)
self.key_action_initiated_this_step = keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);

// Up/Down Keys (Held state - for Phasing)
self.key_up_held = keyboard_check(vk_up) || keyboard_check(ord("W")) || (gamepad_axis_value(0, gp_axislv) < -0.5) || gamepad_button_check(0, gp_padu);
self.key_down_held = keyboard_check(vk_down) || keyboard_check(ord("S")) || (gamepad_axis_value(0, gp_axislv) > 0.5) || gamepad_button_check(0, gp_padd);

// NPC Interaction Input
self.interact_key_pressed = keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(0, gp_face4);
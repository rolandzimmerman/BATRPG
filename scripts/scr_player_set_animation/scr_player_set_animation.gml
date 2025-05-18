/// @function scr_player_set_animation()
/// @description Sets the player's sprite and animation based on current state and inputs.
/// Assumes self.player_state, self.dir_x, self.face_dir, 
/// self.key_action_initiated_this_step (for anim_flap_key_pressed) etc. are set.

// Update facing direction based on horizontal input (dir_x is set by input script)
if (self.dir_x != 0) {
    self.face_dir = self.dir_x;
}
image_xscale = self.face_dir * abs(self.original_scale); // Use original_scale if you want to preserve it

// Define flap key states for animation (specifically for FLYING animation)
// These could also be passed in or be instance vars set by input script
var _anim_flap_key_pressed = self.key_action_initiated_this_step; 
var _anim_flap_key_held = keyboard_check(vk_space) || gamepad_button_check(0, gp_face1);
var _anim_flap_key_released = keyboard_check_released(vk_space) || gamepad_button_check_released(0, gp_face1);


switch (self.player_state) {
    case PLAYER_STATE.FLYING:
        self.image_speed = 0; // Manual frame control
        if (self.face_dir == 1) { // Or use image_xscale to flip
            self.sprite_index = spr_player_walk_right; // Replace with actual flying_right sprite
        } else {
            self.sprite_index = spr_player_walk_left;  // Replace with actual flying_left sprite
        }

        if (_anim_flap_key_released) { self.image_index = 0; }
        else if (_anim_flap_key_pressed) { self.image_index = 1; }
        else if (_anim_flap_key_held) { self.image_index = 1; }
        else { self.image_index = 0; } // Or falling frame
        break;

    case PLAYER_STATE.WALKING_FLOOR:
        if (self.dir_x != 0) { 
            self.image_speed = self.walk_animation_speed;
        } else {
            self.image_speed = 0;
            self.image_index = 0; 
        }
        if (self.face_dir == 1) {
            self.sprite_index = spr_player_walk_right_ground; 
        } else {
            self.sprite_index = spr_player_walk_left_ground;  
        }
        break;

    case PLAYER_STATE.WALKING_CEILING:
        if (self.dir_x != 0) { 
            self.image_speed = self.walk_animation_speed;
        } else {
            self.image_speed = 0;
            self.image_index = 0;
        }
        if (self.face_dir == 1) {
            self.sprite_index = spr_player_walk_right_ceiling; 
        } else {
            self.sprite_index = spr_player_walk_left_ceiling;  
        }
        break;
}
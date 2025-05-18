var _fire_missile_input = keyboard_check_pressed(ord("X")) || gamepad_button_check_pressed(0, gp_face3);

if (_fire_missile_input) {
    if (script_exists(scr_HaveItem) && scr_HaveItem("echo_gem", 1)) {
        var _m_inst = instance_create_depth(x, y, 0, obj_echo_missile); // Ensure obj_echo_missile exists

        if (instance_exists(_m_inst)) {
            _m_inst.hspeed   = self.missile_speed * self.face_dir;  
            _m_inst.origin_x = x;                                     
            _m_inst.max_dist = self.missile_max_distance;     

            if (self.face_dir > 0) {
                _m_inst.sprite_index = spr_echo_right; // Ensure spr_echo_right exists
            } else {
                _m_inst.sprite_index = spr_echo_left;  // Ensure spr_echo_left exists
            }
            _m_inst.image_speed = 0.4; // Or make this a variable
            _m_inst.image_index = 0;
        }
    } else { 
        // Optional: Play a "no ammo" sound or visual cue
    }
}
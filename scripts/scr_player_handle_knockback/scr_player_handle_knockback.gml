/// @function scr_player_handle_knockback()
/// @description Handles player knockback logic.
/// @returns {Bool} True if knockback is active (and Step should exit), false otherwise.
/// Called from obj_player's Step Event.

if (variable_instance_exists(id, "is_in_knockback") && self.is_in_knockback) {
    if (self.knockback_timer > 0) {
        self.knockback_timer -= 1;

        var _kb_dx = self.knockback_hspeed;
        var _kb_dy = self.knockback_vspeed;
        
        // Horizontal collision (simplified from your Option 2)
        if (self.tilemap != -1 && place_meeting(x + _kb_dx, y, self.tilemap)) {
            while(!place_meeting(x + sign(_kb_dx), y, self.tilemap)) { x += sign(_kb_dx); }
            self.knockback_hspeed = 0;
        } else {
            x += _kb_dx;
        }
        // Vertical collision
        if (self.tilemap != -1 && place_meeting(x, y + _kb_dy, self.tilemap)) {
            while(!place_meeting(x, y + sign(_kb_dy), self.tilemap)) { y += sign(_kb_dy); }
            self.knockback_vspeed = 0;
            self.v_speed = 0; 
        } else {
            y += _kb_dy;
        }

        self.knockback_hspeed *= self.knockback_friction;
        self.knockback_vspeed *= self.knockback_friction;

        if (abs(self.knockback_hspeed) < 0.1 && abs(self.knockback_vspeed) < 0.1) {
            self.knockback_timer = 0;
        }

        if (self.knockback_timer == 0) {
            self.is_in_knockback = false;
            self.knockback_hspeed = 0;
            self.knockback_vspeed = 0;
            show_debug_message("Player " + string(id) + " knockback effect ended.");
        }
        return true; // Knockback is active, caller should exit
    } else {
        self.is_in_knockback = false;
        self.knockback_hspeed = 0;
        self.knockback_vspeed = 0;
    }
}
return false; // Knockback not active
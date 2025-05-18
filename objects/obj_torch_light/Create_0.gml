light_sprite = spr_light_orb;
light_radius_scale = 2.0;     // Your base light scale
light_alpha = 1.0;            // Alpha for the light sprite when drawn

// --- Variables for smoother random flicker ---
flicker_max_offset = 0.3;       // Maximum random deviation from light_radius_scale (e.g. scale becomes 2.0 +/- 0.3)
flicker_current_offset = 0;     // The current smoothed offset from the base scale
flicker_target_offset = 0;      // The random offset we are currently moving towards

flicker_lerp_speed = 0.05;      // How quickly the current offset moves to the target offset (0.01 to 0.2 are good ranges)
                                // Smaller values mean slower, smoother transitions.

flicker_change_interval = 15;   // How many steps before picking a new random target offset (e.g., 15 steps = 1/4 second at 60fps)
_flicker_update_timer = flicker_change_interval; // Initialize timer to pick a new target on the first relevant step

current_light_scale = light_radius_scale; // Initialize current_light_scale
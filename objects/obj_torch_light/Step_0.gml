// --- Smoother Random Flicker Logic ---
_flicker_update_timer--; // Countdown the timer

if (_flicker_update_timer <= 0) {
    // Time to pick a new random target offset
    flicker_target_offset = random_range(-flicker_max_offset, flicker_max_offset);

    // Reset the timer (can also add a bit of randomness to the interval itself)
    _flicker_update_timer = flicker_change_interval + random_range(-5, 5); // Add some variance to timing
    _flicker_update_timer = max(5, _flicker_update_timer); // Ensure interval is not too short
}

// Smoothly interpolate (lerp) the current offset towards the target offset
// lerp(current_value, target_value, interpolation_amount)
flicker_current_offset = lerp(flicker_current_offset, flicker_target_offset, flicker_lerp_speed);

// Apply the current smoothed offset to the base light scale
current_light_scale = light_radius_scale + flicker_current_offset;

// Optional: Ensure the light scale doesn't become unreasonably small or negative
var minimum_allowed_scale = light_radius_scale * 0.5; // e.g., never smaller than half the base radius
if (minimum_allowed_scale <= 0) minimum_allowed_scale = 0.1; // Absolute minimum
current_light_scale = max(minimum_allowed_scale, current_light_scale);
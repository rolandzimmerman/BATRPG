/// obj_wind_region :: Step

// Check for any player overlapping our mask
var p = collision_rectangle(
    bbox_left, bbox_top,
    bbox_right, bbox_bottom,
    obj_player, false, true
);

if (p != noone) {
    // If the player is NOT in a dash right now, push them back
    if (!p.isDashing) {
        // Move the player by push_strength in push_dir
        p.x += push_dir * push_strength;

        // Play the wind sound once per frame
        audio_play_sound(snd_wind, 1, 0);
    }
    // else: player is dashing, so they blast right through
}

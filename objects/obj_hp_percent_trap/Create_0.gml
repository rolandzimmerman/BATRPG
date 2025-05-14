/// obj_hp_percent_trap :: Create Event

damage_percent = 0.10; // 10% of max HP
player_invulnerability_duration_frames = ceil(1.5 * game_get_speed(gamespeed_fps)); // 1.5 seconds in frames
trap_cooldown_frames = ceil(2.0 * game_get_speed(gamespeed_fps)); // 2 seconds before trap can hit again
current_cooldown = 0; // Timer for trap's own cooldown

// Optional: Sound effect for the trap triggering
snd_trap_activate = asset_get_index("snd_trap_trigger"); // Replace with your actual sound asset if you have one
snd_player_hit_by_trap = asset_get_index("snd_player_hurt"); // Sound for player getting hit

show_debug_message("obj_hp_percent_trap created. Damage: " + string(damage_percent*100) + "%, Invuln: " + string(player_invulnerability_duration_frames) + " frames, Cooldown: " + string(trap_cooldown_frames) + " frames.");
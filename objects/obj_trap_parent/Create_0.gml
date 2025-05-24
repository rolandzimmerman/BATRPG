/// obj_trap_parent :: Create Event
/// — Initialize parameters, flags, and ensure no name mismatches

// Cooldown & timing
current_cooldown               = 0;  
trap_cooldown_frames           = game_get_speed(gamespeed_fps) * 3;   // 3s cooldown
invuln_duration_frames         = game_get_speed(gamespeed_fps) * 1.5; // 1.5s invuln

// Damage
damage_percent                 = 0.10; 

// Animation flags
image_index      = 0;
image_speed      = 0;
animation_active = false;
has_animation    = (sprite_get_number(sprite_index) > 1);

// (Optional) Sound slots—assign your sounds in the editor
snd_trap_activate      = noone;
snd_player_hit_by_trap = noone;
// DEBUG: report whether we think we have an animation
show_debug_message(
  "Trap Create → frames=" + string(sprite_get_number(sprite_index))
  + ", has_animation=" + string(has_animation)
);
// DEBUG: how many sub-images?
show_debug_message(
  "Create: sprite_frames=" + string(sprite_get_number(sprite_index))
  + ", has_animation=" + string(has_animation)
);

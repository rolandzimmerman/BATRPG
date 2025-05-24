/// obj_trap_parent :: Step Event
// — Cooldown / collision / animate / effects

// 1) Cooldown
if (current_cooldown > 0) {
    current_cooldown -= 1;
    return;
}

// 2) Overlap check
var ply = instance_place(x, y, obj_player);
if (!instance_exists(ply)) return;

// 3) Ignore invuln
if (variable_instance_exists(ply, "invulnerable_timer") 
 && ply.invulnerable_timer > 0) {
    return;
}

// 4) Fire trap
current_cooldown = trap_cooldown_frames;

// 5) DEBUG: about to start animation?
if (!animation_active && has_animation) {
    animation_active = true;

    var total_frames  = sprite_get_number(sprite_index);
    var sps           = game_get_speed(gamespeed_fps);
    image_speed       = 1;
    alarm[0]          = sps * 2;

    show_debug_message(
      "Step: started anim – total_frames=" + string(total_frames)
      + ", image_speed=" + string(image_speed)
      + ", will reset in " + string(alarm[0]) + " steps"
    );
}

// 6) Damage all party members
var hero_dmg = 0;
var hero_key = (variable_instance_exists(ply, "data")
             && is_struct(ply.data)
             && variable_struct_exists(ply.data, "character_key"))
             ? ply.data.character_key 
             : "hero";

if (variable_global_exists("party_members")
 && is_array(global.party_members)
 && variable_global_exists("party_current_stats")
 && ds_exists(global.party_current_stats, ds_type_map)) {
    for (var i = 0; i < array_length(global.party_members); i++) {
        var key   = global.party_members[i];
        if (!ds_map_exists(global.party_current_stats, key)) continue;
        var stats = global.party_current_stats[? key];
        if (!(is_struct(stats)
           && variable_struct_exists(stats, "hp")
           && variable_struct_exists(stats, "maxhp"))) continue;

        var dmg = floor(stats.maxhp * damage_percent);
        if (dmg < 1 && (stats.maxhp * damage_percent) > 0) dmg = 1;
        var old = stats.hp;
        stats.hp    = max(0, stats.hp - dmg);
        show_debug_message("Trap damaged " + key 
          + ": " + string(dmg) 
          + " (HP " + string(old) 
          + "→" + string(stats.hp) + ")");
        if (key == hero_key) hero_dmg = dmg;
    }
}

// 7) Apply invulnerability & flash
ply.invulnerable_timer   = invuln_duration_frames;
ply.is_flashing_visible  = true;
ply.flash_cycle_timer    = ply.flash_interval;

// 8) Knockback
var kb_force = 15;
var kb_dur   = 25;
var dir      = point_direction(x, y, ply.x, ply.y);
ply.is_in_knockback      = true;
ply.knockback_timer      = kb_dur;
ply.knockback_hspeed     = lengthdir_x(kb_force, dir);
ply.knockback_vspeed     = lengthdir_y(kb_force, dir);

// 9) Player‐hit sound
if (audio_exists(snd_player_hit_by_trap)) {
    audio_play_sound(snd_player_hit_by_trap, 10, false);
}

// 10) Damage popup
if (hero_dmg > 0 && object_exists(obj_popup_damage)) {
    var pop = instance_create_layer(ply.x, ply.bbox_top, "Instances", obj_popup_damage);
    if (instance_exists(pop)) pop.damage_amount = hero_dmg;
}

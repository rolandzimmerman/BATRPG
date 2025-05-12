/// scr_player_dive()
function scr_player_dive() {
    // only if you have a meteor_shard
    if (!scr_HaveItem("meteor_shard", 1)) return;

    isDiving     = true;
    v_speed      = dive_max_speed;  
    sprite_index = spr_dive;  
    image_index  = 0;         
    image_speed  = 0.5;

    audio_play_sound(snd_sfx_dive, 1, 0);
}

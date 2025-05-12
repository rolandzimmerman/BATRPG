/// obj_gate :: User Event 0
if (!opened && !opening) {
    opening      = true;
    sprite_index = spr_gate_opening; // play the “opening” anim
    image_index  = 0;
    image_speed  = 1;              // tweak to taste

    // no longer block the player as soon as it starts
    mask_index   = -1;
    solid        = false;

    audio_play_sound(snd_sfx_gate_open, 1, 0);
}

/// scr_player_dash(dir)
function scr_player_dash(dir) {
    // only if you’ve picked up the flurry flower
    if (!scr_HaveItem("flurry_flower", 1)) return;

    isDashing   = true;
    dash_dir    = dir;
    dash_timer  = dash_duration;

    // pick the correct sprite & start on frame 0
    if (dir < 0) {
        sprite_index = spr_player_dash_left;
    } else {
        sprite_index = spr_player_dash_right;
    }
    image_index = 0;      // start at first frame
    image_speed = 0.5;    // let it animate

    audio_play_sound(snd_sfx_dash, 1, 0);
}
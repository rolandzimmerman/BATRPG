// show the dust‐slam animation and play SFX
sprite_index   = spr_dive_slam;
image_speed    = 1;
image_index    = 0;

// no collision
mask_index     = -1;
solid          = false;

// play the slam sound
audio_play_sound(snd_sfx_dive_slam, 1, 0);

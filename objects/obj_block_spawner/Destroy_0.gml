// obj_block_spawner - Destroy Event

// Stop the continuous earthquake sound if it's playing
if (audio_is_playing(earthquake_sound_instance)) {
    audio_stop_sound(earthquake_sound_instance);
    show_debug_message("Block Spawner Destroyed: Ensured snd_fx_earthquake is stopped.");
}
earthquake_sound_instance = noone;
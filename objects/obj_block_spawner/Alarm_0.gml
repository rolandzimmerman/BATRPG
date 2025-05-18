// obj_block_spawner - Alarm 0 Event

// Check if there are still blocks left to spawn
if (current_spawn_index < total_blocks_to_spawn) {
    // Get position data for the current block
    var current_pos_data = blocks_to_spawn_list[current_spawn_index];
    var spawn_x = current_pos_data.x_pos;
    var spawn_y = current_pos_data.y_pos;

    // Create an instance of the block
    instance_create_layer(spawn_x, spawn_y, spawn_layer_name, block_object_to_spawn);
    show_debug_message("Spawned block " + string(current_spawn_index + 1) + " at " + string(spawn_x) + "," + string(spawn_y));

    // Play the individual crash sound for this block
    // Higher priority number (e.g., 10) means it's less important if channels are limited.
    // We want this to be clearly audible, so a moderate to high priority is good.
    if (audio_exists(individual_spawn_sound)) {
        audio_play_sound(individual_spawn_sound, 10, false); // Priority 10, not looping
    } else {
        show_debug_message("Block Spawner Warning: individual_spawn_sound (snd_fx_crash) not found!");
    }

    // Move to the next block in the sequence
    current_spawn_index++;

    // If there are more blocks to spawn, reset the alarm for the next one
    if (current_spawn_index < total_blocks_to_spawn) {
        alarm[0] = spawn_delay_frames;
    } else {
        // All blocks have been spawned
        show_debug_message("Block Spawner: All blocks spawned successfully!");

        // Stop the continuous earthquake sound
        if (audio_is_playing(earthquake_sound_instance)) {
            audio_stop_sound(earthquake_sound_instance);
            show_debug_message("Block Spawner: Stopped snd_fx_earthquake.");
        }
        earthquake_sound_instance = noone; // Clear the stored sound instance ID

        // Optionally, destroy the spawner object now
        // instance_destroy();
    }
}
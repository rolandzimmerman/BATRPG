// obj_block_spawner - Create Event

show_debug_message("Block Spawner Initialized");

// --- Configuration ---

// 1. Define the positions where each block will spawn using your coordinates
blocks_to_spawn_list = [
    { x_pos: 3756, y_pos: 312 },
    { x_pos: 3756, y_pos: 236 },
    { x_pos: 3660, y_pos: 312 },
    { x_pos: 3660, y_pos: 236 },
    { x_pos: 3564, y_pos: 312 },
    { x_pos: 3584, y_pos: 236 }, // Note: X is 3584 as per your list
    { x_pos: 3536, y_pos: 312 },
    { x_pos: 3536, y_pos: 236 },
    { x_pos: 68, y_pos: 1103 },
    { x_pos: 68, y_pos: 1007 },
    { x_pos: 68, y_pos: 911 },
    { x_pos: 68, y_pos: 815 },
    { x_pos: 68, y_pos: 719 },
    { x_pos: 68, y_pos: 623 },
    { x_pos: 68, y_pos: 527 },
    { x_pos: 68, y_pos: 431 },
    { x_pos: 68, y_pos: 335 },
    { x_pos: 68, y_pos: 239 }
];

// 2. Set the delay (in game frames) between each spawn
spawn_delay_frames = 30; // e.g., 30 frames = 0.5 seconds at 60 FPS (adjust as needed)

// 3. Specify the object to spawn and sound effects
block_object_to_spawn = obj_destructible_block; // Your destructible block object
individual_spawn_sound = snd_fx_crash;       // Sound for each block spawn
continuous_background_sound = snd_fx_earthquake; // Looping earthquake sound

// 4. Specify the layer to spawn instances on
spawn_layer_name = "Instances"; // Ensure this layer exists in your room

// --- Internal Variables ---
current_spawn_index = 0;
total_blocks_to_spawn = array_length(blocks_to_spawn_list);
earthquake_sound_instance = noone; // To store the playing instance of the earthquake sound

// --- Start the Spawning Sequence and Background Sound ---
if (total_blocks_to_spawn > 0) {
    // Start the continuous earthquake sound (looping)
    if (audio_exists(continuous_background_sound)) {
        // Arguments: sound_index, priority, loop, gain (optional), offset (optional), pitch (optional)
        // Lower priority number (e.g., 5) means it's more important than higher numbers if channels are limited.
        // Let's give it a moderate priority and ensure it loops.
        earthquake_sound_instance = audio_play_sound(continuous_background_sound, 5, true);
        show_debug_message("Block Spawner: Started snd_fx_earthquake (Instance ID: " + string(earthquake_sound_instance) + ")");
    } else {
        show_debug_message("Block Spawner Warning: continuous_background_sound (snd_fx_earthquake) not found!");
    }

    // Set the alarm to trigger the first block spawn
    alarm[0] = spawn_delay_frames;
} else {
    show_debug_message("Block Spawner: No spawn positions defined in blocks_to_spawn_list. Spawner will do nothing.");
    // Optionally, destroy the spawner if there's nothing to do
    // instance_destroy();
}
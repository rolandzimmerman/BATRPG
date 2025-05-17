/// obj_cutscene_sequencer - Room Start Event

show_debug_message("Cutscene Sequencer: Entered Room " + room_get_name(room) + ". Current scene index: " + string(current_scene_index) + ", Current state: " + string(current_state));

if (current_state == SEQ_STATE.FINISHED_ALL) {
    show_debug_message("Cutscene Sequencer: In Room Start, but sequence is already FINISHED_ALL. Object will likely destroy itself if this is not the final_destination_room_pending.");
    // The FINISHED_ALL state in Step event should handle final actions or self-destruction.
    exit;
}

if (current_scene_index < array_length(cutscene_scenes)) {
    var _expected_room_for_current_scene = cutscene_scenes[current_scene_index].room_id;

    if (room == _expected_room_for_current_scene) {
        // We've arrived in the correct room for the current or next scene
        show_debug_message("Cutscene Sequencer: Correct room (" + room_get_name(room) + ") for scene " + string(current_scene_index) + ". Setting state to INITIAL_FADE_IN.");
        current_state = SEQ_STATE.INITIAL_FADE_IN;
        fade_alpha = 1.0; // Ensure screen is black to fade in from
    } else {
        // This means we are in a room that is NOT the one expected for the current_scene_index
        // This could happen if the sequencer was placed in the wrong initial room, or an error occurred.
        // Try to resync by going to the correct room for current_scene_index.
        show_debug_message("Cutscene Sequencer WARNING: In Room Start, room " + room_get_name(room) + 
                           " is NOT expected for scene " + string(current_scene_index) + 
                           " (which is " + room_get_name(_expected_room_for_current_scene) + "). Attempting to change room.");
        current_state = SEQ_STATE.CHANGING_ROOM; // This will trigger a room_goto in the Step event.
        fade_alpha = 1.0; // Ensure screen is black for the transition
    }
} else {
    // current_scene_index is out of bounds, meaning all scenes were processed.
    show_debug_message("Cutscene Sequencer: In Room Start, but all scenes processed (index " + string(current_scene_index) + "). Setting to FINISHED_ALL.");
    current_state = SEQ_STATE.FINISHED_ALL;
    // fade_alpha should ideally be 0 if truly finished and not going to another room via final_destination_room_pending.
    // The FINISHED_ALL state should handle final fade if needed.
}
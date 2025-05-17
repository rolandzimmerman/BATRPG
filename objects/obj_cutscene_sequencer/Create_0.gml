/// obj_cutscene_sequencer - Create Event

// --- Singleton Guard (Optional but Recommended) ---
if (instance_number(object_index) > 1 && id != instance_find(object_index, 0)) {
    show_debug_message("Duplicate obj_cutscene_sequencer found and destroyed.");
    instance_destroy();
    exit; // Stop this instance from initializing further
}
// --- End Singleton Guard ---

persistent = true; // Ensure this object survives room changes

// --- State Machine Definition ---
enum SEQ_STATE {
    INITIAL_FADE_IN,    // Fading into the first/current scene's room
    SHOWING_DIALOGUE,   // Dialogue is active
    WAITING_FOR_DIALOGUE_END, // Waiting for obj_dialog to disappear
    WAITING_FOR_CONFIRM,  // Dialogue done, waiting for player to press 'A' (or confirm)
    FADING_OUT,         // Fading current scene to black
    CHANGING_ROOM,      // Preparing to change room
    FINISHED_ALL        // All scenes in the sequence are done
}
current_state = SEQ_STATE.INITIAL_FADE_IN;

// --- Cutscene Data Configuration ---
// Each element in the array is a struct defining a scene.
// 'dialogue' should be an array of structs, where each struct is { name: "Speaker", msg: "Line of dialogue" }
// This is just example data. Populate it with your actual room names and dialogue arrays.
cutscene_scenes = [
    {
        room_id: rm_opening_cutscene_1, // << REPLACE with your actual room asset
        dialogue: [
            { name: "Echo", msg: "They came with torches, brightness, and light," },
            { name: "Echo", msg: "Flame that flickers and scorches, extinguishing the night." }
        ]
    },
    {
        room_id: rm_opening_cutscene_2, // << REPLACE with your actual room asset
        dialogue: [
            { name: "Echo", msg: "Echoes of batkind past tell of a treasure," },
            { name: "Echo", msg: "That a vampire king amassed, without measure." },
            { name: "Echo", msg: "Find and behold the sacred stone of wishing," },
            { name: "Echo", msg: "Else a future foretold with all batkind missing." }
        ]
    },
    {
        room_id: rm_opening_cutscene_3, // << REPLACE with your actual room asset
        dialogue: [
            { name: "Echo", msg: "Face thy fear, little bat, venture ever further, " },
            { name: "Echo", msg: "Our fate depends on thee, and thy hope's eternal fervor" }
        ],
        final_room_after_sequence: rm_cave_tutorial // << Optional: Room to go to after the ENTIRE sequence
    }
];
current_scene_index = 0; // Start with the first scene in the array

// --- Fade Control ---
fade_alpha = 1.0; // Start fully black, ready to fade IN to the first room
fade_speed = 0.02; // Adjust for faster/slower fades (e.g., 1.0 / 0.02 = 50 steps for full fade)

// --- Input Control ---
input_confirm_key_cooldown = 0;
input_confirm_key_cooldown_max = 15; // Small delay after dialogue closes before confirm is accepted

show_debug_message("obj_cutscene_sequencer: Initialized. Starting sequence.");

// MODIFIED Function to trigger dialogue for the current scene
function trigger_current_dialogue() {
    if (current_scene_index < array_length(cutscene_scenes)) {
        var _scene_data = cutscene_scenes[current_scene_index];
        if (array_length(_scene_data.dialogue) > 0) { // If there ARE dialogue messages
            if (script_exists(create_dialog)) {
                show_debug_message("Cutscene: Triggering dialogue for scene " + string(current_scene_index));
                create_dialog(_scene_data.dialogue);
                current_state = SEQ_STATE.WAITING_FOR_DIALOGUE_END; // Correct: Wait for obj_dialog to finish
            } else {
                show_debug_message("Cutscene ERROR: create_dialog script not found! Attempting to skip to fade out.");
                current_state = SEQ_STATE.FADING_OUT; // Error case: no script, try to proceed
            }
        } else { // If there are NO dialogue messages for this scene
            show_debug_message("Cutscene: No dialogue for scene " + string(current_scene_index) + ". Moving to WAIT_FOR_CONFIRM to advance scene.");
            current_state = SEQ_STATE.WAITING_FOR_CONFIRM; // Requires a single confirm press to proceed
            input_confirm_key_cooldown = input_confirm_key_cooldown_max; // Prevent immediate skip if 'A' was just pressed
        }
    } else {
        // Should not happen if logic is correct, but as a fallback
        show_debug_message("Cutscene: trigger_current_dialogue called with invalid scene index: " + string(current_scene_index));
        current_state = SEQ_STATE.FINISHED_ALL;
    }
}
self.trigger_current_dialogue = trigger_current_dialogue; // Make it callable as a method if needed later

// --- Function to set up a new scene (now an instance method for clarity when called from Step) ---
// This function was part of my previous thought process but wasn't in your provided Create.
// Let's define it here properly.
setup_new_scene = function(_scene_idx) {
    if (!instance_exists(self)) return false;

    if (_scene_idx >= array_length(cutscene_scenes)) {
        var _last_actual_scene_idx = array_length(cutscene_scenes) - 1;
        if (_last_actual_scene_idx >= 0 && variable_struct_exists(cutscene_scenes[_last_actual_scene_idx], "final_room_after_sequence")) {
            self.final_destination_room_pending = cutscene_scenes[_last_actual_scene_idx].final_room_after_sequence;
        } else {
            self.final_destination_room_pending = noone;
        }
        current_state = SEQ_STATE.FINISHED_ALL;
        show_debug_message("Cutscene: All scenes complete. Transitioning to FINISHED_ALL.");
        return false;
    }
    
    var current_scene_info = cutscene_scenes[_scene_idx];
    self.final_destination_room_pending = noone; // Clear pending final room until we are truly at the end

    if (room != current_scene_info.room_id) {
        if (room_exists(current_scene_info.room_id)) {
            current_state = SEQ_STATE.CHANGING_ROOM;
            fade_alpha = 1.0; 
            show_debug_message("Cutscene: Scene " + string(_scene_idx) + " requires room change to " + room_get_name(current_scene_info.room_id));
        } else {
            show_debug_message("Cutscene ERROR: Room " + room_get_name(current_scene_info.room_id) + " does not exist for scene " + string(_scene_idx));
            current_state = SEQ_STATE.FINISHED_ALL; 
            return false;
        }
    } else {
        fade_alpha = 1.0; 
        current_state = SEQ_STATE.INITIAL_FADE_IN;
        show_debug_message("Cutscene: Scene " + string(_scene_idx) + " starting in current room " + room_get_name(room) + ". Fading in.");
    }
    return true; 
}
self.setup_new_scene = setup_new_scene; // Make it a method
self.final_destination_room_pending = noone; // Initialize this variable

// Initialize the first scene if this object wasn't destroyed by singleton check
if (instance_exists(self)) {
    // The original logic for initial room check:
    if (array_length(cutscene_scenes) > 0) {
        var _first_scene_room = cutscene_scenes[0].room_id;
        if (room != _first_scene_room) {
            if (room_exists(_first_scene_room)) {
                current_state = SEQ_STATE.CHANGING_ROOM; 
                show_debug_message("Cutscene: Initial room mismatch. Will change to " + room_get_name(_first_scene_room));
            } else {
                show_debug_message("Cutscene ERROR: First scene room " + room_get_name(_first_scene_room) + " does not exist!");
                current_state = SEQ_STATE.FINISHED_ALL;
            }
        } else {
             // Already in the first scene's room, start fading in
             current_state = SEQ_STATE.INITIAL_FADE_IN;
             fade_alpha = 1.0; // Ensure we start black to fade from
        }
    } else {
        show_debug_message("Cutscene ERROR: No scenes defined.");
        current_state = SEQ_STATE.FINISHED_ALL;
    }
}
/// obj_cutscene_sequencer - Step Event

// Assuming SEQ_STATE enum is defined globally or in this object's Create event
// enum SEQ_STATE { INITIAL_FADE_IN, WAITING_FOR_DIALOGUE_END, WAITING_FOR_CONFIRM, FADING_OUT, CHANGING_ROOM, FINISHED_ALL }

if (input_confirm_key_cooldown > 0) {
    input_confirm_key_cooldown--;
}

// Assuming player_index 0 for gamepad inputs by default in input functions
var confirm_input_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);

switch (current_state) {
    case SEQ_STATE.INITIAL_FADE_IN:
        fade_alpha -= fade_speed;
        if (fade_alpha <= 0) {
            fade_alpha = 0;
            show_debug_message("Cutscene: Initial fade IN complete for scene " + string(current_scene_index));
            // self.trigger_current_dialogue(); // Assuming 'self' is not strictly needed if called from within instance
            trigger_current_dialogue(); // Call the method defined in Create
        }
        break;

    // SHOWING_DIALOGUE state is effectively handled by trigger_current_dialogue 
    // immediately setting state to WAITING_FOR_DIALOGUE_END or WAITING_FOR_CONFIRM.

    case SEQ_STATE.WAITING_FOR_DIALOGUE_END:
        // This state is active when obj_dialog is present and running.
        // obj_dialog destroys itself when the player presses confirm on its last message.
        if (!instance_exists(obj_dialog)) { 
            show_debug_message("Cutscene: Dialogue ended for scene " + string(current_scene_index) + ". Proceeding directly to FADE_OUT.");
            current_state = SEQ_STATE.FADING_OUT;
            // No input_confirm_key_cooldown reset here because the confirm was for the dialogue box itself.
        }
        break;

    case SEQ_STATE.WAITING_FOR_CONFIRM: // This state is now ONLY for scenes with NO dialogue messages initially
        if (input_confirm_key_cooldown == 0) {
            // Replaced with:
            if (confirm_input_pressed) {
                show_debug_message("Cutscene: Confirm pressed (for no-dialogue scene " + string(current_scene_index) + "). Fading OUT.");
                current_state = SEQ_STATE.FADING_OUT;
                input_confirm_key_cooldown = 10; // Reset cooldown after confirm (adjust value as needed)
            }
        }
        break;

    case SEQ_STATE.FADING_OUT:
        fade_alpha += fade_speed;
        if (fade_alpha >= 1.0) {
            fade_alpha = 1.0;
            current_scene_index++; 
            show_debug_message("Cutscene: Fade OUT complete. Setting up next scene (index: " + string(current_scene_index) + ")");
            // self.setup_new_scene(current_scene_index); // Assuming 'self' is not strictly needed
            setup_new_scene(current_scene_index); // Call method to set next state (CHANGING_ROOM or FINISHED_ALL)
        }
        break;

    case SEQ_STATE.CHANGING_ROOM:
        // This state is set by setup_new_scene if a room change is needed.
        // fade_alpha should be 1.0.
        if (current_scene_index < array_length(cutscene_scenes)) { // Ensure we have a valid next scene
            var _target_room = cutscene_scenes[current_scene_index].room_id;
            if (room != _target_room) { // Make sure we only call room_goto once per required change
                if (room_exists(_target_room)) {
                    show_debug_message("Cutscene: Executing room_goto to: " + room_get_name(_target_room));
                    room_goto(_target_room);
                    // The Room Start event of this persistent object (if it is persistent) 
                    // will handle setting the state to INITIAL_FADE_IN.
                } else {
                    show_debug_message("Cutscene ERROR: Target room " + room_get_name(_target_room) + " (from CHANGING_ROOM) does not exist for scene index " + string(current_scene_index) + "!");
                    current_state = SEQ_STATE.FINISHED_ALL; // Critical error
                }
            } else {
                // Already in the target room (e.g. if Room Start already handled it or error in logic)
                // Force INITIAL_FADE_IN for safety if this state is reached unexpectedly while in target room.
                current_state = SEQ_STATE.INITIAL_FADE_IN;
                fade_alpha = 1.0; // Ensure screen is black to fade from
                show_debug_message("Cutscene: CHANGING_ROOM detected already in target room. Forcing INITIAL_FADE_IN.");
            }
        } else {
            // This should ideally be caught by setup_new_scene sending to FINISHED_ALL
            show_debug_message("Cutscene: CHANGING_ROOM called but current_scene_index is out of bounds. Finishing.");
            current_state = SEQ_STATE.FINISHED_ALL;
        }
        break;

    case SEQ_STATE.FINISHED_ALL:
        show_debug_message("Cutscene: Sequence processing finished.");
        var _went_to_final_room = false; // Renamed from _goto_final for clarity
        
        // Check if final_destination_room_pending is defined and not noone
        var _final_dest_room = self.final_destination_room_pending ?? noone; // Use instance variable

        if (_final_dest_room != noone && room_exists(_final_dest_room)) {
            if (room != _final_dest_room) {
                // Ensure screen is black for final transition
                if (fade_alpha < 1.0) { 
                    show_debug_message("Cutscene: Screen not fully black for final room transition (alpha: " + string(fade_alpha) + "). Forcing black.");
                    fade_alpha = 1.0; 
                    // Ideally, you'd have a FADE_OUT_FINAL state to handle this fade smoothly
                    // For now, it will draw black for one frame if not already black, then change room.
                }
                show_debug_message("Cutscene: Going to final destination room: " + room_get_name(_final_dest_room));
                room_goto(_final_dest_room);
                _went_to_final_room = true; 
            } else {
                show_debug_message("Cutscene: Already in final destination room (" + room_get_name(_final_dest_room) + ").");
            }
        } else if (_final_dest_room != noone) { // It was defined but doesn't exist
             show_debug_message("Cutscene ERROR: Defined final destination room " + room_get_name(_final_dest_room) + " does not exist!");
        }

        // Destroy the cutscene sequencer instance
        // If room_goto was just called, this instance (if not persistent) will be destroyed anyway.
        // If it IS persistent and needs to be manually destroyed after the cutscene, do it here.
        // If it went to a final room, it's usually safe to destroy. If no final room, destroy.
        show_debug_message("Cutscene: Destroying self (obj_cutscene_sequencer).");
        instance_destroy();
        // No exit here; allow the instance_destroy to take effect at end of step.
        break;
        
    default:
        show_debug_message("WARNING [obj_cutscene_sequencer]: Unknown current_state: " + string(current_state));
        current_state = SEQ_STATE.FINISHED_ALL; // Try to gracefully end
        break;
}
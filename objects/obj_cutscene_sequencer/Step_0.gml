/// obj_cutscene_sequencer - Step Event

if (input_confirm_key_cooldown > 0) {
    input_confirm_key_cooldown--;
}

switch (current_state) {
    case SEQ_STATE.INITIAL_FADE_IN:
        fade_alpha -= fade_speed;
        if (fade_alpha <= 0) {
            fade_alpha = 0;
            show_debug_message("Cutscene: Initial fade IN complete for scene " + string(current_scene_index));
            self.trigger_current_dialogue(); // Call the method defined in Create
        }
        break;

    // SHOWING_DIALOGUE state is effectively handled by trigger_current_dialogue 
    // immediately setting state to WAITING_FOR_DIALOGUE_END or WAITING_FOR_CONFIRM.

    case SEQ_STATE.WAITING_FOR_DIALOGUE_END:
        // This state is active when obj_dialog is present and running.
        // obj_dialog destroys itself when the player presses confirm on its last message.
        if (!instance_exists(obj_dialog)) { 
            show_debug_message("Cutscene: Dialogue ended for scene " + string(current_scene_index) + ". Proceeding directly to FADE_OUT.");
            current_state = SEQ_STATE.FADING_OUT; // <<<< KEY CHANGE HERE <<<<
            // No need for input_confirm_key_cooldown here because the confirm was for the dialogue box itself.
        }
        break;

    case SEQ_STATE.WAITING_FOR_CONFIRM: // This state is now ONLY for scenes with NO dialogue messages initially
        if (input_confirm_key_cooldown == 0) {
            var _confirm_pressed = keyboard_check_pressed(vk_space) || 
                                   keyboard_check_pressed(vk_enter) || 
                                   gamepad_button_check_pressed(0, gp_face1); // Gamepad 'A'

            if (_confirm_pressed) {
                show_debug_message("Cutscene: Confirm pressed (for no-dialogue scene " + string(current_scene_index) + "). Fading OUT.");
                current_state = SEQ_STATE.FADING_OUT;
            }
        }
        break;

    case SEQ_STATE.FADING_OUT:
        fade_alpha += fade_speed;
        if (fade_alpha >= 1.0) {
            fade_alpha = 1.0;
            current_scene_index++; 
            show_debug_message("Cutscene: Fade OUT complete. Setting up next scene (index: " + string(current_scene_index) + ")");
            self.setup_new_scene(current_scene_index); // Call method to set next state (CHANGING_ROOM or FINISHED_ALL)
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
                    // The Room Start event of this persistent object will handle setting the state to INITIAL_FADE_IN.
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
        var _goto_final = false;
        if (self.final_destination_room_pending != noone && room_exists(self.final_destination_room_pending)) {
            if (room != self.final_destination_room_pending) {
                // Ensure screen is black for final transition
                if (fade_alpha < 1.0) { // This check implies we need a fade before this final goto.
                                        // This state might need a pre-state like FADE_OUT_FINAL if not already black.
                                        // For now, assuming fade_alpha is already 1.0 from the last FADING_OUT.
                    show_debug_message("Cutscene: Screen not fully black for final room transition (alpha: " + string(fade_alpha) + "). Forcing black.");
                    fade_alpha = 1.0; 
                    // To make this smooth, you'd need another state: FADE_OUT_TO_FINAL_DESTINATION
                    // For now, this will draw black for one frame, then change room.
                }
                 show_debug_message("Cutscene: Going to final destination room: " + room_get_name(self.final_destination_room_pending));
                room_goto(self.final_destination_room_pending);
                _goto_final = true; 
            } else {
                show_debug_message("Cutscene: Already in final destination room.");
            }
        } else if (self.final_destination_room_pending != noone) {
             show_debug_message("Cutscene ERROR: Defined final destination room " + room_get_name(self.final_destination_room_pending) + " does not exist!");
        }

        if (!_goto_final) { // If we didn't just call room_goto for a final destination
            show_debug_message("Cutscene: Destroying self.");
            instance_destroy();
        } else {
            // If we did call room_goto, destroy self in next step to ensure room change processes
            // Or better, let persistence handle it, it'll be destroyed if the room it goes to doesn't have it.
            // But since this is the end of its lifecycle:
            instance_destroy();
        }
        break;
}
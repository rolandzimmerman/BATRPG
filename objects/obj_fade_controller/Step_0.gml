/// obj_fade_controller - Step Event

switch (current_fade_state) {
    case FADE_STATE.INITIAL_ROOM_DISPLAY:
        if (initial_room_timer > 0) {
            initial_room_timer -= 1;
        } else {
            show_debug_message("Initial display time ended. Starting FADE_OUT.");
            current_fade_state = FADE_STATE.FADING_OUT;
        }
        break;

    case FADE_STATE.FADING_OUT:
        current_fade_alpha += fade_speed;
        if (current_fade_alpha >= 1.0) {
            current_fade_alpha = 1.0;
            show_debug_message("Faded OUT completely. State: CHANGING_ROOM.");
            current_fade_state = FADE_STATE.CHANGING_ROOM;
        }
        break;

    case FADE_STATE.CHANGING_ROOM:
        // This state is very brief. It changes the room and immediately sets up for fade-in.
        if (room_exists(self.target_room_after_fade)) {
            show_debug_message("Changing to room: " + room_get_name(self.target_room_after_fade));
            // The controller is persistent, so it will continue in the new room.
            // Alpha is already 1.0. The FADING_IN state will handle reducing it.
            current_fade_state = FADE_STATE.FADING_IN; // Set state for the new room
            room_goto(self.target_room_after_fade);
        } else {
            show_debug_message("ERROR: Target room for fade transition does not exist!");
            current_fade_state = FADE_STATE.FINISHED; // Or handle error appropriately
        }
        break;

    case FADE_STATE.FADING_IN:
        current_fade_alpha -= fade_speed;
        if (current_fade_alpha <= 0.0) {
            current_fade_alpha = 0.0;
            show_debug_message("Faded IN completely. State: FINISHED.");
            current_fade_state = FADE_STATE.FINISHED;
        }
        break;

    case FADE_STATE.FINISHED:
        // Transition is complete. Decide what to do with this controller.
        // For a one-time sequence like this, you can destroy it.
        show_debug_message("Fade sequence finished. Destroying fade controller.");
        instance_destroy();
        // If you want it to be reusable, you might reset its state here or await new instructions.
        break;
}
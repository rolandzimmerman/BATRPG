/// obj_fade_controller - Create Event

// --- Singleton Pattern (Ensures only one instance of this controller exists) ---
// If you might create this object from multiple places, this prevents duplicates.
// If you only place it once in your initial timed room, this might be optional.
if (instance_number(object_index) > 1 && id != instance_find(object_index, 0)) {
    instance_destroy(); // Destroy this new instance if one already exists
    exit; // Stop running the rest of the Create Event for this duplicate
}
persistent = true; // Make this object persist between rooms

// --- Configuration ---
var initial_display_seconds = 3.0;      // How long to show the first room before fading
self.target_room_after_fade = Titlescreen; // Room to go to after fade out (e.g., rm_destination)
self.fade_speed = 0.02;                 // How much alpha changes per step (e.g., 1.0 / 0.02 = 50 steps to full fade)

// --- State Machine Variables ---
enum FADE_STATE {
    INITIAL_ROOM_DISPLAY,
    FADING_OUT,
    CHANGING_ROOM,
    FADING_IN,
    FINISHED
}
current_fade_state = FADE_STATE.INITIAL_ROOM_DISPLAY;

// --- Timers and Alpha ---
var game_fps = game_get_speed(gamespeed_fps); // Or room_speed for older GM
initial_room_timer = initial_display_seconds * game_fps;
current_fade_alpha = 0; // Start fully transparent

show_debug_message("Fade Controller Initialized. State: INITIAL_ROOM_DISPLAY");
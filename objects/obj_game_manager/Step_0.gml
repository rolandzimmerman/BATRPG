/// obj_game_manager :: Step Event
/// @description Handle global game state, pause triggering, etc.

// The initial pause trigger (input detection, state change, menu creation, instance deactivation)
// is now handled in the Player Step (or another dedicated input object).
// This block below is commented out because that logic has been moved.



// --- Optional: Prevent other manager logic while not in 'playing' state ---
// If the manager does things every step that shouldn't happen while paused, in dialogue, battle, etc.
// This check IS useful to stop other manager logic.
// Keep save/load triggers ABOVE this if you want them to work while paused/in menus
// Remove save/load triggers below if they should only work while playing
if (game_state == "paused" || game_state == "dialogue" || game_state == "battle") {
    // Assuming you have other states where manager logic should stop
    exit; // Stop processing the rest of the manager's Step event
}


// --- Other Manager Logic (Runs only when game_state is NOT paused/dialogue/battle) ---
// Place code here that manages game-wide systems ONLY when the game is actively playing or in non-paused/dialogue/battle states.
// (Keep your F5/F9 save/load triggers here IF you want them ONLY while playing - they are in CREATE above)


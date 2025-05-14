/// obj_player :: Draw Event

// Never draw the over-world sprite in the battle room
if (room == rm_battle) {
    exit;
}

var original_image_alpha = image_alpha; // Store the instance's current image_alpha

if (variable_instance_exists(id, "invulnerable_timer") && invulnerable_timer > 0) {
    if (variable_instance_exists(id, "is_flashing_visible")) { // Check variable exists
        if (is_flashing_visible) {
            image_alpha = 1.0; // Fully visible phase
        } else {
            image_alpha = 0.3; // Dimmed phase (try a more noticeable value like 0.3 or even 0.0)
        }
        // Your existing Draw event debug message is good here:
        // show_debug_message("Player Draw (Invuln): Timer: " + string(invulnerable_timer) + 
        //                   ", IsVisiblePhase: " + string(is_flashing_visible) + 
        //                   ", Setting image_alpha to: " + string(image_alpha));
    } else {
        image_alpha = 1.0; // Fallback if is_flashing_visible somehow doesn't exist
    }
} else {
    image_alpha = 1.0; // Not invulnerable, ensure fully visible
}

draw_self(); // Draws the player sprite using its current image_alpha, image_blend, etc.

image_alpha = original_image_alpha; // IMPORTANT: Restore image_alpha to its original value
                                    // This is crucial if other parts of your game (or default state)
                                    // expect image_alpha to be something specific, or if you
                                    // fade the player in/out using image_alpha elsewhere.
                                    // If image_alpha is *only* used for this flash, you could simply
                                    // set it to 1.0 in the Step event when invulnerable_timer <= 0.
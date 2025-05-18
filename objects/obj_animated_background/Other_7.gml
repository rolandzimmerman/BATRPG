// In the Animation End Event of obj_animated_background
show_debug_message("Animation End: obj_animated_background. image_index was " + string(image_index));
image_speed = 0; // Stop the animation
image_index = image_number - 1; // Explicitly set it to the last frame
show_debug_message("Animation End: image_speed set to 0, image_index set to " + string(image_index));
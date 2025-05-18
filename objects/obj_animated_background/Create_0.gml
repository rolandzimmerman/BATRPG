// In the Create Event of obj_animated_background
show_debug_message("Create: obj_animated_background. Sprite: " + sprite_get_name(sprite_index) + ", Frames: " + string(image_number));
image_speed = 1; // Or your desired positive speed
image_index = 0; // Start from the first frame
show_debug_message("Create: image_speed set to " + string(image_speed) + ", image_index to " + string(image_index));
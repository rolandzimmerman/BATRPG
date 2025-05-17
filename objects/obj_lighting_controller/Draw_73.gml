// obj_lighting_controller - Draw End Event

// 1. Validate and prepare the lighting surface
if (!surface_exists(global.lighting_surface)) {
    // Attempt to recreate if lost (e.g., game minimized, display adapter reset)
    var _view_w = camera_get_view_width(view_camera[0]);
    var _view_h = camera_get_view_height(view_camera[0]);
    global.lighting_surface = surface_create(_view_w, _view_h);
    // If creation fails again, exit to avoid errors
    if (!surface_exists(global.lighting_surface)) {
        exit;
    }
}

// 2. Set the target to our lighting surface
surface_set_target(global.lighting_surface);

// 3. Clear the surface with the ambient darkness color and alpha
// This creates the overall shadow layer.
draw_clear_alpha(c_black, global.ambient_darkness_alpha);

// 4. "Cut out" light from the darkness
// We use a subtractive blend mode. Where we draw (e.g., white), it will subtract from the black, making it transparent.
gpu_set_blendmode(bm_subtract); // Or try: gpu_set_blendmode_ext(bm_zero, bm_inv_src_alpha);

// Loop through all fire instances (or any light-emitting object)
with (obj_fire) {
    if (instance_exists(self)) { // Good practice to check if instance still exists
        // Calculate light position relative to the view/camera if the surface is view-sized
        var _light_x_on_surface = x - camera_get_view_x(view_camera[0]);
        var _light_y_on_surface = y - camera_get_view_y(view_camera[0]);

        // Draw the light sprite. We draw it white with full alpha to "erase" the maximum amount of darkness.
        draw_sprite_ext(light_sprite, 
                        0, // image_index (can be animated if your light sprite is an animation)
                        _light_x_on_surface, 
                        _light_y_on_surface,
                        current_light_scale, // Use the flickering scale
                        current_light_scale, // Use the flickering scale
                        0, // rotation
                        c_white, // Color (use c_white for bm_subtract to remove darkness)
                        light_alpha); // Alpha of the light itself (usually 1.0 for this method)
    }
}
// You would add similar 'with (obj_other_light_source)' blocks here for other lights.

// 5. Reset the blend mode back to normal
gpu_set_blendmode(bm_normal);

// 6. Reset the drawing target back to the application surface (the screen)
surface_reset_target();

// 7. Draw the completed lighting surface onto the screen
// It will be drawn at the view's origin.
draw_surface(global.lighting_surface, camera_get_view_x(view_camera[0]), camera_get_view_y(view_camera[0]));
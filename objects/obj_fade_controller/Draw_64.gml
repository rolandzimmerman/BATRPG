/// obj_fade_controller - Draw GUI Event

if (current_fade_alpha > 0) {
    // Get GUI width and height to ensure full coverage
    var gui_width = display_get_gui_width();
    var gui_height = display_get_gui_height();

    // Store original color and alpha to reset them later
    var original_color = draw_get_color();
    var original_alpha = draw_get_alpha();

    draw_set_color(c_black);
    draw_set_alpha(current_fade_alpha);

    // Draw a rectangle covering the entire GUI layer
    draw_rectangle(0, 0, gui_width, gui_height, false);

    // Reset to original drawing color and alpha
    draw_set_color(original_color);
    draw_set_alpha(original_alpha);
}
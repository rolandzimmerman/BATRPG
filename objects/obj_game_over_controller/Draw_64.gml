/// obj_game_over_controller :: Draw GUI Event
// Draw the black fade overlay on top of everything
if (fade_fading) {
    var w = display_get_gui_width();
    var h = display_get_gui_height();
    draw_set_color(c_black);
    draw_set_alpha(clamp(fade_alpha, 0, 1));
    draw_rectangle(0, 0, w, h, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

/// obj_cutscene_sequencer - Draw GUI Event
if (fade_alpha > 0) { 
    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();
    var _prev_color = draw_get_color();
    var _prev_alpha = draw_get_alpha();
    draw_set_color(c_black);
    draw_set_alpha(fade_alpha);
    draw_rectangle(0, 0, _gui_w, _gui_h, false); 
    draw_set_color(_prev_color);
    draw_set_alpha(_prev_alpha);
}
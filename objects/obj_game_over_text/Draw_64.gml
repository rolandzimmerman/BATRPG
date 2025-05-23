// obj_game_over_text :: Draw GUI Event
// Draw centered, middle-aligned text at (x,y)
draw_set_font(display_font);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_color(display_color);

draw_text(x, y, display_text);

// Reset (in case other GUI draws later)
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);

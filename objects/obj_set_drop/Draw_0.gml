/// obj_loot_drop :: Draw Event
draw_self();

// Optional: Draw current Y if needed for debugging
/*
if (instance_exists(id)) {
    draw_set_color(c_blue);
    draw_text(x + 10, y - 20, "y: " + string(y) + "\nv_spd: " + string(v_speed) + "\nlanded: " + string(landed));
    draw_set_color(c_white);
}
*/
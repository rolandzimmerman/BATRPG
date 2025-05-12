/// obj_gate :: Animation End Event
if (opening && sprite_index == spr_gate_opening) {
    opening        = false;
    opened         = true;
    sprite_index   = spr_gate_open;  // final frame/sprite
    image_speed    = 0;
    image_index    = 0;
}

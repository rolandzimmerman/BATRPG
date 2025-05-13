/// obj_gate :: Animation End Event

if (opening && sprite_index == spr_gate_opening) {
    opening = false;
    opened = true; // This specific gate instance is now visually and mechanically open
    sprite_index = spr_gate_open; 
    image_speed = 0;
    image_index = 0; 
    // 'solid' and 'mask_index' should have been set to non-solid when User Event 0 started the opening.
    var current_gate_group_id = variable_instance_exists(id, "group_id") ? string(group_id) : "NOT SET";
    show_debug_message("Gate (Group ID: " + current_gate_group_id + ", Instance: " + string(id) + ") finished opening animation and is now in 'opened' state.");
}
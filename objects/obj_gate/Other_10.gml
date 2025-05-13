/// obj_gate :: User Event 0

// This event is triggered by a switch with a matching group_id.
// It only proceeds if the gate isn't already open or in the process of opening.
if (!opened && !opening) {
    var current_gate_group_id_ue0 = variable_instance_exists(id, "group_id") ? string(group_id) : "NOT SET";
    show_debug_message("Gate (Group ID: " + current_gate_group_id_ue0 + ", Instance: " + string(id) + ") User Event 0 triggered: Starting to open.");
    
    opening = true;
    sprite_index = spr_gate_opening; 
    image_index = 0;
    image_speed = 1; // Adjust animation speed as needed

    // Become non-solid as soon as opening starts
    mask_index = -1;
    solid = false;

    if (audio_exists(snd_sfx_gate_open)) {
        audio_play_sound(snd_sfx_gate_open, 1, 0);
    } else {
        show_debug_message("WARNING: snd_sfx_gate_open sound asset not found for gate " + string(id));
    }
} else {
    var current_gate_group_id_ue0_skip = variable_instance_exists(id, "group_id") ? string(group_id) : "NOT SET";
    if (opened) {
        show_debug_message("Gate (Group ID: " + current_gate_group_id_ue0_skip + ", Instance: " + string(id) + ") User Event 0 triggered, but gate is already 'opened'. No action.");
    } else if (opening) {
        show_debug_message("Gate (Group ID: " + current_gate_group_id_ue0_skip + ", Instance: " + string(id) + ") User Event 0 triggered, but gate is already 'opening'. No action.");
    }
}
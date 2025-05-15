/// obj_minimap :: Draw GUI Event (or whichever event this code is in)

// ... (your existing code for visibility check, frame setup, border, background image) ...
if (!visible) exit;

// ░░░ DRAW THE BORDER FIRST (box1)
// Assuming spr_box1 should be fully opaque or use the instance's current alpha
draw_sprite_stretched(spr_box1, 0, frame_x, frame_y, frame_width, frame_height);

// ░░░ DRAW BACKGROUND IMAGE
// Assuming spr_minimap should be fully opaque or use the instance's current alpha
draw_sprite_stretched(spr_minimap, 0, frame_x, frame_y, frame_width, frame_height);

// ░░░ DRAW ROOMS
var map_margin = 32;
var content_x = frame_x + map_margin;
var content_y = frame_y + map_margin;

var original_global_alpha = draw_get_alpha(); // Store the current global draw alpha

var key = ds_map_find_first(global.room_coords);
while (!is_undefined(key)) {
    var coord = global.room_coords[? key];
    var map_xpos = content_x + coord.x * scale;
    var map_ypos = content_y + coord.y * scale;

    // --- MODIFICATION FOR ROOM ALPHA ---
    // Set alpha for the general room box. 
    // We multiply by original_global_alpha in case the entire minimap is being faded.
    draw_set_alpha(0.5 * original_global_alpha); 
    draw_set_color(c_white); 
    
    // The last argument 'false' means it draws an outline. 
    // This semi-transparent outline will appear fainter.
    // If you wanted a semi-transparent *filled* box, you'd set the last argument to 'true'.
    draw_rectangle(map_xpos, map_ypos, map_xpos + scale, map_ypos + scale, false);
    // --- END MODIFICATION ---

    // Current room indicator - let's assume this should be more prominent (fully opaque relative to original_global_alpha)
    if (room == key) {
        draw_set_alpha(1.0 * original_global_alpha); // Reset to full (original) alpha for the indicator
        draw_set_color(c_red);
        draw_rectangle(map_xpos + 2, map_ypos + 2, map_xpos + scale - 2, map_ypos + scale - 2, false);
        // No need to set alpha back to 0.5 here, as the next loop iteration will do it for the next room box.
    }

    key = ds_map_find_next(global.room_coords, key);
}

// Restore the original global draw alpha after drawing all rooms
draw_set_alpha(original_global_alpha);
draw_set_color(c_white); // Reset color just in case it was left as c_red

// ... (rest of your Draw GUI event, if any) ...
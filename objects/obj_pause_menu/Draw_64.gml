/// obj_pause_menu :: Draw GUI Event
/// Draws the pause menu using spr_box1 (engine 9-slice via stretch), Font1, and white text.

// Only draw if this menu is active
if (!variable_instance_exists(id, "active") || !active) return;
if (!variable_instance_exists(id, "menu_options")) return;
if (!variable_instance_exists(id, "menu_item_count")) return;
if (!variable_instance_exists(id, "menu_index")) return;

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Set Font and Determine Dynamic Line Height ---
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1); // Fallback to default font
}
var _text_height_example = string_height("Mg"); // Get typical height of text with current font
var line_height = ceil(_text_height_example + 10); // Add 10px padding for spacing. Adjust as needed.
                                                  // For Font 24, this might make line_height around 34-40px.

// --- Menu Box Dimensions & Layout (Adjusted for larger font) ---
var pad = 20;    // Increased padding inside the box, tune as needed (was 15)
var margin = 32; // Increased margin from screen edges, tune as needed (was 16)

// Calculate dynamic box_width based on longest menu option or title
var max_text_line_width = string_width("Paused"); // Start with title width
for (var i = 0; i < menu_item_count; i++) {
    var option_text_for_width_check = "> " + menu_options[i]; // Check width including the selector
    max_text_line_width = max(max_text_line_width, string_width(option_text_for_width_check));
}
var box_content_width = max_text_line_width;
var box_width = box_content_width + pad * 2; // Total box width = content + left/right padding
var min_menu_width = 280; // A minimum sensible width for the pause menu with Font 24
box_width = max(box_width, min_menu_width);

var box_lines = menu_item_count + 1; // +1 for Title
var box_content_height = box_lines * line_height;
var box_height = box_content_height + (pad * 2); // Total box height = content + top/bottom padding

// Position the box (e.g., top-left or centered)
var box_x = margin; // Positioned using margin from left
var box_y = margin; // Positioned using margin from top
// Alternatively, to center the menu:
// var box_x = (gui_w - box_width) / 2;
// var box_y = (gui_h - box_height) / 2;


// --- Set Common Draw Properties ---
draw_set_color(c_white);
draw_set_valign(fa_top); // Default for multi-line text
draw_set_halign(fa_left); // Default
draw_set_alpha(1.0);

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white);

// --- Draw Menu Box ---
// The box_x, box_y, box_width, box_height here refer to the full panel including its own padding.
if (sprite_exists(spr_box1)) {
    var _spr_w = sprite_get_width(spr_box1);
    var _spr_h = sprite_get_height(spr_box1);
    if (_spr_w > 0 && _spr_h > 0) { // Ensure sprite dimensions are valid
        // For 9-slice like stretching, draw_sprite_stretched is fine.
        // If spr_box1 is a true 9-slice sprite, you'd use draw_sprite_pos or draw_sprite_nine_slice.
        // Assuming draw_sprite_stretched is the intended method:
        draw_sprite_stretched(spr_box1, -1, box_x, box_y, box_width, box_height);
    } else { // Fallback if sprite has no dimensions
        draw_set_alpha(0.8); draw_set_color(c_dkgray); // Fallback box color
        draw_rectangle(box_x, box_y, box_x + box_width, box_y + box_height, false);
        draw_set_alpha(1.0); draw_set_color(c_white);
        show_debug_message("Warning: spr_box1 has zero width or height.");
    }
} else { // Fallback if sprite doesn't exist
    draw_set_alpha(0.8); draw_set_color(c_dkgray); // Fallback box color
    draw_rectangle(box_x, box_y, box_x + box_width, box_y + box_height, false);
    draw_set_alpha(1.0); draw_set_color(c_white);
    show_debug_message("Warning: spr_box1 does not exist. Drawing fallback rectangle.");
}

// --- Draw Text ---
// Text is drawn relative to the content area, which starts at (box_x + pad, box_y + pad)
var content_area_x = box_x + pad;
var content_area_y = box_y + pad;
var content_area_width = box_width - (pad * 2); // This is 'box_content_width' calculated earlier

// Title "Paused"
draw_set_halign(fa_center);
draw_set_valign(fa_middle); // Vertically center title in its line_height
draw_text(content_area_x + content_area_width / 2, content_area_y + line_height / 2, "Paused");

// Options
draw_set_halign(fa_left); // For menu options
draw_set_valign(fa_top);  // Align text from its top for consistent line spacing

var options_start_y = content_area_y + line_height; // Start drawing options below the title line

for (var i = 0; i < menu_item_count; i++) {
    var option_text = menu_options[i];
    var current_row_y = options_start_y + i * line_height;
    var text_draw_color = c_white;

    if (i == menu_index) {
        option_text = "> " + option_text;
        text_draw_color = c_yellow; // Highlight selected text color

        // Optional: Draw a selection highlight rectangle behind text
        // draw_set_alpha(0.3); draw_set_color(c_yellow);
        // draw_rectangle(content_area_x - pad/2, current_row_y - 2,
        //                content_area_x + content_area_width + pad/2, current_row_y + line_height - 2,
        //                false);
        // draw_set_alpha(1.0);
    }
    draw_set_color(text_draw_color);
    draw_text(content_area_x, current_row_y, option_text);
}

// --- Reset Drawing Settings ---
draw_set_font(-1); // Reset to default font
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
/// obj_levelup_popup :: Draw GUI Event
/// — Draw the box, title, and old→new for each stat, green if it went up

// Ensure essential instance variables are available
if (!variable_instance_exists(id, "info") || !is_struct(info) ||
    !variable_instance_exists(id, "keys") || !is_array(keys)) {
    if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);
    draw_text(10, 10, "Level Up Popup Error: Info/Keys missing.");
    if (font_exists(Font1)) draw_set_font(-1); // Reset font
    exit;
}

// --- Font and Dynamic Layout Setup ---
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1);
}

var _text_height_example = string_height("Hg");
var lineH = ceil(_text_height_example + 10);
var padding = 20;          // Overall padding inside the box edges for top/bottom/left/right of content block
var column_gap_padding = ceil(_text_height_example * 0.75); // Gap between Label | OldVal | > | NewVal columns (e.g. 15-20px)
                                                       // This replaces the multiple small_paddings for inter-column spacing

// --- Calculate Required Content Dimensions ---
var title_text = (variable_struct_exists(info, "name") ? string(info.name) : "Character") + " leveled up!";
var title_width = string_width(title_text);

var max_stat_label_w = 0;
var max_old_val_w = 0;
var max_new_val_w = 0;
var num_stat_lines = array_length(keys);

// Define a minimum width for stat number columns to accommodate "high stats"
// This width should be enough for about 4-5 digits + some breathing room.
// "9 more spaces" - if a space is ~4px, this is ~36px. If a digit is ~12px, this is ~3 digits.
// Let's use string_width for "99999" to be generous for 5-digit numbers.
var min_stat_number_col_width = string_width("99999");

for (var i = 0; i < num_stat_lines; i++) {
    var key = keys[i];
    var stat_label_text = string_upper(key) + ":";
    max_stat_label_w = max(max_stat_label_w, string_width(stat_label_text));

    var oldV_str = "N/A";
    if (variable_struct_exists(info, "old") && is_struct(info.old) && variable_struct_exists(info.old, key)) {
        oldV_str = string(info.old[$ key]);
    }
    max_old_val_w = max(max_old_val_w, string_width(oldV_str));

    var newV_str = "N/A";
    if (variable_struct_exists(info, "new") && is_struct(info.new) && variable_struct_exists(info.new, key)) {
        newV_str = string(info.new[$ key]);
    }
    max_new_val_w = max(max_new_val_w, string_width(newV_str));
}

// Ensure value columns are at least wide enough for min_stat_number_col_width
max_old_val_w = max(max_old_val_w, min_stat_number_col_width);
max_new_val_w = max(max_new_val_w, min_stat_number_col_width);

var separator_text = ">"; // Simplified separator, easier to center
var separator_width = string_width(separator_text);

// Content width for one stat line: Label + gap + OldVal + gap + Sep + gap + NewVal
var stat_line_content_w = max_stat_label_w + column_gap_padding + 
                           max_old_val_w + column_gap_padding + 
                           separator_width + column_gap_padding + 
                           max_new_val_w;

var dynamic_content_width = max(title_width, stat_line_content_w);
var final_box_w = dynamic_content_width + padding * 2; // Add outer left/right padding for the panel

var content_height = lineH + padding + (num_stat_lines * lineH); // Title line + gap + all stat lines
var final_box_h = content_height + padding * 2; // Add outer top/bottom padding

// Use instance variables boxX, boxY for the top-left position of the panel if they are meant to be fixed.
// If you want the dynamically sized box to also be centered, calculate panel_x, panel_y here:
// var panel_x = (display_get_gui_width() - final_box_w) / 2;
// var panel_y = (display_get_gui_height() - final_box_h) / 2;
// For now, using self.boxX and self.boxY as per original structure.
var panel_x = self.boxX;
var panel_y = self.boxY;

// --- Background using 9-Slice ---
draw_set_alpha(0.9);
if (sprite_exists(spr_box1)) {
    // Ensure spr_box1 is configured for 9-slice in the Sprite Editor
    var _spr_w = sprite_get_width(spr_box1); // Get original sprite width/height
    var _spr_h = sprite_get_height(spr_box1);
    if (_spr_w > 0 && _spr_h > 0) {
         // Use draw_sprite_ext if 9-slice is enabled in sprite properties
        draw_sprite_ext(spr_box1, 0, panel_x, panel_y, 
                        final_box_w / _spr_w, final_box_h / _spr_h, 
                        0, c_white, 1.0);
    } else { /* Fallback rect */ draw_set_color(make_color_rgb(30,30,30)); draw_rectangle(panel_x, panel_y, panel_x + final_box_w, panel_y + final_box_h, false); }
} else { /* Fallback rect */ draw_set_color(make_color_rgb(30,30,30)); draw_rectangle(panel_x, panel_y, panel_x + final_box_w, panel_y + final_box_h, false); }
draw_set_alpha(1.0);

// --- Draw Content (Title and Stats) ---
var content_start_x = panel_x + padding;
var content_start_y = panel_y + padding;

// Title
draw_set_color(c_white);
draw_set_halign(fa_left); // Draw title left-aligned within the content area
draw_set_valign(fa_top);
draw_text(content_start_x, content_start_y, title_text);

// Stats Display Area
var stats_area_y = content_start_y + lineH + padding;

// Define column start X positions based on calculated max widths
var col_label_start_x = content_start_x;
var col_old_val_start_x = col_label_start_x + max_stat_label_w + column_gap_padding;
var col_separator_start_x = col_old_val_start_x + max_old_val_w + column_gap_padding;
var col_new_val_start_x = col_separator_start_x + separator_width + column_gap_padding;

for (var i = 0; i < num_stat_lines; i++) {
    var key = keys[i];
    var current_stat_draw_y = stats_area_y + i * lineH;

    var oldV_str = "N/A"; var oldV_val = 0;
    if (variable_struct_exists(info, "old") && is_struct(info.old) && variable_struct_exists(info.old, key)) {
        oldV_val = info.old[$ key]; oldV_str = string(oldV_val);
    }
    var newV_str = "N/A"; var newV_val = 0;
    if (variable_struct_exists(info, "new") && is_struct(info.new) && variable_struct_exists(info.new, key)) {
        newV_val = info.new[$ key]; newV_str = string(newV_val);
    }

    // Draw Stat Label
    var stat_label_text = string_upper(key) + ":";
    draw_set_halign(fa_left);
    draw_set_color(c_silver);
    draw_text(col_label_start_x, current_stat_draw_y, stat_label_text);

    // Draw Old Value (right-aligned within its allocated space: max_old_val_w)
    draw_set_halign(fa_right);
    draw_set_color(c_gray);
    draw_text(col_old_val_start_x + max_old_val_w, current_stat_draw_y, oldV_str);

    // Draw Separator (centered within its allocated space: separator_width)
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text(col_separator_start_x + separator_width / 2, current_stat_draw_y, separator_text);

    // Draw New Value (right-aligned within its allocated space: max_new_val_w)
    var new_val_color = c_white;
    if (is_real(newV_val) && is_real(oldV_val)) {
        if (newV_val > oldV_val) new_val_color = c_lime;
        else if (newV_val < oldV_val) new_val_color = c_red;
    }
    draw_set_halign(fa_right);
    draw_set_color(new_val_color);
    draw_text(col_new_val_start_x + max_new_val_w, current_stat_draw_y, newV_str);
}

// --- Reset Drawing Settings ---
draw_set_font(-1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
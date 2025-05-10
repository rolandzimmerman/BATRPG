/// obj_settings_menu :: Draw GUI Event

if (!variable_instance_exists(id, "active") || !active) return;

// Ensure other necessary variables exist (initialized in Create Event)
if (!variable_instance_exists(id, "settings_items") || !variable_instance_exists(id, "settings_index") ||
    !variable_instance_exists(id, "dropdown_display_options") || !variable_instance_exists(id, "dropdown_display_index") ||
    !variable_instance_exists(id, "dropdown_display_open") || !variable_instance_exists(id, "dropdown_resolution_open") ||
    !variable_global_exists("resolution_options") || !variable_global_exists("resolution_index") ) {
    if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);
    draw_text(10, 10, "Settings Menu Error: Essential variables missing for drawing.");
    if (font_exists(Font1)) draw_set_font(-1); // Reset font if set
    return;
}

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Font and Dynamic Layout Setup ---
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1);
}
var _text_height = string_height("Hg");
var line_height = ceil(_text_height + 10);
var dropdown_item_h = line_height;
var slider_bar_h = ceil(_text_height * 0.6);
if (slider_bar_h < 12) slider_bar_h = 12;
var general_padding = 20; // Padding around content and between major sections
var small_padding = 8;   // Internal padding for text within dropdown boxes, etc.

// --- Calculate Dynamic Overall Menu Width ---
var max_label_w = 0;
for (var i = 0; i < array_length(settings_items); i++) {
    var label_text_for_width = settings_items[i];
    if (label_text_for_width != "Back") { // "Back" won't have a colon
        label_text_for_width += ":";
    }
    max_label_w = max(max_label_w, string_width(label_text_for_width));
}

var max_value_content_w = 0;
// Check Display Mode options
for (var i = 0; i < array_length(dropdown_display_options); i++) {
    max_value_content_w = max(max_value_content_w, string_width(dropdown_display_options[i]));
}
// Check Resolution options
for (var i = 0; i < array_length(global.resolution_options); i++) {
    var res_opt_text = string(global.resolution_options[i][0]) + " x " + string(global.resolution_options[i][1]);
    max_value_content_w = max(max_value_content_w, string_width(res_opt_text));
}
// Check Sliders (assume a fixed preferred width for sliders for this calculation)
var typical_slider_width = 200; // This is the width of the slider bar itself
max_value_content_w = max(max_value_content_w, typical_slider_width);

max_value_content_w += small_padding * 2; // Add internal padding for value boxes

// Total content width needed for "Label: Value" structure
var total_content_width = max_label_w + general_padding + max_value_content_w;
var min_overall_box_w = 400; // A sensible minimum width for the entire panel

var box_outer_w = max(total_content_width + general_padding * 2, min_overall_box_w); // Panel padding included
var box_outer_x = (gui_w - box_outer_w) / 2; // Center the box
var box_outer_y = 80; // Keep original Y, or make dynamic based on height
var box_outer_h = 600; // Keep original H; may need to be increased if content overflows vertically

// Colors
var col_bg_interactive = make_color_rgb(40, 40, 40);
var col_highlight_interactive = make_color_rgb(100,100,100);
var col_text = c_white;
var col_selection_bar = c_yellow;

// Draw main background box
if (sprite_exists(spr_box1)) {
    var sw = sprite_get_width(spr_box1); var sh = sprite_get_height(spr_box1);
    if (sw > 0 && sh > 0) draw_sprite_ext(spr_box1, -1, box_outer_x, box_outer_y, box_outer_w / sw, box_outer_h / sh, 0, c_white, 1);
    else { draw_set_color(col_bg_interactive); draw_set_alpha(0.9); draw_rectangle(box_outer_x, box_outer_y, box_outer_x + box_outer_w, box_outer_y + box_outer_h, false); draw_set_alpha(1.0); }
} else { draw_set_color(col_bg_interactive); draw_set_alpha(0.9); draw_rectangle(box_outer_x, box_outer_y, box_outer_x + box_outer_w, box_outer_y + box_outer_h, false); draw_set_alpha(1.0); }

// Content Area Definition & Drawing Setup
var content_x = box_outer_x + general_padding;
var current_y = box_outer_y + general_padding;
// var content_width_available = box_outer_w - (general_padding * 2); // Not strictly needed if box_outer_w is now dynamic enough

draw_set_color(col_text);
draw_set_valign(fa_top);

// Title
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(box_outer_x + box_outer_w / 2, current_y + line_height / 2, "Settings Menu");
current_y += line_height + general_padding;

// --- Store Y positions for highlight ---
var item_y_positions = array_create(array_length(settings_items));

// --- Draw Settings Items Sequentially ---
var label_column_x = content_x;
var value_column_x = content_x + max_label_w + general_padding; // Values start after widest label + a gap

for (var i = 0; i < array_length(settings_items); i++) {
    var item_name = settings_items[i];
    item_y_positions[i] = current_y;

    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(col_text);
    
    var label_display_text = item_name;
    if (item_name != "Back") { // <<<< REMOVE COLON FOR "Back" >>>>
        label_display_text += ":";
    }
    draw_text(label_column_x, current_y, label_display_text);

    // Calculate available width for this specific value element
    var available_width_for_this_value = (box_outer_x + box_outer_w - general_padding) - value_column_x;

    switch (item_name) {
        case "Display Mode":
            var current_display_text = dropdown_display_options[dropdown_display_index];
            var dynamic_value_box_w = string_width(current_display_text) + small_padding * 2;
            if (dropdown_display_open) {
                for (var k = 0; k < array_length(dropdown_display_options); k++) {
                    dynamic_value_box_w = max(dynamic_value_box_w, string_width(dropdown_display_options[k]) + small_padding * 2);
                }
            }
            dynamic_value_box_w = min(dynamic_value_box_w, available_width_for_this_value);
            dynamic_value_box_w = max(dynamic_value_box_w, 150);

            draw_set_color(col_highlight_interactive);
            draw_rectangle(value_column_x, current_y, value_column_x + dynamic_value_box_w, current_y + dropdown_item_h, true);
            draw_set_color(col_text);
            draw_set_valign(fa_middle);
            draw_text(value_column_x + small_padding, current_y + dropdown_item_h / 2, current_display_text);
            draw_set_valign(fa_top);

            var next_y_increment = dropdown_item_h;
            if (dropdown_display_open) {
                var dd_item_start_y = current_y + dropdown_item_h + small_padding;
                for (var j = 0; j < array_length(dropdown_display_options); j++) {
                    var dd_item_abs_y = dd_item_start_y + j * (dropdown_item_h + small_padding);
                    draw_set_color(col_highlight_interactive);
                    draw_rectangle(value_column_x, dd_item_abs_y, value_column_x + dynamic_value_box_w, dd_item_abs_y + dropdown_item_h, true);
                    draw_set_color((j == dropdown_hover_index && settings_index == i) ? c_yellow : col_text);
                    draw_set_valign(fa_middle);
                    draw_text(value_column_x + small_padding, dd_item_abs_y + dropdown_item_h / 2, dropdown_display_options[j]);
                    draw_set_valign(fa_top);
                    next_y_increment += dropdown_item_h + small_padding;
                }
            }
            current_y += next_y_increment;
            break;

        case "Resolution":
            var res = global.resolution_options[global.resolution_index];
            var current_res_text = string(res[0]) + " x " + string(res[1]);
            var dynamic_res_box_w = string_width(current_res_text) + small_padding * 2;
            if (dropdown_resolution_open) {
                for (var k = 0; k < array_length(global.resolution_options); k++) {
                    var r_opt_text = string(global.resolution_options[k][0]) + " x " + string(global.resolution_options[k][1]);
                    dynamic_res_box_w = max(dynamic_res_box_w, string_width(r_opt_text) + small_padding * 2);
                }
            }
            dynamic_res_box_w = min(dynamic_res_box_w, available_width_for_this_value);
            dynamic_res_box_w = max(dynamic_res_box_w, 220); // Min width for resolutions

            draw_set_color(col_highlight_interactive);
            draw_rectangle(value_column_x, current_y, value_column_x + dynamic_res_box_w, current_y + dropdown_item_h, true);
            draw_set_color(col_text);
            draw_set_valign(fa_middle);
            draw_text(value_column_x + small_padding, current_y + dropdown_item_h / 2, current_res_text);
            draw_set_valign(fa_top);

            var next_y_increment_res = dropdown_item_h;
            if (dropdown_resolution_open) {
                var dd_res_item_start_y = current_y + dropdown_item_h + small_padding;
                for (var j = 0; j < array_length(global.resolution_options); j++) {
                    var r_opt = global.resolution_options[j];
                    var dd_item_abs_y = dd_res_item_start_y + j * (dropdown_item_h + small_padding);
                    draw_set_color(col_highlight_interactive);
                    draw_rectangle(value_column_x, dd_item_abs_y, value_column_x + dynamic_res_box_w, dd_item_abs_y + dropdown_item_h, true);
                    draw_set_color((j == dropdown_hover_index && settings_index == i) ? c_yellow : col_text);
                    draw_set_valign(fa_middle);
                    draw_text(value_column_x + small_padding, dd_item_abs_y + dropdown_item_h / 2, string(r_opt[0]) + " x " + string(r_opt[1]));
                    draw_set_valign(fa_top);
                    next_y_increment_res += dropdown_item_h + small_padding;
                }
            }
            current_y += next_y_increment_res;
            break;

        case "SFX Volume":
            var slider_actual_width = min(typical_slider_width, available_width_for_this_value);
            draw_set_color(col_bg_interactive);
            draw_rectangle(value_column_x, current_y, value_column_x + slider_actual_width, current_y + slider_bar_h, false);
            draw_set_color(col_highlight_interactive);
            draw_rectangle(value_column_x, current_y, value_column_x + global.sfx_volume * slider_actual_width, current_y + slider_bar_h, false);
            current_y += slider_bar_h;
            break;

        case "Music Volume":
            var slider_actual_width = min(typical_slider_width, available_width_for_this_value);
            draw_set_color(col_bg_interactive);
            draw_rectangle(value_column_x, current_y, value_column_x + slider_actual_width, current_y + slider_bar_h, false);
            draw_set_color(col_highlight_interactive);
            draw_rectangle(value_column_x, current_y, value_column_x + global.music_volume * slider_actual_width, current_y + slider_bar_h, false);
            current_y += slider_bar_h;
            break;

        case "Back":
            // Label already drawn, just advance Y for spacing
            current_y += line_height;
            break;
    }
    current_y += general_padding; // Spacing before the next main setting item
}

// --- Draw Highlight Rectangle for the main selected setting ---
if (settings_index >= 0 && settings_index < array_length(item_y_positions)) {
    var sel_y_top = item_y_positions[settings_index]; // This is the Y where the label text starts
    var selected_item_name = settings_items[settings_index];
    var selected_item_block_h = line_height; // Default highlight height is one line

    // Adjust highlight height based on the content of the selected item if it's a dropdown/slider
    if (selected_item_name == "Display Mode") {
        selected_item_block_h = dropdown_item_h + (dropdown_display_open ? (array_length(dropdown_display_options) * (dropdown_item_h + small_padding)) + small_padding : 0);
    } else if (selected_item_name == "Resolution") {
        selected_item_block_h = dropdown_item_h + (dropdown_resolution_open ? (array_length(global.resolution_options) * (dropdown_item_h + small_padding)) + small_padding : 0);
    } else if (selected_item_name == "SFX Volume" || selected_item_name == "Music Volume") {
        selected_item_block_h = slider_bar_h;
    }

    draw_set_color(col_selection_bar);
    draw_set_alpha(0.5);
    // Highlight the entire row: from start of label column to end of value column
    draw_rectangle(content_x - small_padding, sel_y_top - small_padding,
                   content_x + (value_column_x - content_x) + max_value_content_w + small_padding, // Covers label, gap, and max value width
                   sel_y_top + selected_item_block_h + small_padding,
                   false);
    draw_set_alpha(1.0);
}

// Reset draw state
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
draw_set_font(-1);
/// obj_settings_menu :: Draw GUI Event

// --- Initial Check for 'active' state ---
if (variable_instance_exists(id, "active")) {
    show_debug_message("obj_settings_menu active status: " + string(active));
} else {
    show_debug_message("obj_settings_menu: 'active' variable DOES NOT EXIST. Nothing will be drawn.");
    return; // Exit if 'active' doesn't even exist
}

// Only draw if this menu is active
if (!active) {
    show_debug_message("obj_settings_menu is NOT active. Returning.");
    return;
}

// Check other essential variables
if (!variable_instance_exists(id, "menu_options")) { show_debug_message("Settings: menu_options missing"); return; }
if (!variable_instance_exists(id, "menu_item_count")) { show_debug_message("Settings: menu_item_count missing"); return; }
if (!variable_instance_exists(id, "menu_index")) { show_debug_message("Settings: menu_index missing"); return; }

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Font and Dynamic Layout Setup ---
if (font_exists(Font1)) {
    draw_set_font(Font1);
    show_debug_message("Font1 set for settings menu.");
} else {
    draw_set_font(-1); // Fallback to default font
    show_debug_message("Font1 NOT FOUND for settings menu, using default font.");
}
var _text_height_example = string_height("Mg");
show_debug_message("Settings menu _text_height_example: " + string(_text_height_example));
var line_height = ceil(_text_height_example + 10);
show_debug_message("Settings menu calculated line_height: " + string(line_height));
if (line_height <= 10 && _text_height_example <=0) { // Safety check if font metrics are weird
    show_debug_message("WARNING: line_height is very small or zero. Font issue?");
    line_height = 36; // Fallback line height
}

var dropdown_item_height = line_height;
var slider_bar_height = ceil(_text_height_example * 0.6);
if (slider_bar_height < 12) slider_bar_height = 12;

// Menu Box Dimensions & Layout
var padding = 20;
var margin = 32;

var max_text_line_width = string_width("Paused"); // Start with a common word
if (variable_instance_exists(id, "menu_options") && array_length(menu_options) > 0) {
    for (var i = 0; i < menu_item_count; i++) {
        var option_text_for_width_check = "> " + menu_options[i];
        max_text_line_width = max(max_text_line_width, string_width(option_text_for_width_check));
    }
}
max_text_line_width = max(max_text_line_width, string_width("Resolution: WWWW x HHHH")); // Check against typical content

var box_content_width = max_text_line_width;
var box_width = box_content_width + padding * 2;
var min_menu_width = 320; // Adjusted minimum for potentially larger text
box_width = max(box_width, min_menu_width);

// Recalculate box_h based on content (this needs full layout definition first)
// For now, using your original fixed box_h, but it might need to be dynamic
var fixed_box_x = 380; // Using original fixed positions as base for this debug pass
var fixed_box_y = 80;
var fixed_box_w = 640; // User's original overall width
var fixed_box_h = 600; // User's original overall height

show_debug_message("Settings Box - X:" + string(fixed_box_x) + " Y:" + string(fixed_box_y) + " W:" + string(fixed_box_w) + " H:" + string(fixed_box_h) + " LineH:" + string(line_height));


// --- Set Common Draw Properties ---
draw_set_color(c_white);
draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_set_alpha(1.0);

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white);

// --- Draw Menu Box ---
// Using fixed_box_x,y,w,h from your original for the main panel
if (sprite_exists(spr_box1)) {
    var sw = sprite_get_width(spr_box1);
    var sh = sprite_get_height(spr_box1);
    if (sw > 0 && sh > 0) {
        draw_sprite_ext(spr_box1, 0, fixed_box_x, fixed_box_y, fixed_box_w / sw, fixed_box_h / sh, 0, c_white, 1);
    } else {
        draw_set_color(make_color_rgb(40,40,40)); draw_set_alpha(0.8);
        draw_rectangle(fixed_box_x, fixed_box_y, fixed_box_x + fixed_box_w, fixed_box_y + fixed_box_h, false);
        draw_set_alpha(1.0);
    }
} else {
    draw_set_color(make_color_rgb(40,40,40)); draw_set_alpha(0.8);
    draw_rectangle(fixed_box_x, fixed_box_y, fixed_box_x + fixed_box_w, fixed_box_y + fixed_box_h, false);
    draw_set_alpha(1.0);
}

// Content positioning based on the fixed box
var content_start_x = fixed_box_x + padding;
var content_start_y = fixed_box_y + padding;
var content_max_width = fixed_box_w - padding * 2;

// Title
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(fixed_box_x + fixed_box_w / 2, content_start_y + line_height / 2, "Settings Menu");
draw_set_halign(fa_left);
draw_set_valign(fa_top);
var current_draw_y = content_start_y + line_height + padding; // Start Y for first actual setting

// --- Compute Highlight Position (using original hardcoded Y values for now for stability) ---
// These Y values are absolute and need to be within fixed_box_y and fixed_box_y + fixed_box_h
var sel_y_text_top; // This will be the Y where the text of the selected item is drawn
var highlight_rect_x1 = fixed_box_x + padding / 2;
var highlight_rect_x2 = fixed_box_x + fixed_box_w - padding / 2;
var highlight_padding_vertical = 4; // Small padding around the text line for highlight

// Store the Y positions of your interactive elements if they are fixed
// These are the Y values where the *labels* are drawn
var display_mode_y_label = current_draw_y;
var resolution_y_label = display_mode_y_label + line_height + (dropdown_display_open ? array_length(dropdown_display_options) * dropdown_item_height : dropdown_item_height) + padding * 2;
var sfx_volume_y_label = resolution_y_label + line_height + (dropdown_resolution_open ? array_length(global.resolution_options) * dropdown_item_height : dropdown_item_height) + padding * 2;
var music_volume_y_label = sfx_volume_y_label + line_height + slider_bar_height + padding * 2;
var back_y_label = music_volume_y_label + line_height + slider_bar_height + padding * 2;


switch (settings_index) {
    case 0: sel_y_text_top = display_mode_y_label; break;
    case 1: sel_y_text_top = resolution_y_label; break;
    case 2: sel_y_text_top = sfx_volume_y_label; break;
    case 3: sel_y_text_top = music_volume_y_label; break;
    case 4: sel_y_text_top = back_y_label; break;
    default: sel_y_text_top = -1; // No valid selection
}

if (sel_y_text_top != -1) {
    draw_set_color(c_yellow); // Was col_selection_bar
    draw_set_alpha(0.5);
    draw_rectangle(highlight_rect_x1, sel_y_text_top - highlight_padding_vertical,
                   highlight_rect_x2, sel_y_text_top + line_height + highlight_padding_vertical, false);
    draw_set_alpha(1.0);
}
draw_set_color(c_white); // Reset color

// Interactive elements X position (labels on left, values/controls on right)
var label_x_pos = content_start_x;
var value_x_pos = fixed_box_x + fixed_box_w * 0.45; // Start values/controls near middle
var value_width = fixed_box_x + fixed_box_w - padding - value_x_pos; // Available width for values


// === Display Mode ===
draw_text(label_x_pos, display_mode_y_label, "Display Mode:");
var dd_display_box_y = display_mode_y_label; // Align dropdown box with label vertically
draw_set_color(make_color_rgb(100,100,100)); // Was col_highlight
draw_rectangle(value_x_pos, dd_display_box_y, value_x_pos + value_width, dd_display_box_y + dropdown_item_height, true);
draw_set_color(c_white);
draw_set_valign(fa_middle);
draw_text(value_x_pos + padding_small, dd_display_box_y + dropdown_item_height / 2, dropdown_display_options[dropdown_display_index]);
draw_set_valign(fa_top);

if (dropdown_display_open) {
    for (var i = 0; i < array_length(dropdown_display_options); i++) {
        var item_y = dd_display_box_y + dropdown_item_height * (i + 1);
        draw_set_color(make_color_rgb(100,100,100));
        draw_rectangle(value_x_pos, item_y, value_x_pos + value_width, item_y + dropdown_item_height, true);
        draw_set_color((i == dropdown_hover_index && settings_index == 0) ? c_yellow : c_white);
        draw_set_valign(fa_middle);
        draw_text(value_x_pos + padding_small, item_y + dropdown_item_height / 2, dropdown_display_options[i]);
        draw_set_valign(fa_top);
    }
}

// === Resolution ===
draw_set_color(c_white);
draw_text(label_x_pos, resolution_y_label, "Resolution:");
var res = global.resolution_options[global.resolution_index];
var res_text = string(res[0]) + " x " + string(res[1]);
var dd_res_box_y = resolution_y_label;
draw_set_color(make_color_rgb(100,100,100));
draw_rectangle(value_x_pos, dd_res_box_y, value_x_pos + value_width, dd_res_box_y + dropdown_item_height, true);
draw_set_color(c_white);
draw_set_valign(fa_middle);
draw_text(value_x_pos + padding_small, dd_res_box_y + dropdown_item_height / 2, res_text);
draw_set_valign(fa_top);

if (dropdown_resolution_open) {
    for (var i = 0; i < array_length(global.resolution_options); i++) {
        var r_opt = global.resolution_options[i];
        var item_y = dd_res_box_y + dropdown_item_height * (i + 1);
        draw_set_color(make_color_rgb(100,100,100));
        draw_rectangle(value_x_pos, item_y, value_x_pos + value_width, item_y + dropdown_item_height, true);
        draw_set_color((i == dropdown_hover_index && settings_index == 1) ? c_yellow : c_white);
        draw_set_valign(fa_middle);
        draw_text(value_x_pos + padding_small, item_y + dropdown_item_height / 2, string(r_opt[0]) + " x " + string(r_opt[1]));
        draw_set_valign(fa_top);
    }
}

// === SFX Volume ===
draw_set_color(c_white);
draw_text(label_x_pos, sfx_volume_y_label, "SFX Volume:");
var slider_sfx_y = sfx_volume_y_label;
var slider_actual_width = value_width; // Use available width for slider
draw_set_color(make_color_rgb(40,40,40)); // col_bg
draw_rectangle(value_x_pos, slider_sfx_y, value_x_pos + slider_actual_width, slider_sfx_y + slider_bar_height, false);
draw_set_color(make_color_rgb(100,100,100)); // col_highlight
draw_rectangle(value_x_pos, slider_sfx_y, value_x_pos + global.sfx_volume * slider_actual_width, slider_sfx_y + slider_bar_height, false);

// === Music Volume ===
draw_set_color(c_white);
draw_text(label_x_pos, music_volume_y_label, "Music Volume:");
var slider_music_y = music_volume_y_label;
draw_set_color(make_color_rgb(40,40,40)); // col_bg
draw_rectangle(value_x_pos, slider_music_y, value_x_pos + slider_actual_width, slider_music_y + slider_bar_height, false);
draw_set_color(make_color_rgb(100,100,100)); // col_highlight
draw_rectangle(value_x_pos, slider_music_y, value_x_pos + global.music_volume * slider_actual_width, slider_music_y + slider_bar_height, false);

// === Back ===
draw_set_color(c_white);
draw_text(label_x_pos, back_y_label, "Back (ESC / B)");

// --- Reset Drawing Settings ---
draw_set_font(-1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
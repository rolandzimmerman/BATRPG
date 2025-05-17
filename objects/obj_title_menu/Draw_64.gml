/// obj_title_menu - Draw GUI Event
if (!active) {
    exit;
}

var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _center_x = _gui_w / 2;

// --- Title ---
var title_font = Font1; // <<<< SET YOUR TITLE FONT >>>>
if (font_exists(title_font)) draw_set_font(title_font); else draw_set_font(-1);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text_color(_center_x, _gui_h * 0.25, "We Only Come Out at Night", c_yellow, c_yellow, c_yellow, c_yellow, 1);

// --- Menu Items ---
var menu_font = Font1; // <<<< SET YOUR MENU FONT >>>>
if (font_exists(menu_font)) draw_set_font(menu_font); else draw_set_font(-1);

var item_start_y = _gui_h * 0.50;
var line_height = string_height("Hg") + 20; // Dynamic line height based on font + padding

for (var i = 0; i < menu_item_count; i++) {
    var current_item_text = menu_items[i];
    var current_item_y = item_start_y + (i * line_height);
    var text_color = c_white;
    var text_scale = 1;

    if (i == menu_index) {
        text_color = c_yellow; // Highlight color for selected item
        text_scale = 1.1;      // Slightly larger text for selected item
        // Optional: Draw a selector sprite
        // if (sprite_exists(spr_menu_selector)) {
        //     draw_sprite(spr_menu_selector, 0, _center_x - (string_width(current_item_text) * text_scale / 2) - 30, current_item_y);
        // }
    }
    draw_text_transformed_color(_center_x, current_item_y, current_item_text, text_scale, text_scale, 0, text_color, text_color, text_color, text_color, 1);
}

// Reset drawing settings
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
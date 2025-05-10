/// obj_battle_log :: Draw GUI Event

// --- Read Configuration from Instance Variables (set in Create Event) ---
var log_margin_x, log_margin_y, box_width, max_lines, padding;

if (variable_instance_exists(id, "config_log_margin_x")) {
    log_margin_x = variable_instance_get(id, "config_log_margin_x");
} else {
    log_margin_x = 30; // Default margin from right
}

if (variable_instance_exists(id, "config_log_margin_y")) {
    log_margin_y = variable_instance_get(id, "config_log_margin_y");
} else {
    log_margin_y = 30; // Default margin from bottom
}

if (variable_instance_exists(id, "config_box_total_width")) {
    box_width = variable_instance_get(id, "config_box_total_width");
} else {
    box_width = 800; // Default to user-requested width
}

if (variable_instance_exists(id, "config_max_visible_lines")) {
    max_lines = variable_instance_get(id, "config_max_visible_lines");
} else {
    max_lines = 8; // Default to user-requested lines
}

if (variable_instance_exists(id, "config_box_padding")) {
    padding = variable_instance_get(id, "config_box_padding");
} else {
    padding = 8; // Default to user's padding value
}

// --- Font & Initial Draw Settings ---
var actual_font_to_use = Font1; 
if (!font_exists(actual_font_to_use)) {
    actual_font_to_use = -1; 
}
draw_set_font(actual_font_to_use); 

var current_font_size = font_get_size(actual_font_to_use); 
if (!is_real(current_font_size) || current_font_size <= 0) { 
    current_font_size = 24; 
}
var calculated_line_height = current_font_size + floor(current_font_size * 0.5);

// --- Early Exit if no logEntries ---
if (!variable_instance_exists(id, "logEntries") || !is_array(logEntries) || array_length(logEntries) == 0) {
    exit;
}
var current_log_index = array_length(logEntries) - 1;

// --- Calculate Box and Text Area Dimensions & Positions (for Lower-Right) ---
var box_total_h = (max_lines * calculated_line_height) + (padding * 2);
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
var box_draw_x = gui_w - box_width - log_margin_x;
var box_draw_y = gui_h - box_total_h - log_margin_y;
var text_area_x = box_draw_x + padding;
var text_area_y = box_draw_y + padding;
var text_wrap_w = box_width - (padding * 2);
if (text_wrap_w < 10) text_wrap_w = 10; 
var text_area_max_h = max_lines * calculated_line_height;
var text_area_bottom_y = text_area_y + text_area_max_h;

// --- Draw Background Box ---
var box_bg_sprite = spr_box1; 
if (sprite_exists(box_bg_sprite)) {
    var sw = sprite_get_width(box_bg_sprite);
    var sh = sprite_get_height(box_bg_sprite);
    if (sw > 0 && sh > 0) {
        draw_sprite_ext(box_bg_sprite, -1, box_draw_x, box_draw_y,
                        box_width / sw, box_total_h / sh, 0, c_white, 0.9);
    } else { 
        draw_set_color(c_dkgray); draw_set_alpha(0.8); 
        draw_rectangle(box_draw_x, box_draw_y, box_draw_x + box_width, box_draw_y + box_total_h, false);
        draw_set_alpha(1); draw_set_color(c_white);
    }
} else { 
    draw_set_color(c_dkgray); draw_set_alpha(0.8); 
    draw_rectangle(box_draw_x, box_draw_y, box_draw_x + box_width, box_draw_y + box_total_h, false);
    draw_set_alpha(1); draw_set_color(c_white);
}

// --- Determine Which Log Entries to Draw ---
var entries_to_render_data = []; 
var current_accumulated_height = 0;

for (var i = current_log_index; i >= 0; i--) {
    if (!is_string(logEntries[i])) continue; 
    var entry_text = logEntries[i];
    if (string_length(entry_text) == 0) continue; 

    var entry_render_height = string_height_ext(entry_text, calculated_line_height, text_wrap_w);
    // If string_height_ext returns 0 for a non-empty string (e.g., only spaces, or problematic wrap_w),
    // assign at least one line_height to prevent issues and ensure it's considered.
    if (entry_render_height <= 0 && string_length(entry_text) > 0) {
        entry_render_height = calculated_line_height; 
    }
    if (entry_render_height <= 0) continue; // Skip if still no valid height

    if (current_accumulated_height + entry_render_height > text_area_max_h) {
        if (array_length(entries_to_render_data) == 0) { // First entry checked is already too big
            array_insert(entries_to_render_data, 0, {text: entry_text, height: entry_render_height});
        }
        break; 
    }
    array_insert(entries_to_render_data, 0, {text: entry_text, height: entry_render_height});
    current_accumulated_height += entry_render_height;
}

// --- Draw The Determined Log Entries ---
draw_set_color(c_white); 
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var y_draw_cursor = text_area_y; 

for (var i = 0; i < array_length(entries_to_render_data); i++) {
    var entry_data = entries_to_render_data[i];
    var text_to_draw = entry_data.text;
    var expected_draw_height = entry_data.height; // Height calculated by string_height_ext

    // Safety break: if y_cursor is already at/past the bottom or no height for this entry
    if (y_draw_cursor >= text_area_bottom_y || expected_draw_height <= 0) {
        break;
    }
    
    // Even if this specific entry might partially exceed text_area_bottom_y, we draw it.
    // Visual clipping will occur at the bounds of where things are drawn (e.g. GUI layer limits or surface limits if used)
    // The collection loop already tried to ensure the *set* of entries fits.
    
    draw_text_ext(
        text_area_x,          
        y_draw_cursor,        
        text_to_draw,         
        calculated_line_height, // This is the 'sep' argument for internal line spacing during wrap     
        text_wrap_w           
    );
    
    // Advance y_draw_cursor by the pre-calculated height this entry is expected to take.
    // This is more reliable than relying on draw_text_ext's return value for complex cases.
    y_draw_cursor += expected_draw_height; 
}

// Reset alpha and color if they were changed by fallback box drawing and not reset after.
draw_set_alpha(1);
draw_set_color(c_white);
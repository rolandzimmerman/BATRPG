/// obj_levelup_popup :: Draw GUI Event
/// — Draw the box, title, stats, and new spells learned

// Ensure essential instance variables are available
if (!variable_instance_exists(id, "info") || !is_struct(info) ||
    !variable_instance_exists(id, "keys") || !is_array(keys)) {
    if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1); // Use fallback if Font1 missing
    draw_text(10, 10, "Level Up Popup Error: Info/Keys missing.");
    if (font_exists(Font1)) draw_set_font(-1); // Reset font
    exit;
}

// --- Font and Dynamic Layout Setup ---
var current_font = Font1;
if (!font_exists(current_font)) {
    current_font = -1; // Fallback to default system font if Font1 doesn't exist
    show_debug_message("Warning: Font1 not found, using default font for level up popup.");
}
draw_set_font(current_font);


var _text_height_example = string_height("Hg"); // "Hg" is good for typical ascenders/descenders
var lineH = ceil(_text_height_example + 10); // Base line height for stats and spells
var padding = 20;      // Overall padding inside the box edges
var column_gap_padding = ceil(_text_height_example * 0.75); // Gap between columns

// --- Calculate Required Content Dimensions ---
var title_text = (variable_struct_exists(info, "name") ? string(info.name) : "Character") + " leveled up!";
var title_width = string_width(title_text);

var max_stat_label_w = 0;
var max_old_val_w = 0;
var max_new_val_w = 0;
var num_stat_lines = array_length(keys);

var min_stat_number_col_width = string_width("99999"); // Generous width for stat numbers

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

max_old_val_w = max(max_old_val_w, min_stat_number_col_width);
max_new_val_w = max(max_new_val_w, min_stat_number_col_width);

var separator_text = ">";
var separator_width = string_width(separator_text);

var stat_line_content_w = max_stat_label_w + column_gap_padding +
                          max_old_val_w + column_gap_padding +
                          separator_width + column_gap_padding +
                          max_new_val_w;

// --- Calculate Spells Learned Section Dimensions (IF ANY) ---
var spells_learned_header_text = "Spells Learned:";
var spells_header_h = 0; // Height of the "Spells Learned:" header itself
var spells_list_total_h = 0; // Total height for the list of spell names
var num_spells_learned = 0;
var max_spell_name_w = 0;
var spells_to_display = []; // Array of spell names to draw

if (variable_struct_exists(info, "new_spells_learned") && is_array(info.new_spells_learned)) {
    spells_to_display = info.new_spells_learned;
    num_spells_learned = array_length(spells_to_display);

    if (num_spells_learned > 0) {
        spells_header_h = lineH; // Header takes one line
        max_spell_name_w = max(max_spell_name_w, string_width(spells_learned_header_text));
        for (var i = 0; i < num_spells_learned; i++) {
            var spell_name = "- " + string(spells_to_display[i]); // Add a bullet point for display
            max_spell_name_w = max(max_spell_name_w, string_width(spell_name));
        }
        spells_list_total_h = num_spells_learned * lineH;
    }
}
// --- End Spells Section Calculation ---

var dynamic_content_width = max(title_width, stat_line_content_w, max_spell_name_w);
var final_box_w = dynamic_content_width + padding * 2; // Add outer left/right padding

// Calculate total content height: Title + Stats + Spells (if any)
var total_content_block_h = lineH; // For title
total_content_block_h += padding;   // Padding after title
total_content_block_h += (num_stat_lines * lineH); // For stats

if (num_spells_learned > 0) {
    total_content_block_h += padding; // Padding before spells header
    total_content_block_h += spells_header_h; // For "Spells Learned:" header
    // No extra padding between spell header and spell list items, lineH handles it
    total_content_block_h += spells_list_total_h; // For the spell names
}

var final_box_h = total_content_block_h + padding * 2; // Add outer top/bottom padding

// Use instance variables boxX, boxY for the top-left position, or center dynamically
var panel_x = self.boxX; // (display_get_gui_width()  - final_box_w) / 2; // For centering X
var panel_y = self.boxY; // (display_get_gui_height() - final_box_h) / 2; // For centering Y


// --- Background using 9-Slice (or fallback rectangle) ---
draw_set_alpha(0.9); // Semi-transparent background
var box_sprite = asset_get_index("spr_box1"); // Get sprite asset index
if (sprite_exists(box_sprite)) {
    var _spr_w = sprite_get_width(box_sprite);
    var _spr_h = sprite_get_height(box_sprite);
    if (_spr_w > 0 && _spr_h > 0) { // Ensure sprite dimensions are valid
        draw_sprite_ext(box_sprite, -1, panel_x, panel_y,
                        final_box_w / _spr_w, final_box_h / _spr_h,
                        0, c_white, 1.0);
    } else {
        // Fallback if sprite dimensions are invalid
        draw_set_color(make_color_rgb(30,30,30));
        draw_rectangle(panel_x, panel_y, panel_x + final_box_w, panel_y + final_box_h, false);
    }
} else {
    // Fallback if sprite doesn't exist
    draw_set_color(make_color_rgb(30,30,30));
    draw_rectangle(panel_x, panel_y, panel_x + final_box_w, panel_y + final_box_h, false);
}
draw_set_alpha(1.0); // Reset alpha

// --- Draw Content (Title, Stats, Spells) ---
var current_draw_y = panel_y + padding; // Start drawing Y position, will be incremented
var content_start_x = panel_x + padding; // Start drawing X position for content

// Title
draw_set_color(titleColor); // Use titleColor defined in Create event
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(content_start_x, current_draw_y, title_text);
current_draw_y += lineH + padding; // Advance Y past title and add a gap

// Stats Display Area
var stats_area_y = current_draw_y; // Y position for the first stat line

// Define column start X positions based on calculated max widths
var col_label_start_x = content_start_x;
var col_old_val_start_x = col_label_start_x + max_stat_label_w + column_gap_padding;
var col_separator_start_x = col_old_val_start_x + max_old_val_w + column_gap_padding;
var col_new_val_start_x = col_separator_start_x + separator_width + column_gap_padding;

for (var i = 0; i < num_stat_lines; i++) {
    var key = keys[i];
    var stat_draw_y = stats_area_y + i * lineH; // Y for current stat line

    var oldV_str = "N/A"; var oldV_val = 0;
    if (variable_struct_exists(info, "old") && is_struct(info.old) && variable_struct_exists(info.old, key)) {
        oldV_val = info.old[$ key]; oldV_str = string(oldV_val);
    }
    var newV_str = "N/A"; var newV_val = 0;
    if (variable_struct_exists(info, "new") && is_struct(info.new) && variable_struct_exists(info.new, key)) {
        newV_val = info.new[$ key]; newV_str = string(newV_val);
    }

    var stat_label_text = string_upper(key) + ":";
    draw_set_halign(fa_left);
    draw_set_color(oldColor); // Using oldColor for stat labels as they are 'prior' info context
    draw_text(col_label_start_x, stat_draw_y, stat_label_text);

    draw_set_halign(fa_right);
    draw_set_color(oldColor); // Using oldColor for old values
    draw_text(col_old_val_start_x + max_old_val_w, stat_draw_y, oldV_str);

    draw_set_halign(fa_center);
    draw_set_color(sepColor); // Using sepColor for the separator
    draw_text(col_separator_start_x + separator_width / 2, stat_draw_y, separator_text);

    var new_val_color = newColor; // Default new value color
    if (is_real(newV_val) && is_real(oldV_val)) {
        if (newV_val > oldV_val) new_val_color = newColorUp; // Green if increased
        // else if (newV_val < oldV_val) new_val_color = c_red; // Optionally red if decreased
    }
    draw_set_halign(fa_right);
    draw_set_color(new_val_color);
    draw_text(col_new_val_start_x + max_new_val_w, stat_draw_y, newV_str);
}
current_draw_y += (num_stat_lines * lineH); // Advance Y past the block of stats

// --- Draw Spells Learned (IF ANY) ---
if (num_spells_learned > 0) {
    current_draw_y += padding; // Add a gap after stats, before the spells section

    draw_set_halign(fa_left);
    draw_set_color(titleColor); // Use titleColor for this header, or a new color
    draw_text(content_start_x, current_draw_y, spells_learned_header_text);
    current_draw_y += lineH; // Advance Y past spells header (spells_header_h includes this lineH)

    var spell_text_x = content_start_x + padding / 2; // Indent spell names slightly
    for (var i = 0; i < num_spells_learned; i++) {
        var spell_name_to_draw = "- " + string(spells_to_display[i]);
        draw_set_color(newColorUp); // Use lime color for new spells
        draw_text(spell_text_x, current_draw_y, spell_name_to_draw);
        current_draw_y += lineH; // Advance Y for the next spell name
    }
}
// --- End Draw Spells Learned ---

// --- Reset Drawing Settings ---
draw_set_font(-1); // Reset to default font if 'current_font' was not -1
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
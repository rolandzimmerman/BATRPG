/// obj_spell_menu_field :: Draw GUI Event
if (!active) return;

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Set font and determine dynamic line height
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1); // Fallback to default font
}
var _text_height_example = string_height("Mg"); // Get typical height of text with ascenders/descenders
var line_height = ceil(_text_height_example + 8); // Add 8px padding; ceil for whole pixels. Adjust padding as needed.
                                                  // For Font 24, line_height might be around 32-38px.

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0);

// --- Menu State & Data Checks ---
if (!variable_instance_exists(id, "menu_state")) exit;
if (!variable_instance_exists(id, "character_index")) exit;
if (!variable_instance_exists(id, "spell_index")) exit;
if (!variable_instance_exists(id, "usable_spells")) exit;
if (!variable_instance_exists(id, "selected_caster_key")) exit;
if (menu_state == "target_select_ally" && !variable_instance_exists(id, "target_party_index")) exit;

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white);

// --- Constants & Layout Variables (Adjusted for larger font) ---
var list_items_to_show = 10; // With larger line_height, this list might become very tall. Adjust if needed.
var box_margin = 64;
var box_width = 500; // Increased from 400, tune based on content width with Font 24
var pad = 16;        // Padding inside boxes, might need slight increase (e.g., 20 or 24)
var title_h = line_height; // Title height matches line height
var list_select_color = c_yellow;
var party_list_keys = global.party_members ?? [];
var party_count = array_length(party_list_keys);

// --- Character Selection Header ---
var char_box_h = line_height + pad * 1.5; // Dynamic height based on new line_height and some padding
var char_slot_width_estimate = 180; // Increased estimate for wider names with Font 24. Tune this value!
var char_box_w = max(box_width, party_count * char_slot_width_estimate); // Ensure it's at least as wide as other boxes
var char_box_x = (gui_w - char_box_w) / 2;
var char_box_y = box_margin;

if (party_count > 0) {
    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, char_box_x, char_box_y, char_box_w, char_box_h);
    } else { // Fallback drawing if spr_box1 is missing
        draw_set_alpha(0.8);
        draw_set_color(c_black);
        draw_rectangle(char_box_x, char_box_y, char_box_x + char_box_w, char_box_y + char_box_h, false);
        draw_set_alpha(1.0);
    }
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var char_y_center = char_box_y + char_box_h / 2; // Y-coordinate for centering text in the char_box

    for (var i = 0; i < party_count; i++) {
        var p_key = party_list_keys[i];
        var p_data = (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, p_key))
                     ? ds_map_find_value(global.party_current_stats, p_key)
                     : undefined;
        var display_name = (is_struct(p_data) && variable_struct_exists(p_data, "name"))
                           ? p_data.name
                           : p_key;
        var draw_x = char_box_x + (char_box_w * (i + 0.5) / party_count);
        var text_color = (menu_state == "character_select" && i == character_index)
                         ? list_select_color
                         : c_white;

        // Character selection highlight (thin bar below name)
        if (menu_state == "character_select" && i == character_index) {
            var tw = string_width(display_name);
            // The highlight was drawn relative to char_y + line_height/2.
            // If char_y_center is true middle, and line_height is actual text draw height,
            // then text is from char_y_center - _text_height_example/2 to char_y_center + _text_height_example/2.
            // The previous rectangle was effectively an underline. Let's keep its relative positioning.
            // For Font 24, _text_height_example might be ~26-30. line_height ~34-38.
            var highlight_bar_y_top = char_y_center + (_text_height_example / 2) - 2; // Example adjustment
            var highlight_bar_y_bottom = char_y_center + (_text_height_example / 2) + 2; // Making it a 4px bar under text
            
            draw_set_color(list_select_color); // Ensure color is set before drawing rect
            draw_set_alpha(0.6); // Make highlight slightly transparent
            draw_rectangle(draw_x - tw/2 - 4, highlight_bar_y_top,
                           draw_x + tw/2 + 4, highlight_bar_y_bottom,
                           false); // Changed to false for a filled rectangle, adjust as preferred
            draw_set_alpha(1.0);
        }

        draw_set_color(text_color);
        draw_text(draw_x, char_y_center, display_name); // Use char_y_center for middle alignment
    }
}

// --- Draw Spell List or Target List ---
var list_box_w = box_width; // Use the adjusted box_width
var list_box_x = (gui_w - list_box_w) / 2;
var list_box_y = char_box_y + char_box_h + pad; // Position below character box
var title_y_pos = list_box_y + pad;
var list_items_start_y = title_y_pos + title_h; // Start list below title
var list_text_x = list_box_x + pad;
var title_text = "";

if (menu_state == "spell_select") {
    title_text = (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, selected_caster_key))
                 ? (ds_map_find_value(global.party_current_stats, selected_caster_key).name ?? selected_caster_key) + " - Spells"
                 : "Select Spell";
    var spell_count = array_length(usable_spells);
    // Calculate height needed for visible spell items
    var visible_items_h = (spell_count > 0) ? min(spell_count, list_items_to_show) * line_height : line_height;
    var list_box_h = title_h + visible_items_h + pad * 2; // Total height of the spell list box

    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, list_box_x, list_box_y, list_box_w, list_box_h);
    } // Fallback drawing for box can be added here if needed

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle); // For title
    draw_text(list_box_x + list_box_w / 2, title_y_pos + title_h / 2, title_text);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top); // Reset for list items

    var current_mp = (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, selected_caster_key))
                     ? ds_map_find_value(global.party_current_stats, selected_caster_key).mp
                     : 0;
    var cost_x = list_box_x + list_box_w - pad; // X-pos for MP cost (right-aligned)

    for (var i = 0; i < min(spell_count, list_items_to_show); i++) { // Loop through visible spells
        var spell_data = usable_spells[i]; // This should be the actual index from scrolling, not just 'i' if list scrolls
                                          // For now, assuming top 'list_items_to_show' are visible
        var display_y = list_items_start_y + i * line_height;
        var name_text = spell_data.name ?? "???";
        var cost = spell_data.cost ?? 0;
        var cost_text = string(cost) + " MP";
        var can_afford = (current_mp >= cost);
        var color = can_afford ? c_white : c_gray;

        if (i == spell_index) { // Check against the actual current spell_index
            draw_set_alpha(0.4);
            draw_set_color(list_select_color);
            draw_rectangle(list_box_x + pad/2, display_y - 2,
                           list_box_x + list_box_w - pad/2, display_y + line_height - 2,
                           false);
            draw_set_alpha(1.0);
            color = list_select_color; // Highlighted text color
        }

        draw_set_color(color);
        draw_text(list_text_x, display_y, name_text);
        draw_set_halign(fa_right);
        draw_text(cost_x, display_y, cost_text);
        draw_set_halign(fa_left);
    }
}
else if (menu_state == "target_select_ally") {
    title_text = "Select Target";
    var visible_targets_h = (party_count > 0) ? min(party_count, list_items_to_show) * line_height : line_height;
    var list_box_h = title_h + visible_targets_h + pad * 2;

    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, list_box_x, list_box_y, list_box_w, list_box_h);
    } // Fallback box drawing

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle); // For title
    draw_text(list_box_x + list_box_w / 2, title_y_pos + title_h / 2, title_text);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top); // Reset for list items

    for (var i = 0; i < min(party_count, list_items_to_show); i++) { // Loop through visible party members
        // This needs to account for scrolling if party_count > list_items_to_show
        // For now, assumes top members are shown.
        var p_key = party_list_keys[i]; // This should use a scrolled index if implemented
        var p_data = (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, p_key))
                     ? ds_map_find_value(global.party_current_stats, p_key)
                     : undefined;
        var display_y = list_items_start_y + i * line_height;
        var name_text = (is_struct(p_data) && variable_struct_exists(p_data, "name")) ? p_data.name : p_key;
        var hpmp_text = is_struct(p_data)
                        ? "HP " + string(p_data.hp) + "/" + string(p_data.maxhp) + " MP " + string(p_data.mp) + "/" + string(p_data.maxmp)
                        : "";
        var valid_color = (is_struct(p_data) && p_data.hp > 0) ? c_white : c_gray; // Gray out if KO'd

        if (i == target_party_index) { // Check against the actual current target_party_index
            draw_set_alpha(0.4);
            draw_set_color(list_select_color);
            draw_rectangle(list_box_x + pad/2, display_y - 2,
                           list_box_x + list_box_w - pad/2, display_y + line_height - 2,
                           false);
            draw_set_alpha(1.0);
            valid_color = list_select_color; // Highlighted text color
        }

        draw_set_color(valid_color);
        draw_text(list_text_x, display_y, name_text);
        draw_set_halign(fa_right);
        draw_text(list_box_x + list_box_w - pad, display_y, hpmp_text);
        draw_set_halign(fa_left);
    }
}

// --- Reset Drawing State ---
draw_set_font(-1); // Reset to default font
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
draw_set_color(c_white);
/// obj_item_menu_field :: Draw GUI Event
if (!active) return;

// Ensure necessary global variables exist for drawing party list
if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
    if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);
    show_debug_message("obj_item_menu_field: global.party_members not found or not an array. Drawing error message.");
    draw_text(10,10,"Item Menu Error: Party data missing!");
    if (font_exists(Font1)) draw_set_font(-1);
    return;
}

// --- Basic Setup & Font ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1);
}

// --- Dynamic Layout Calculation ---
var _text_height_example = string_height("Hg");
var line_height = ceil(_text_height_example + 10);
var title_h = ceil(_text_height_example + 12);
var pad = 20;
var small_pad = 8;
var box_margin = 48;
var list_items_to_show = 10;
var list_select_color = c_yellow;

// --- Safety Checks for Essential Instance Variables ---
if (!variable_instance_exists(id, "menu_state") ||
    !variable_instance_exists(id, "usable_items") ||
    !variable_instance_exists(id, "item_index") ||
    !variable_instance_exists(id, "target_party_index")) {
    show_debug_message("obj_item_menu_field Draw GUI Error: Essential menu instance variables missing.");
    draw_text(10,10,"Item Menu Error: Instance data missing!");
    draw_set_font(-1);
    return;
}

// Determine current list and title based on menu_state
var current_list_array;
var title_text_main; // Renamed to avoid conflict with local title_text in currency section
var _item_count_for_height_calc;

if (menu_state == "item_select") {
    title_text_main = "Items";
    current_list_array = usable_items;
    _item_count_for_height_calc = array_length(usable_items);
} else if (menu_state == "target_select") {
    title_text_main = "Use Item On:";
    current_list_array = global.party_members ?? [];
    _item_count_for_height_calc = array_length(current_list_array);
} else {
    title_text_main = "Error";
    current_list_array = [];
    _item_count_for_height_calc = 0;
}
var current_list_count = array_length(current_list_array);

// --- Calculate Dynamic Width for Main Box ---
var max_line_content_w = string_width(title_text_main);
var icon_area_width = 32 + small_pad;

for (var i = 0; i < current_list_count; i++) {
    var line_text_left = "";
    var line_text_right = "";
    var prefix_w = string_width("> [1st] ");

    if (menu_state == "item_select" && i < array_length(usable_items)) {
        var entry = usable_items[i];
        line_text_left = entry.name ?? "Unknown Item";
        line_text_right = "x" + string(entry.quantity ?? 0);
        max_line_content_w = max(max_line_content_w, prefix_w + icon_area_width + string_width(line_text_left) + small_pad + string_width(line_text_right));
    } else if (menu_state == "target_select" && i < array_length(global.party_members ?? [])) {
        var memberKey_calc = global.party_members[i]; // Use different var name
        var stats_calc = (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, memberKey_calc))
                    ? ds_map_find_value(global.party_current_stats, memberKey_calc) : undefined;
        line_text_left = (is_struct(stats_calc) && variable_struct_exists(stats_calc, "name")) ? stats_calc.name : memberKey_calc;
        line_text_right = is_struct(stats_calc) ? "HP " + string(stats_calc.hp ?? 0) + "/" + string(stats_calc.maxhp ?? 0) : "";
        max_line_content_w = max(max_line_content_w, prefix_w + string_width(line_text_left) + small_pad + string_width(line_text_right));
    }
}
var dynamic_box_content_width = max_line_content_w;
var box_width_main = dynamic_box_content_width + pad * 2; // main list box width
var min_main_box_width = 350;
box_width_main = max(box_width_main, min_main_box_width);

// --- Compute Main Box Height & Position ---
var list_display_count = min(current_list_count, list_items_to_show);
var list_actual_h = (list_display_count > 0) ? list_display_count * line_height : line_height;
var box_height_main = title_h + list_actual_h + pad * 3; // main list box height
var box_x_main = box_margin;
var box_y_main = (gui_h - box_height_main) / 2;

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white);

// --- Draw Main Menu Box (using draw_sprite_ext with 9-slice enabled on spr_box1) ---
// This is line 105 (approximately) from your error message.
if (sprite_exists(spr_box1)) {
    var _spr_w = sprite_get_width(spr_box1);
    var _spr_h = sprite_get_height(spr_box1);
    if (_spr_w > 0 && _spr_h > 0) {
        // Ensure 9-slice is enabled for spr_box1 in the Sprite Editor
        draw_sprite_ext(spr_box1, -1, box_x_main, box_y_main, 
                        box_width_main / _spr_w, box_height_main / _spr_h, 
                        0, c_white, 1.0);
    } else { /* Fallback rect */ draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(box_x_main, box_y_main, box_x_main + box_width_main, box_y_main + box_height_main, false); draw_set_alpha(1.0); }
} else { /* Fallback rect */ draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(box_x_main, box_y_main, box_x_main + box_width_main, box_y_main + box_height_main, false); draw_set_alpha(1.0); }
draw_set_color(c_white);

// --- Draw Title ---
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(box_x_main + box_width_main / 2, box_y_main + pad + title_h / 2, title_text_main);

// --- Draw Item or Target List ---
draw_set_halign(fa_left);
draw_set_valign(fa_top); 
var list_content_start_x = box_x_main + pad; // Assuming box_x_main, pad are defined
var list_content_start_y = box_y_main + pad + title_h + pad; // Assuming box_y_main, title_h are defined

if (menu_state == "item_select") {
    var item_name_x = list_content_start_x + icon_area_width; // icon_area_width should be defined
    var qty_x = box_x_main + box_width_main - pad; // Assuming box_width_main is defined

    for (var i = 0; i < list_display_count; i++) { // list_display_count uses current_list_count
        var entry = current_list_array[i]; // Use current_list_array which is usable_items here
        var row_y = list_content_start_y + i * line_height;
        var current_text_color = c_white;

        if (i == item_index) {
            draw_set_alpha(0.4); draw_set_color(list_select_color);
            draw_rectangle(box_x_main + small_pad, row_y - (line_height - _text_height_example)/2,
                           box_x_main + box_width_main - small_pad, row_y + line_height - (line_height - _text_height_example)/2, false);
            draw_set_alpha(1.0);
            current_text_color = list_select_color;
        }
        draw_set_color(current_text_color);
        draw_set_halign(fa_left);
        draw_text(item_name_x, row_y, entry.name ?? "Unknown Item");
        draw_set_halign(fa_right);
        draw_text(qty_x, row_y, "x" + string(entry.quantity ?? 0));
    }
} else if (menu_state == "target_select") {
    var name_x = list_content_start_x;
    var stats_x = box_x_main + box_width_main - pad;

    for (var i = 0; i < list_display_count; i++) {
        // VVVV THIS IS THE CORRECTED LINE (AROUND YOUR LINE 158) VVVV
        var memberKey = (i < current_list_count) ? current_list_array[i] : undefined;
        // ^^^^ Use current_list_array and current_list_count ^^^^

        if (memberKey == undefined) continue; // Safety check, skip if out of bounds

        var stats = (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, memberKey))
                    ? ds_map_find_value(global.party_current_stats, memberKey) : undefined;
        var row_y = list_content_start_y + i * line_height;
        var dispName = (is_struct(stats) && variable_struct_exists(stats, "name")) ? stats.name : memberKey;
        var dispHP = is_struct(stats) ? "HP " + string(stats.hp ?? 0) + "/" + string(stats.maxhp ?? 0) : "";
        var textCol = (is_struct(stats) && stats.hp > 0) ? c_white : c_dkgray;

        if (i == target_party_index) { 
            draw_set_alpha(0.4); draw_set_color(list_select_color);
            draw_rectangle(box_x_main + small_pad, row_y - (line_height - _text_height_example)/2,
                           box_x_main + box_width_main - small_pad, row_y + line_height - (line_height - _text_height_example)/2, false);
            draw_set_alpha(1.0);
            textCol = list_select_color;
        }
        draw_set_color(textCol);
        draw_set_halign(fa_left);
        draw_text(name_x, row_y, dispName);
        draw_set_halign(fa_right);
        draw_text(stats_x, row_y, dispHP);
    }
}
draw_set_color(c_white); // Reset color

// --- Draw Preview Box (Right of main list) ---
var PREVIEW_SIZE = 96;
var PREVIEW_X = box_x_main + box_width_main + pad;
var PREVIEW_Y = box_y_main; // Align top with main box

if (sprite_exists(spr_box1)) {
    var _spr_w_pv = sprite_get_width(spr_box1);
    var _spr_h_pv = sprite_get_height(spr_box1);
    if (_spr_w_pv > 0 && _spr_h_pv > 0) {
        draw_sprite_ext(spr_box1, -1, PREVIEW_X, PREVIEW_Y,
                        PREVIEW_SIZE / _spr_w_pv, PREVIEW_SIZE / _spr_h_pv,
                        0, c_white, 1.0);
    } else { /* Fallback rect */ draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(PREVIEW_X, PREVIEW_Y, PREVIEW_X + PREVIEW_SIZE, PREVIEW_Y + PREVIEW_SIZE, false); draw_set_alpha(1.0); }
} else { /* Fallback rect */ draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(PREVIEW_X, PREVIEW_Y, PREVIEW_X + PREVIEW_SIZE, PREVIEW_Y + PREVIEW_SIZE, false); draw_set_alpha(1.0); }

// Draw selected item's icon inside preview
if (menu_state == "item_select" && item_index >= 0 && item_index < array_length(usable_items)) {
    var item_entry = usable_items[item_index];
    if (is_struct(item_entry) && variable_struct_exists(item_entry, "sprite")) {
        var sprID = item_entry.sprite;
        if (sprID != undefined && sprID >= 0 && sprite_exists(sprID)) {
            var sw_icon = sprite_get_width(sprID);
            var sh_icon = sprite_get_height(sprID);
            var dx_icon = PREVIEW_X + (PREVIEW_SIZE - sw_icon) / 2;
            var dy_icon = PREVIEW_Y + (PREVIEW_SIZE - sh_icon) / 2;
            draw_sprite(sprID, 0, dx_icon, dy_icon);
        }
    }
}
draw_set_color(c_white);

// --- Draw Currency Display in Top-Left ---
var curTxt = "Gold: " + string(global.party_currency ?? 0);
var cur_text_w = string_width(curTxt);
var cur_text_h = _text_height_example;
var cur_pad = ceil(line_height * 0.3);

var cur_box_content_w = cur_text_w;
var cur_box_content_h = cur_text_h;
var cur_box_final_w = cur_box_content_w + cur_pad * 2;
var cur_box_final_h = cur_box_content_h + cur_pad * 2;
var cur_box_x = box_margin / 2;
var cur_box_y = box_margin / 2;

if (sprite_exists(spr_box1)) {
    var _spr_w_gold = sprite_get_width(spr_box1);
    var _spr_h_gold = sprite_get_height(spr_box1);
    if (_spr_w_gold > 0 && _spr_h_gold > 0) {
        draw_sprite_ext(spr_box1, -1, cur_box_x, cur_box_y,
                        cur_box_final_w / _spr_w_gold, cur_box_final_h / _spr_h_gold,
                        0, c_white, 1.0);
    } else { /* Fallback rect */ draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(cur_box_x, cur_box_y, cur_box_x + cur_box_final_w, cur_box_y + cur_box_final_h, false); draw_set_alpha(1.0); }
} else { /* Fallback rect */ draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(cur_box_x, cur_box_y, cur_box_x + cur_box_final_w, cur_box_y + cur_box_final_h, false); draw_set_alpha(1.0); }

draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(cur_box_x + cur_box_final_w / 2, cur_box_y + cur_box_final_h / 2, curTxt);

// --- Reset Drawing State ---
draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(-1);
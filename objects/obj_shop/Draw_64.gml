/// obj_shop :: Draw GUI Event

// Only draw when the shop is active
if (!shop_active) return;

// Fetch GUI dimensions
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Font and Dynamic Layout Setup ---
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1);
}
var _text_height_example = string_height("Mg"); // Example string for height
var line_h = ceil(_text_height_example + 8);    // Line height for list items
var title_line_h = ceil(_text_height_example + 12); // Line height for titles

// Common styling setup
var padding = 16;       // General padding for UI elements
var box_margin = 32;    // Margin from screen edges
var max_visible_items = 8;
var initial_main_box_x = 64; // Default starting X for the shop panel
var items_in_stock = shop_stock;
var item_stock_count = array_length(items_in_stock);

// Default draw settings
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0);

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white);


// === BROWSE STATE: Show stock list ===
if (shop_state == "browse") {
    var shop_title_text = "Shop";
    
    // --- Calculate dynamic box_w based on content ---
    var calculated_content_width = 0;
    var min_content_width = 350; // A sensible minimum width for the content area

    if (item_stock_count > 0) {
        for (var i = 0; i < item_stock_count; i++) {
            var item_key = items_in_stock[i];
            var item_data = scr_GetItemData(item_key);
            var item_name = item_data.name ?? item_key;
            var buy_price = ceil((item_data.value ?? 0) * buyMultiplier);
            var sell_price = ceil((item_data.value ?? 0) * sellMultiplier);
            var prices_text = "B:" + string(buy_price) + "  S:" + string(sell_price);
            
            // Width needed: Name + a gap (padding) + Prices
            var current_line_width = string_width(item_name) + padding + string_width(prices_text);
            calculated_content_width = max(calculated_content_width, current_line_width);
        }
    }
    var box_w = max(calculated_content_width, min_content_width); // This is the width of the actual content area

    // Determine position and height of the main shop box
    var visible_item_count = min(item_stock_count, max_visible_items);
    var list_content_h = (visible_item_count > 0) ? (visible_item_count * line_h) : line_h;
    var current_box_content_h = title_line_h + list_content_h; // Height of just the content (title + items)
    
    // Adjust main_box_x if box_w (content width) + panel padding is too large
    var panel_total_width = box_w + padding * 2; // Total width of the panel including its own padding
    var main_box_x = initial_main_box_x;
    if (main_box_x + panel_total_width > gui_w - box_margin) {
        main_box_x = (gui_w - panel_total_width) / 2;
        if (main_box_x < box_margin) main_box_x = box_margin;
    }
    // current_box_y is the top of the content area
    var current_box_y = (gui_h - (current_box_content_h + padding * 2)) / 2; // Center panel vertically

    // Panel coordinates (drawn around the content area)
    var panel_x1 = main_box_x - padding;
    var panel_y1 = current_box_y - padding;
    var panel_x2 = main_box_x + box_w + padding;
    var panel_y2 = current_box_y + current_box_content_h + padding * 2; // Use current_box_content_h

    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, panel_x1, panel_y1, panel_x2 - panel_x1, panel_y2 - panel_y1);
    } else { 
        draw_set_alpha(0.8); draw_set_color(c_black);
        draw_rectangle(panel_x1, panel_y1, panel_x2, panel_y2, false);
        draw_set_alpha(1.0); draw_set_color(c_white);
    }

    // Shop Title (centered in the content width `box_w`, at the top of content area `main_box_x, current_box_y`)
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(main_box_x + box_w / 2, current_box_y + title_line_h / 2, shop_title_text);
    
    // Reset alignment for list items
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    // List items
    var list_items_content_start_y = current_box_y + title_line_h;
    for (var i = 0; i < visible_item_count; i++) {
        var item_key = items_in_stock[i]; 
        var item_data = scr_GetItemData(item_key);
        var item_name = item_data.name ?? item_key; // Full item name, no truncation
        var buy_price = ceil((item_data.value ?? 0) * buyMultiplier);
        var sell_price = ceil((item_data.value ?? 0) * sellMultiplier);
        var current_item_draw_y = list_items_content_start_y + i * line_h;
        var prices_text = "B:" + string(buy_price) + "  S:" + string(sell_price);

        if (i == shop_index) { 
            draw_set_alpha(0.4); draw_set_color(c_yellow);
            // Highlight rectangle covers the content width inside main_box_x
            draw_rectangle(main_box_x, current_item_draw_y - 2, main_box_x + box_w, current_item_draw_y + line_h - 2, false);
            draw_set_alpha(1.0); 
            draw_set_color(c_yellow);
        } else {
            draw_set_color(c_white);
        }

        // Item Name (drawn at main_box_x, which is start of content area)
        draw_text(main_box_x, current_item_draw_y, item_name);

        // Buy/Sell prices (drawn at main_box_x + box_w, right aligned, so it's at the right edge of content area)
        draw_set_halign(fa_right);
        draw_text(main_box_x + box_w, current_item_draw_y, prices_text);
        draw_set_halign(fa_left); 
    }
    draw_set_color(c_white); 

    // --- Player Gold Display --- (Logic from before, should be fine)
    var gold_text = "Gold: " + string(global.party_currency);
    var gold_text_w = string_width(gold_text);
    var gold_box_content_h = line_h;
    var gold_box_content_w = gold_text_w;
    
    var gold_panel_x = 32; 
    var gold_panel_y = 32;
    var gold_panel_true_w = gold_box_content_w + padding * 2;
    var gold_panel_true_h = gold_box_content_h + padding * 2;

    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, gold_panel_x, gold_panel_y, gold_panel_true_w, gold_panel_true_h);
    } else { 
        draw_set_alpha(0.8); draw_set_color(c_black);
        draw_rectangle(gold_panel_x, gold_panel_y, gold_panel_x + gold_panel_true_w, gold_panel_y + gold_panel_true_h, false);
        draw_set_alpha(1.0); draw_set_color(c_white);
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(gold_panel_x + gold_panel_true_w / 2, gold_panel_y + gold_panel_true_h / 2, gold_text);
    draw_set_halign(fa_left); 
    draw_set_valign(fa_top);  
}

// === CONFIRM PURCHASE STATE: Show yes/no prompt ===
else if (shop_state == "confirm_purchase") {
    var confirm_item_key = shop_stock[shop_index]; // shop_index should be valid here
    var confirm_item_data = scr_GetItemData(confirm_item_key);
    var confirm_item_name = confirm_item_data.name ?? confirm_item_key;
    
    // VVVV CORRECTED LINE VVVV
    var confirm_price = ceil((confirm_item_data.value ?? 0) * buyMultiplier); 
    // ^^^^ Was using 'item_data.value', now correctly uses 'confirm_item_data.value'

    var question_text = "Buy " + confirm_item_name + " for " + string(confirm_price) + "g?";
    
    // Confirmation box content width calculation
    var confirm_content_w = string_width(question_text);
    var yes_no_text_width = string_width("YES") + padding + string_width("NO"); // YES + gap + NO
    confirm_content_w = max(confirm_content_w, yes_no_text_width);
    confirm_content_w = max(confirm_content_w, 300); // Ensure a minimum sensible width

    var confirm_content_h = title_line_h + line_h + padding; // Question line + options line + padding between
    
    var confirm_panel_width = confirm_content_w + padding * 2;
    var confirm_panel_height = confirm_content_h + padding * 2;
    var confirm_panel_x1 = (gui_w - confirm_panel_width) / 2;
    var confirm_panel_y1 = (gui_h - confirm_panel_height) / 2;

    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, confirm_panel_x1, confirm_panel_y1, confirm_panel_width, confirm_panel_height);
    } else { 
        draw_set_alpha(0.8); draw_set_color(c_black);
        draw_rectangle(confirm_panel_x1, confirm_panel_y1, confirm_panel_x1 + confirm_panel_width, confirm_panel_y1 + confirm_panel_height, false);
        draw_set_alpha(1.0); draw_set_color(c_white);
    }

    var content_confirm_x = confirm_panel_x1 + padding;
    var content_confirm_y = confirm_panel_y1 + padding;

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(content_confirm_x + confirm_content_w / 2, content_confirm_y + title_line_h / 2, question_text);

    var options_y_center = content_confirm_y + title_line_h + padding + line_h / 2;
    var yes_color = (shop_confirm_choice == 0) ? c_yellow : c_white;
    var no_color = (shop_confirm_choice == 1) ? c_yellow : c_white;
    
    var yes_text_w = string_width("YES");
    // var no_text_w = string_width("NO"); // Not strictly needed for this positioning method

    var yes_x_center = content_confirm_x + (confirm_content_w * 0.33);
    var no_x_center = content_confirm_x + (confirm_content_w * 0.66);

    draw_set_color(yes_color);
    draw_text(yes_x_center, options_y_center, "YES"); 
    
    draw_set_color(no_color);
    draw_text(no_x_center, options_y_center, "NO"); 
    
    draw_set_halign(fa_left); 
    draw_set_valign(fa_top);  
}

// --- Reset General Drawing State At End ---
draw_set_font(-1); 
draw_set_alpha(1.0);
draw_set_color(c_white);
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
var _text_height_example = string_height("Mg"); 
var line_h = ceil(_text_height_example + 8);   
var title_line_h = ceil(_text_height_example + 12); 

// Common styling setup
var padding = 16;           
var box_margin = 32;    
var max_visible_items = 8;
var initial_main_box_x = 64; 
var items_in_stock = shop_stock; // This should be instance variable shop_stock, not a local redeclaration
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
    var shop_title_text = "Shop - For Sale"; // Title can reflect it's only for buying
    
    // --- Calculate dynamic box_w based on content ---
    var calculated_content_width = 0;
    var min_content_width = 300; // Adjusted minimum width slightly if needed

    if (item_stock_count > 0) {
        for (var i = 0; i < item_stock_count; i++) {
            var item_key = items_in_stock[i]; // Use the instance variable items_in_stock
            var item_data = scr_GetItemData(item_key);
            var item_name = item_data.name ?? item_key;
            var buy_price = ceil((item_data.value ?? 0) * buyMultiplier);
            // var sell_price = ceil((item_data.value ?? 0) * sellMultiplier); // REMOVED sell_price calculation
            
            // MODIFIED: Only show buy price
            var price_text = "Buy: " + string(buy_price) + "g"; 
            // var prices_text = "B:" + string(buy_price) + "  S:" + string(sell_price); // OLD line
            
            // Width needed: Name + a gap (padding) + Price text
            var current_line_width = string_width(item_name) + padding + string_width(price_text);
            calculated_content_width = max(calculated_content_width, current_line_width);
        }
    } else { // If no items in stock
        calculated_content_width = max(string_width("No items in stock."), min_content_width);
    }
    var box_w = max(calculated_content_width, min_content_width);

    // Determine position and height of the main shop box
    var visible_item_count = min(item_stock_count, max_visible_items);
    // If no items, still allocate height for one line for the "No items" message
    var list_content_h = (item_stock_count == 0) ? line_h : (visible_item_count * line_h);
    var current_box_content_h = title_line_h + list_content_h; 
    
    var panel_total_width = box_w + padding * 2; 
    var main_box_x = initial_main_box_x;
    if (main_box_x + panel_total_width > gui_w - box_margin) {
        main_box_x = (gui_w - panel_total_width) / 2;
        if (main_box_x < box_margin) main_box_x = box_margin;
    }
    var current_box_y = (gui_h - (current_box_content_h + padding * 2)) / 2; 

    var panel_x1 = main_box_x - padding;
    var panel_y1 = current_box_y - padding;
    var panel_x2 = main_box_x + box_w + padding;
    var panel_y2 = current_box_y + current_box_content_h + padding * 2; 

    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, panel_x1, panel_y1, panel_x2 - panel_x1, panel_y2 - panel_y1);
    } else { 
        draw_set_alpha(0.8); draw_set_color(c_black);
        draw_rectangle(panel_x1, panel_y1, panel_x2, panel_y2, false);
        draw_set_alpha(1.0); draw_set_color(c_white);
    }

    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(main_box_x + box_w / 2, current_box_y + title_line_h / 2, shop_title_text);
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top); // Changed to fa_top for consistency with item text y-positioning

    var list_items_content_start_y = current_box_y + title_line_h;
    
    if (item_stock_count > 0) {
        for (var i = 0; i < visible_item_count; i++) {
            var item_key = items_in_stock[i]; // Use the instance variable items_in_stock 
            var item_data = scr_GetItemData(item_key);
            var item_name = item_data.name ?? item_key; 
            var buy_price = ceil((item_data.value ?? 0) * buyMultiplier);
            // var sell_price = ceil((item_data.value ?? 0) * sellMultiplier); // REMOVED
            var current_item_draw_y = list_items_content_start_y + i * line_h;
            
            // MODIFIED: Only show buy price
            var price_text = "Buy: " + string(buy_price) + "g";
            // var prices_text = "B:" + string(buy_price) + "  S:" + string(sell_price); // OLD line

            if (i == shop_index) { 
                draw_set_alpha(0.4); draw_set_color(c_yellow);
                draw_rectangle(main_box_x, current_item_draw_y - 2, main_box_x + box_w, current_item_draw_y + line_h - 2, false);
                draw_set_alpha(1.0); 
                draw_set_color(c_yellow);
            } else {
                draw_set_color(c_white);
            }

            // Item Name (valign is fa_top, so y is top of text)
            // To vertically center in line_h, you'd use current_item_draw_y + line_h/2 and valign fa_middle
            // For now, keeping it simple with valign fa_top for the block
            draw_text(main_box_x, current_item_draw_y + (line_h - _text_height_example)/2, item_name); // Slightly adjust Y for better centering if line_h > text_height

            // Buy price (right aligned)
            draw_set_halign(fa_right);
            draw_text(main_box_x + box_w, current_item_draw_y + (line_h - _text_height_example)/2, price_text); // Slightly adjust Y
            draw_set_halign(fa_left); 
        }
    } else {
        // Display "No items in stock" message if stock is empty
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(main_box_x + box_w / 2, list_items_content_start_y + list_content_h / 2, "No items in stock.");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
    draw_set_color(c_white); 

    // --- Player Gold Display --- 
    var gold_text = "Gold: " + string(global.party_currency);
    var gold_text_w = string_width(gold_text);
    var gold_box_content_h = line_h; // Use line_h for consistency
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
    // This state is entirely about buying, so it remains largely unchanged.
    // The price calculation already uses buyMultiplier.
    var confirm_item_key = shop_stock[shop_index]; 
    var confirm_item_data = scr_GetItemData(confirm_item_key);
    var confirm_item_name = confirm_item_data.name ?? confirm_item_key;
    
    var confirm_price = ceil((confirm_item_data.value ?? 0) * buyMultiplier); 

    var question_text = "Buy " + confirm_item_name + " for " + string(confirm_price) + "g?";
    
    var confirm_content_w = string_width(question_text);
    var yes_no_text_width = string_width("YES") + padding + string_width("NO");
    confirm_content_w = max(confirm_content_w, yes_no_text_width);
    confirm_content_w = max(confirm_content_w, 300); 

    var confirm_content_h = title_line_h + line_h + padding; 
    
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
    
    var yes_x_center = content_confirm_x + (confirm_content_w * 0.33); // Position YES option
    var no_x_center = content_confirm_x + (confirm_content_w * 0.66);  // Position NO option

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
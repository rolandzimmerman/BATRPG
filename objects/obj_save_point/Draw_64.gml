/// @description Draw black overlay and horizontal Yes/No prompt

var ww = display_get_gui_width();
var hh = display_get_gui_height();

// --- Set Font Early for Metrics ---
// Assuming Font1 is a valid font asset in your game
if (font_exists(Font1)) { 
    draw_set_font(Font1);
} else {
    show_debug_message_once("Warning: Font1 not found in obj_save_point Draw GUI. Using default font.");
    draw_set_font(-1); // Fallback to default font
}

// --- Black overlay whenever not idle ---
if (state != "idle") {
    draw_set_color(c_black);
    draw_set_alpha(fade_alpha); // fade_alpha is managed in the Step Event
    draw_rectangle(0, 0, ww, hh, false);
    draw_set_alpha(1.0); // Reset alpha for subsequent drawing
}

// --- Draw menu prompt when in "menu" state ---
if (state == "menu") {
    // Font is already set from above
    draw_set_color(c_white);
    draw_set_valign(fa_top); // Set valign for consistent y positioning of text

    var _text_height = string_height("Yes"); // Get height of typical option text with current font
    var _vertical_gap = ceil(_text_height * 0.75); // Gap between prompt and options

    // --- Prompt "Save Game?" ---
    var prompt_str = "Save Game?";
    var prompt_w = string_width(prompt_str);
    var prompt_x = (ww - prompt_w) / 2; // Center the prompt text
    var prompt_y = (hh / 2) - _text_height - _vertical_gap - (_text_height / 2); // Position group centered

    draw_set_halign(fa_left); // Draw from top-left for consistency with highlight calculation
    draw_text(prompt_x, prompt_y, prompt_str);

    // --- Yes / No options (horizontally centered as a group) ---
    var options_y = prompt_y + _text_height + _vertical_gap; // Y position for "Yes" and "No"

    var yes_str = "Yes";
    var no_str = "No";
    var yes_w = string_width(yes_str);
    var no_w = string_width(no_str);
    var gap_between_options = max(40, floor(_text_height * 1.5)); // Ensure a good visual gap

    var total_options_width = yes_w + gap_between_options + no_w;
    var options_block_start_x = (ww - total_options_width) / 2; // Starting X for the "Yes [gap] No" block

    var yes_x_draw = options_block_start_x;
    var no_x_draw = options_block_start_x + yes_w + gap_between_options;

    // Draw "Yes"
    draw_set_color((menu_choice == 0) ? c_yellow : c_white);
    draw_text(yes_x_draw, options_y, yes_str);

    // Draw "No"
    draw_set_color((menu_choice == 1) ? c_yellow : c_white);
    draw_text(no_x_draw, options_y, no_str);
    
    // --- Highlight current choice (alternative style: just change color, already done above) ---
    // If you want a separate highlight box:
    /*
    var selected_text_for_highlight = (menu_choice == 0 ? yes_str : no_str);
    var selected_x_for_highlight_text = (menu_choice == 0 ? yes_x_draw : no_x_draw);
    
    var highlight_padding = 4; // Padding around the text for the highlight box
    var hl_x1 = selected_x_for_highlight_text - highlight_padding;
    var hl_y1 = options_y - highlight_padding;
    var hl_width = string_width(selected_text_for_highlight) + (highlight_padding * 2);
    var hl_height = _text_height + (highlight_padding * 2);

    draw_set_color(c_yellow); // Highlight color
    draw_set_alpha(0.3);      // Make highlight slightly transparent
    draw_rectangle(hl_x1, hl_y1, hl_x1 + hl_width, hl_y1 + hl_height, false); // Filled rectangle
    draw_set_alpha(1.0);      // Reset alpha for other drawing
    */
}

// --- Reset draw state at the very end ---
draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_font(-1); // Reset to default font
draw_set_halign(fa_left);
draw_set_valign(fa_top);
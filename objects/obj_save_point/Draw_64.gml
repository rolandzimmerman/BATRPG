/// obj_save_point :: Draw GUI Event
/// Draw black overlay and horizontal Yes/No prompt

var ww = display_get_gui_width();
var hh = display_get_gui_height();

// --- Set Font Early for Metrics ---
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1); // Fallback to default font
}

// --- Black overlay whenever not idle ---
// This part seems fine and independent of font size for its own drawing,
// but its visibility is controlled by 'state'.
if (state != "idle") {
    draw_set_color(c_black);
    draw_set_alpha(fade_alpha); // Assuming fade_alpha is managed elsewhere
    draw_rectangle(0, 0, ww, hh, false);
    draw_set_alpha(1.0); // Reset alpha for subsequent drawing
}

// --- Draw menu prompt when in "menu" state ---
if (state == "menu") {
    // Font is already set from above
    draw_set_color(c_white);
    draw_set_valign(fa_top); // Set valign for consistent y positioning of text

    var _text_height = string_height("Yes"); // Get height of typical option text with current font
    var _vertical_gap = ceil(_text_height * 0.75); // Gap between prompt and options, tune as needed

    // --- Prompt "Save Game?" ---
    var prompt_str = "Save Game?";
    var prompt_w = string_width(prompt_str);
    var prompt_x = ww / 2 - prompt_w / 2; // Center the prompt text
    // Position prompt so the Yes/No options below it are roughly centered vertically
    var prompt_y = hh / 2 - _text_height - _vertical_gap; // Adjust '-20' based on desired spacing

    draw_set_halign(fa_left); // Draw from top-left for consistency with highlight calculation
    draw_text(prompt_x, prompt_y, prompt_str);

    // --- Yes / No options (horizontally centered as a group) ---
    var options_y = prompt_y + _text_height + _vertical_gap; // Y position for "Yes" and "No"

    var yes_str = "Yes";
    var no_str = "No";
    var yes_w = string_width(yes_str);
    var no_w = string_width(no_str);
    var gap_between_options = max(40, _text_height * 1.5); // Ensure a good visual gap, e.g., 40px or 1.5x text height

    var total_options_width = yes_w + gap_between_options + no_w;
    var options_block_start_x = ww / 2 - total_options_width / 2; // Starting X for the "Yes [gap] No" block

    var yes_x_draw = options_block_start_x;
    var no_x_draw = options_block_start_x + yes_w + gap_between_options;

    // Draw "Yes"
    if (menu_choice == 0) draw_set_color(c_yellow); else draw_set_color(c_white);
    draw_text(yes_x_draw, options_y, yes_str);

    // Draw "No"
    if (menu_choice == 1) draw_set_color(c_yellow); else draw_set_color(c_white);
    draw_text(no_x_draw, options_y, no_str);

    // --- Highlight current choice ---
    // The highlight logic from your original code looked good and adaptive.
    var selected_text_for_highlight = (menu_choice == 0 ? yes_str : no_str);
    var selected_x_for_highlight_text = (menu_choice == 0 ? yes_x_draw : no_x_draw);
    
    var highlight_padding = 4; // Padding around the text for the highlight box
    var hl_x1 = selected_x_for_highlight_text - highlight_padding;
    var hl_y1 = options_y - highlight_padding;
    var hl_width = string_width(selected_text_for_highlight) + (highlight_padding * 2);
    var hl_height = _text_height + (highlight_padding * 2); // Use measured _text_height

    draw_set_color(c_yellow); // Highlight color
    draw_set_alpha(0.4);      // Make highlight slightly transparent
    draw_rectangle(hl_x1, hl_y1, hl_x1 + hl_width, hl_y1 + hl_height, false); // Filled rectangle
    draw_set_alpha(1.0);      // Reset alpha for other drawing
}

// --- Reset draw state at the very end ---
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_font(-1); // Reset to default font
draw_set_halign(fa_left);
draw_set_valign(fa_top);
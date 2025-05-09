/// obj_party_menu :: Draw GUI Event
if (!active) return;

// Ensure necessary global variables exist for drawing party list
if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
    // Optionally draw an error message or simply don't draw the list part
    show_debug_message("obj_party_menu: global.party_members not found or not an array.");
    // If you still want to draw the box and title, you can, or just exit.
    // For now, let's assume we can at least draw a title.
    // return; // Or handle gracefully
}


// --- GUI dimensions ---
var guiWidth = display_get_gui_width();
var guiHeight = display_get_gui_height();

// --- Font and Dynamic Layout Setup ---
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1); // Fallback to default font
}
var _text_height_example = string_height("Hg"); // Get typical height of text with current font
var lineHeight = ceil(_text_height_example + 10); // Add 10px padding. Adjust as needed.
var pad = 20; // Increased padding for larger font. Tune as needed.

// --- Calculate Dynamic Box Width ---
var title_text = "Arrange Party";
var max_content_width = string_width(title_text); // Start with title width

var party_list_keys = global.party_members ?? []; // Use empty array if global.party_members is undefined
var slotCount = array_length(party_list_keys);

for (var i = 0; i < slotCount; i++) {
    var memberKey = party_list_keys[i];
    var displayName = memberKey; // Fallback
    if (variable_global_exists("party_current_stats") &&
        ds_exists(global.party_current_stats, ds_type_map) &&
        ds_map_exists(global.party_current_stats, memberKey)) {
        var stats = ds_map_find_value(global.party_current_stats, memberKey);
        if (is_struct(stats) && variable_struct_exists(stats, "name")) {
            displayName = stats.name;
        }
    }
    var longest_prefix = "> [1st] "; // Consider the widest possible prefix for width calculation
    max_content_width = max(max_content_width, string_width(longest_prefix + displayName));
}

var boxWidth = max_content_width + pad * 2; // Content width + left/right internal padding
var min_menu_box_width = 300; // A sensible minimum width for the menu with Font 24
boxWidth = max(boxWidth, min_menu_box_width);

// --- Compute box height & position ---
var box_title_height = lineHeight; // Title takes one line_height
var box_items_height = slotCount * lineHeight;
var boxHeight = box_title_height + box_items_height + pad * 3; // Title + Items + TopPad + BetweenTitleItemsPad + BottomPad
var boxX = (guiWidth - boxWidth) / 2;
var boxY = (guiHeight - boxHeight) / 2;

// --- Common Draw Settings ---
draw_set_color(c_white);
draw_set_alpha(1.0);

// --- Dim background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, guiWidth, guiHeight, false);
draw_set_alpha(1.0); // Reset alpha for menu elements

// --- Draw the dialog box ---
if (sprite_exists(spr_box1)) {
    // Assuming spr_box1 is a 9-slice or stretchable sprite
    draw_sprite_stretched(spr_box1, 0, boxX, boxY, boxWidth, boxHeight);
} else { // Fallback drawing if sprite is missing
    draw_set_color(make_color_rgb(30,30,30)); // Darker fallback box
    draw_set_alpha(0.85);
    draw_rectangle(boxX, boxY, boxX + boxWidth, boxY + boxHeight, false);
    draw_set_alpha(1.0);
}
draw_set_color(c_white); // Reset color for text

// --- Title ---
draw_set_halign(fa_center);
draw_set_valign(fa_middle); // Vertically center title in its allocated space
draw_text(boxX + boxWidth / 2, boxY + pad + box_title_height / 2, title_text);

// --- List each party slot ---
draw_set_halign(fa_left);
draw_set_valign(fa_top); // Draw text from its top-left for predictable line spacing

var list_start_y = boxY + pad + box_title_height + pad; // Y where the first list item starts

for (var i = 0; i < slotCount; i++) {
    // Y position for this line
    var lineY = list_start_y + i * lineHeight;

    // The party member key & display name
    var memberKey = party_list_keys[i];
    var displayName = memberKey; // Default to key if name not found
    if (variable_global_exists("party_current_stats") &&
        ds_exists(global.party_current_stats, ds_type_map) &&
        ds_map_exists(global.party_current_stats, memberKey)) {
        var stats = ds_map_find_value(global.party_current_stats, memberKey);
        if (is_struct(stats) && variable_struct_exists(stats, "name")) {
            displayName = stats.name;
        }
    }

    // Determine prefix and color based on menu state and selection
    var prefix = "";
    var textColor = c_white;

    // Highlight the cursor (current selection in the list)
    // Assuming 'member_index' is the variable tracking the cursor in this menu
    if (i == member_index) {
        prefix = "> ";
        textColor = c_yellow;
    }

    // If we're choosing the second slot for a swap, mark the first choice
    // Assuming 'menu_state' and 'selected_index' are instance variables for this object
    if (variable_instance_exists(id, "menu_state") && menu_state == "choose_second" &&
        variable_instance_exists(id, "selected_index") && i == selected_index) {
        
        if (i == member_index) { // If current cursor is also the first selection
            prefix = "> [1st] "; // Combine markers
            textColor = c_yellow; // Keep highlight color
        } else {
            prefix = "[1st] ";
            textColor = c_aqua; // Different color for the already selected first member
        }
    }

    // Draw the line
    draw_set_color(textColor);
    draw_text(boxX + pad, lineY, prefix + displayName);
}

// --- Reset drawing state ---
draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_font(-1); // Reset to default font
draw_set_halign(fa_left);
draw_set_valign(fa_top);
/// obj_battle_menu :: Draw GUI
/// Draws battle UI elements. Reads data from obj_battle_player.data and turn order from obj_battle_manager. Uses global string states.

// --- Basic Checks ---
if (!visible || image_alpha <= 0) exit;
if (!instance_exists(obj_battle_manager)) {
    // show_debug_message("DEBUG_GUI: obj_battle_manager does not exist. Exiting Draw GUI.");
    exit;
}
if (!variable_global_exists("battle_state")) {
    // show_debug_message("DEBUG_GUI: global.battle_state does not exist. Exiting Draw GUI.");
    exit;
}
var _current_battle_state = global.battle_state;
// show_debug_message("DEBUG_GUI: Frame Start. Current battle state: " + _current_battle_state);

// --- Active Player Data Validation ---
var active_player_data_valid = false;
var active_p_inst = noone;
var active_p_data = noone; // This will store the 'data' struct of the active player
var active_idx = -1;

if (variable_global_exists("active_party_member_index") &&
    variable_global_exists("battle_party") &&
    ds_exists(global.battle_party, ds_type_list)) {
    active_idx = global.active_party_member_index;
    var party_size_validation = ds_list_size(global.battle_party);

    if (active_idx >= 0 && active_idx < party_size_validation) {
        active_p_inst = global.battle_party[| active_idx];
        if (instance_exists(active_p_inst) &&
            variable_instance_exists(active_p_inst, "data") &&
            is_struct(active_p_inst.data)) {
            active_p_data = active_p_inst.data; // Assign to active_p_data
            // Check for essential fields for the menu to function
            if (variable_struct_exists(active_p_data, "hp") &&
                variable_struct_exists(active_p_data, "mp") &&
                variable_struct_exists(active_p_data, "name") &&
                // For skills, we need 'skills' array (even if empty) and 'skill_index'
                variable_struct_exists(active_p_data, "skills") && is_array(active_p_data.skills) &&
                variable_struct_exists(active_p_data, "skill_index") &&
                // For items, we need 'item_index' (items themselves are global)
                variable_struct_exists(active_p_data, "item_index")) {
                active_player_data_valid = true;
            } else {
                 // show_debug_message("DEBUG_GUI: Active player data missing one or more essential fields (hp, mp, name, skills array, skill_index, item_index). active_p_data: " + string(active_p_data));
            }
        } else {
            // show_debug_message("DEBUG_GUI: Active player instance (" + string(active_p_inst) + ") invalid or has no data struct.");
        }
    } else {
        // show_debug_message("DEBUG_GUI: active_idx (" + string(active_idx) + ") out of party bounds (" + string(party_size_validation) + ").");
    }
} else {
    // show_debug_message("DEBUG_GUI: Required global variables for active player not found (active_party_member_index, battle_party).");
}

// if (!active_player_data_valid && (_current_battle_state == "player_input" || _current_battle_state == "skill_select" || _current_battle_state == "item_select")) {
//    show_debug_message("DEBUG_GUI: Active player data is NOT valid for state: " + _current_battle_state + ". Menus might not draw.");
// }


// === Set Font ===
var current_gui_font = Font1; // Assuming Font1 is your primary UI font
if (!font_exists(current_gui_font)) {
    // show_debug_message("DEBUG_GUI: Font1 not found. Using default font.");
    current_gui_font = -1; // Fallback to default system font
}
draw_set_font(current_gui_font);
var five_char_width = string_width("MMMMM"); // Using "M" for a wider gap, for spacing calculations

// === Constants ===
var party_hud_y = 48;
var initial_hud_x_pos = 64;
var party_hud_positions_x = array_create(4);
party_hud_positions_x[0] = initial_hud_x_pos;
for (var i = 1; i < array_length(party_hud_positions_x); i++) {
    party_hud_positions_x[i] = party_hud_positions_x[i-1] + (320 + 32); // Original spacing logic
}

var menu_x_offset = 48;
var menu_y_offset = 632;
// var menu_cx = 160; // Not used in provided item/skill list code
// var menu_cy = 600; // Not used
// var menu_r = 80;   // Not used
var button_scale = .9;
var list_x_base = (160 + menu_x_offset) + 80 + 80; // (menu_cx + menu_x_offset) + menu_r + 80; -> 160+48+80+80 = 368
var list_y = menu_y_offset; // Base Y for lists

var const_font_size = string_height("M") + 2; // Dynamically get font size, +2 for a bit of breathing room
var general_list_padding = 8;
var list_line_h = const_font_size + (general_list_padding); // Adjusted: padding is for box, line height is font + small gap

var list_qty_w = string_width("x00"); // For item quantities
var list_select_color = c_yellow;
var target_cursor_sprite = spr_target_cursor;
var target_cursor_y_offset= -20;
var turn_order_x = display_get_gui_width() - 250;
var turn_order_y = 10;
var turn_order_spacing = 40; // For turn order display

// === Set Default Color and Alignments ===
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// === Draw Party HP/MP/Overdrive HUDs ===
if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    var party_size = ds_list_size(global.battle_party);
    var _spr_hud_bg_asset = spr_pc_hud_bg; // Store asset index
    var _spr_hp_asset = spr_pc_hud_hp;
    var _spr_mp_asset = spr_pc_hud_mp;
    var _spr_od_asset = spr_pc_hud_od;

    // Check sprite existence once
    var _hud_bg_exists = sprite_exists(_spr_hud_bg_asset);
    var _hp_bar_exists = sprite_exists(_spr_hp_asset);
    var _mp_bar_exists = sprite_exists(_spr_mp_asset);
    var _od_bar_exists = sprite_exists(_spr_od_asset);

    var _spr_hp_w = _hp_bar_exists ? sprite_get_width(_spr_hp_asset) : 100; // Fallback width
    var _spr_hp_h = _hp_bar_exists ? sprite_get_height(_spr_hp_asset) : 10; // Fallback height
    var _spr_mp_w = _mp_bar_exists ? sprite_get_width(_spr_mp_asset) : 100;
    var _spr_mp_h = _mp_bar_exists ? sprite_get_height(_spr_mp_asset) : 10;
    var _spr_od_w = _od_bar_exists ? sprite_get_width(_spr_od_asset) : 100;
    var _spr_od_h = _od_bar_exists ? sprite_get_height(_spr_od_asset) : 10;
    
    var mp_text_additional_y_offset = 16; // As in original

    for (var i = 0; i < party_size; i++) {
        if (i >= array_length(party_hud_positions_x)) continue;
        var x0 = party_hud_positions_x[i];
        var y0 = party_hud_y;
        var inst = global.battle_party[| i];

        if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data)) continue;
        var d = inst.data; // Character data struct

        var is_current_active_player = (active_p_inst == inst); // More reliable check
        var current_alpha = is_current_active_player ? 1.0 : 0.7;
        var current_tint = is_current_active_player ? c_white : c_gray;

        if (!variable_struct_exists(d, "hp") || d.hp <= 0) { // Check if HP exists before comparing
            current_alpha *= 0.5;
            current_tint = merge_color(current_tint, c_dkgray, 0.5);
        }

        if (_hud_bg_exists) {
            draw_sprite_ext(_spr_hud_bg_asset, 0, x0, y0, 1, 1, 0, current_tint, current_alpha);
        }

        draw_set_alpha(current_alpha); // Set alpha for text and bars
        draw_set_valign(fa_top);
        draw_text_color(x0 + 10, y0 - 48, d.name ?? "???", current_tint, current_tint, current_tint, current_tint, current_alpha); // Name

        // HP Bar & Text
        if (_hp_bar_exists && variable_struct_exists(d, "hp") && variable_struct_exists(d, "maxhp") && d.maxhp > 0) {
            var r_hp = clamp(d.hp / d.maxhp, 0, 1);
            var w_hp = floor(_spr_hp_w * r_hp);
            if (w_hp > 0) draw_sprite_part_ext(_spr_hp_asset, 0, 0, 0, w_hp, _spr_hp_h, x0 + 32, y0, 1, 1, c_white, current_alpha);
        }
        draw_set_valign(fa_middle);
        draw_text_color(x0 + 180, y0 - 16 + (_spr_hp_h / 2), string(floor(d.hp ?? 0)) + "/" + string(floor(d.maxhp ?? 0)), current_tint, current_tint, current_tint, current_tint, current_alpha);
        draw_set_valign(fa_top);

        // MP Bar & Text
        if (_mp_bar_exists && variable_struct_exists(d, "mp") && variable_struct_exists(d, "maxmp") && d.maxmp > 0) {
            var r_mp = clamp(d.mp / d.maxmp, 0, 1);
            var w_mp = floor(_spr_mp_w * r_mp);
            if (w_mp > 0) draw_sprite_part_ext(_spr_mp_asset, 0, 0, 0, w_mp, _spr_mp_h, x0 + 32, y0, 1, 1, c_white, current_alpha);
        }
        draw_set_valign(fa_middle);
        draw_text_color(x0 + 180, y0 + (_spr_mp_h / 2) + mp_text_additional_y_offset, string(floor(d.mp ?? 0)) + "/" + string(floor(d.maxmp ?? 0)), current_tint, current_tint, current_tint, current_tint, current_alpha);
        draw_set_valign(fa_top);
        
        // Overdrive Bar
        if (_od_bar_exists && variable_struct_exists(d, "overdrive") && variable_struct_exists(d, "overdrive_max") && (d.overdrive_max ?? 0) > 0) {
            var ro = clamp(d.overdrive / d.overdrive_max, 0, 1);
            var xo_od = x0 + 32; var yo_od = y0; // Assuming OD bar aligns with HP/MP bars
            var od_sprite_to_draw = _spr_od_asset; // This should be your actual OD bar sprite
            var num_frames_od = sprite_get_number(od_sprite_to_draw);

            if (ro >= 1.0) { // Full Overdrive - Animate
                 var frame_od = (num_frames_od > 1) ? ((current_time div 100) mod num_frames_od) : 0;
                 draw_sprite_ext(od_sprite_to_draw, frame_od, xo_od, yo_od, 1, 1, 0, c_white, current_alpha);
            } else { // Partial Overdrive - Draw part
                var wo_od = floor(_spr_od_w * ro);
                if (wo_od > 0) draw_sprite_part_ext(od_sprite_to_draw, 0, 0, 0, wo_od, _spr_od_h, xo_od, yo_od, 1, 1, c_white, current_alpha);
            }
        }
        draw_set_alpha(1.0); // Reset alpha for next HUD element
    }
}


// === Main Command / Skill / Item Menus ===
// This entire block will only execute if active_player_data_valid is true
if (active_player_data_valid) { // Removed active_p_inst != noone as active_player_data_valid implies active_p_inst is valid
    show_debug_message("DEBUG_GUI: Drawing Main Menus. State: " + _current_battle_state);
    var menu_box_side_padding = 32; 

    if (_current_battle_state == "player_input") {
        show_debug_message("DEBUG_GUI: Drawing Player Input Commands.");
        var ybutton_draw_x = 96 + menu_x_offset;  var ybutton_draw_y = 0 + menu_y_offset;
        var xbutton_draw_x = 0 + menu_x_offset;   var xbutton_draw_y = 96 + menu_y_offset;
        var bbutton_draw_x = 192 + menu_x_offset; var bbutton_draw_y = 96 + menu_y_offset;
        var abutton_draw_x = 96 + menu_x_offset;  var abutton_draw_y = 192 + menu_y_offset;

        var yb_asset = Ybutton; var xb_asset = Xbutton; var bb_asset = Bbutton; var ab_asset = Abutton; // Cache asset indices

        if (sprite_exists(yb_asset)) draw_sprite_ext(yb_asset,0,ybutton_draw_x,ybutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(xb_asset)) draw_sprite_ext(xb_asset,0,xbutton_draw_x,xbutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(bb_asset)) draw_sprite_ext(bb_asset,0,bbutton_draw_x,bbutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(ab_asset)) draw_sprite_ext(ab_asset,0,abutton_draw_x,abutton_draw_y,button_scale,button_scale,0,c_white,1);
        
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        var default_button_dim = 32; // Fallback dimension

        var ybutton_actual_w = (sprite_exists(yb_asset) ? sprite_get_width(yb_asset) * button_scale : default_button_dim);
        var ybutton_actual_h = (sprite_exists(yb_asset) ? sprite_get_height(yb_asset) * button_scale : default_button_dim);
        draw_text(ybutton_draw_x + ybutton_actual_w / 2, ybutton_draw_y + ybutton_actual_h / 2, "Item");

        var xbutton_actual_w = (sprite_exists(xb_asset) ? sprite_get_width(xb_asset) * button_scale : default_button_dim);
        var xbutton_actual_h = (sprite_exists(xb_asset) ? sprite_get_height(xb_asset) * button_scale : default_button_dim);
        draw_text(xbutton_draw_x + xbutton_actual_w / 2, xbutton_draw_y + xbutton_actual_h / 2, "Spec");

        var bbutton_actual_w = (sprite_exists(bb_asset) ? sprite_get_width(bb_asset) * button_scale : default_button_dim);
        var bbutton_actual_h = (sprite_exists(bb_asset) ? sprite_get_height(bb_asset) * button_scale : default_button_dim);
        draw_text(bbutton_draw_x + bbutton_actual_w / 2, bbutton_draw_y + bbutton_actual_h / 2, "Def");

        var abutton_actual_w = (sprite_exists(ab_asset) ? sprite_get_width(ab_asset) * button_scale : default_button_dim);
        var abutton_actual_h = (sprite_exists(ab_asset) ? sprite_get_height(ab_asset) * button_scale : default_button_dim);
        draw_text(abutton_draw_x + abutton_actual_w / 2, abutton_draw_y + abutton_actual_h / 2, "Att");
        
        draw_set_halign(fa_left); draw_set_valign(fa_top); // Reset
    }
    else if (_current_battle_state == "skill_select") {
        show_debug_message("DEBUG_GUI: Attempting to draw Skill Select menu.");
        var skills_to_display = []; // Default to empty
        var current_selection_index = 0;

        // active_p_inst and active_p_data are already validated by the outer 'if (active_player_data_valid)'
        // We also checked active_p_data.skills is an array and skill_index exists.
        // The 'display_skills' should be prepared by obj_battle_player based on active_p_data.skills
        if (variable_instance_exists(active_p_inst, "display_skills") && is_array(active_p_inst.display_skills)) {
            skills_to_display = active_p_inst.display_skills;
        } else {
            show_debug_message("DEBUG_GUI: active_p_inst.display_skills not found or not an array. Defaulting to empty for drawing.");
            // skills_to_display remains []
        }
        current_selection_index = active_p_data.skill_index; // Already validated that skill_index exists

        var cnt_skills = array_length(skills_to_display);
        show_debug_message("DEBUG_GUI: Number of skills to display: " + string(cnt_skills));
        var sel_skill = (cnt_skills > 0) ? clamp(current_selection_index, 0, max(0, cnt_skills - 1)) : -1;
        
        var content_area_x_start_skill = list_x_base;
        var content_area_y_start_skill = list_y;
        
        var no_skills_message = "No Skills Available";
        var skill_name_column_width = 0;
        var mp_cost_column_width = 0;
        
        if (cnt_skills > 0) {
            for (var j_calc = 0; j_calc < cnt_skills; j_calc++) {
                var skc = skills_to_display[j_calc];
                if (!is_struct(skc)) continue; 
                skill_name_column_width = max(skill_name_column_width, string_width(skc.name ?? "???"));
                mp_cost_column_width = max(mp_cost_column_width, string_width("(MP " + string(skc.cost ?? 0) + ")"));
            }
        } else {
            skill_name_column_width = string_width(no_skills_message);
        }
        
        var internal_content_width;
        if (cnt_skills > 0) {
            internal_content_width = skill_name_column_width + five_char_width + mp_cost_column_width;
        } else {
            internal_content_width = skill_name_column_width;
        }
        
        var box_vertical_padding = general_list_padding; 
        var box_horizontal_padding = menu_box_side_padding;

        var actual_box_width = internal_content_width + (box_horizontal_padding * 2);
        var actual_box_height = (cnt_skills == 0 ? 1 : cnt_skills) * list_line_h + (box_vertical_padding * 2);
        
        var box_draw_x = content_area_x_start_skill - box_horizontal_padding;
        var box_draw_y = content_area_y_start_skill - box_vertical_padding;
        show_debug_message("DEBUG_GUI: Skill box calculated: x=" + string(box_draw_x) + ", y=" + string(box_draw_y) + ", w=" + string(actual_box_width) + ", h=" + string(actual_box_height));

        var box_sprite_asset = spr_box1; // Cache asset index
        if (sprite_exists(box_sprite_asset)) {
            var s_w = sprite_get_width(box_sprite_asset);
            var s_h = sprite_get_height(box_sprite_asset);
            if (s_w > 0 && s_h > 0) { 
                draw_sprite_ext(box_sprite_asset, -1, box_draw_x, box_draw_y, actual_box_width / s_w, actual_box_height / s_h, 0, c_white, 0.9);
            } else { 
                show_debug_message("DEBUG_GUI: spr_box1 has invalid dimensions (0 width or height). Drawing fallback rect.");
                draw_set_color(c_red); draw_rectangle(box_draw_x, box_draw_y, box_draw_x + actual_box_width, box_draw_y + actual_box_height, false); draw_set_color(c_white);
            }
        } else { 
            show_debug_message("DEBUG_GUI: spr_box1 does not exist. Drawing fallback rect.");
            draw_set_color(c_fuchsia); draw_rectangle(box_draw_x, box_draw_y, box_draw_x + actual_box_width, box_draw_y + actual_box_height, false); draw_set_color(c_white);
        }
        
        if (cnt_skills > 0) {
            show_debug_message("DEBUG_GUI: Drawing " + string(cnt_skills) + " skills.");
            draw_set_valign(fa_middle);
            var mp_cost_text_x = content_area_x_start_skill + skill_name_column_width + five_char_width;

            for (var j = 0; j < cnt_skills; j++) {
                var sk = skills_to_display[j];
                if (!is_struct(sk)) continue;
                
                var skill_name = sk.name ?? "???";
                var skill_cost = sk.cost ?? 0;
                var mp_cost_string = "(MP " + string(skill_cost) + ")";
                var current_line_y_centered = content_area_y_start_skill + (j * list_line_h) + (list_line_h / 2);

                if (j == sel_skill) {
                    draw_set_color(list_select_color); draw_set_alpha(0.5);
                    draw_rectangle(box_draw_x, content_area_y_start_skill + j * list_line_h, 
                                   box_draw_x + actual_box_width, content_area_y_start_skill + (j + 1) * list_line_h, false);
                    draw_set_alpha(1.0);
                }
                
                var can_afford_skill = true;
                // active_p_data is confirmed to be a struct here
                if (variable_struct_exists(sk, "overdrive") && sk.overdrive) { // Check for overdrive skill
                    can_afford_skill = (active_p_data.overdrive >= (active_p_data.overdrive_max ?? 100) ); 
                } else { // Regular MP cost skill
                    can_afford_skill = (active_p_data.mp >= skill_cost); 
                }
                draw_set_color(can_afford_skill ? c_white : c_gray);
                
                draw_set_halign(fa_left);
                draw_text(content_area_x_start_skill, current_line_y_centered, skill_name);
                
                draw_set_halign(fa_left); 
                draw_text(mp_cost_text_x, current_line_y_centered, mp_cost_string);
            }
        } else {
            show_debug_message("DEBUG_GUI: Drawing 'No Skills Available'.");
            draw_set_halign(fa_center);   
            draw_set_valign(fa_middle);  
            draw_set_color(c_white);     
            
            var text_draw_x = box_draw_x + actual_box_width / 2; 
            var text_draw_y = content_area_y_start_skill + list_line_h / 2; 
            
            draw_text(text_draw_x, text_draw_y, no_skills_message);
        }
        
        draw_set_halign(fa_left); 
        draw_set_valign(fa_top);
        draw_set_alpha(1.0); 
        draw_set_color(c_white);

    } // End of "skill_select"
    else if (_current_battle_state == "item_select") {
        show_debug_message("DEBUG_GUI: Attempting to draw Item Select menu.");
        // --- Item Select --- (Applying similar structure for "No Items")
        var items_to_display = [];
        if (variable_global_exists("battle_usable_items") && is_array(global.battle_usable_items)) {
            items_to_display = global.battle_usable_items;
        } else {
            show_debug_message("DEBUG_GUI: global.battle_usable_items not found or not an array.");
        }

        var cnt_items = array_length(items_to_display);
        show_debug_message("DEBUG_GUI: Number of items to display: " + string(cnt_items));
        var sel_item_idx = active_p_data.item_index; // Already validated item_index exists
        sel_item_idx = (cnt_items > 0) ? clamp(sel_item_idx, 0, max(0, cnt_items - 1)) : -1;
        
        var content_area_x_start_item = list_x_base;
        var content_area_y_start_item = list_y;
        
        var no_items_message = "No Usable Items";
        var item_name_column_width = 0;
        var quantity_column_width = string_width("x99"); // Pre-calculate typical quantity width
        
        if (cnt_items > 0) {
            for (var k_calc = 0; k_calc < cnt_items; k_calc++) {
                var it_c = items_to_display[k_calc]; if(!is_struct(it_c)) continue;
                item_name_column_width = max(item_name_column_width, string_width(it_c.name ?? "???"));
                quantity_column_width = max(quantity_column_width, string_width("x" + string(it_c.quantity ?? 0)));
            }
        } else {
            item_name_column_width = string_width(no_items_message);
            // quantity_column_width can remain as pre-calculated or set to 0
        }
        
        var internal_content_width_item;
        if (cnt_items > 0) {
            internal_content_width_item = item_name_column_width + five_char_width + quantity_column_width;
        } else {
            internal_content_width_item = item_name_column_width;
        }
        
        var box_vertical_padding_item = general_list_padding;
        var box_horizontal_padding_item = menu_box_side_padding;

        var actual_box_width_item = internal_content_width_item + (box_horizontal_padding_item * 2);
        var actual_box_height_item = (cnt_items == 0 ? 1 : cnt_items) * list_line_h + (box_vertical_padding_item * 2);
        
        var box_draw_x_item = content_area_x_start_item - box_horizontal_padding_item;
        var box_draw_y_item = content_area_y_start_item - box_vertical_padding_item;
        show_debug_message("DEBUG_GUI: Item box calculated: x=" + string(box_draw_x_item) + ", y=" + string(box_draw_y_item) + ", w=" + string(actual_box_width_item) + ", h=" + string(actual_box_height_item));

        var box_sprite_asset_item = spr_box1;
        if (sprite_exists(box_sprite_asset_item)) {
            var sw_i = sprite_get_width(box_sprite_asset_item); var sh_i = sprite_get_height(box_sprite_asset_item);
            if (sw_i > 0 && sh_i > 0) {
                draw_sprite_ext(box_sprite_asset_item,-1,box_draw_x_item,box_draw_y_item,actual_box_width_item/sw_i,actual_box_height_item/sh_i,0,c_white,0.9);
            } else {
                 show_debug_message("DEBUG_GUI: spr_box1 has invalid dimensions for item box. Drawing fallback rect.");
                draw_set_color(c_red); draw_rectangle(box_draw_x_item, box_draw_y_item, box_draw_x_item + actual_box_width_item, box_draw_y_item + actual_box_height_item, false); draw_set_color(c_white);
            }
        } else {
            show_debug_message("DEBUG_GUI: spr_box1 does not exist for item box. Drawing fallback rect.");
            draw_set_color(c_fuchsia); draw_rectangle(box_draw_x_item, box_draw_y_item, box_draw_x_item + actual_box_width_item, box_draw_y_item + actual_box_height_item, false); draw_set_color(c_white);
        }
        
        if (cnt_items > 0) {
            show_debug_message("DEBUG_GUI: Drawing " + string(cnt_items) + " items.");
            draw_set_valign(fa_middle);
            var quantity_text_x_pos = content_area_x_start_item + item_name_column_width + five_char_width;

            for (var k = 0; k < cnt_items; k++) {
                var it = items_to_display[k]; if (!is_struct(it)) continue;
                var nm_it = it.name ?? "???";
                var qt_it = it.quantity ?? 0;
                var qty_str_it = "x" + string(qt_it);
                var current_line_y_centered_item = content_area_y_start_item + (k * list_line_h) + (list_line_h / 2);

                if (k == sel_item_idx) {
                    draw_set_color(list_select_color); draw_set_alpha(0.5);
                    draw_rectangle(box_draw_x_item, content_area_y_start_item + k * list_line_h,
                                   box_draw_x_item + actual_box_width_item, content_area_y_start_item + (k+1) * list_line_h ,false);
                    draw_set_alpha(1.0);
                }
                draw_set_color(c_white); 

                draw_set_halign(fa_left);
                draw_text(content_area_x_start_item, current_line_y_centered_item, nm_it);
                
                draw_set_halign(fa_left); 
                draw_text(quantity_text_x_pos, current_line_y_centered_item, qty_str_it);
            }
        } else {
            show_debug_message("DEBUG_GUI: Drawing 'No Usable Items'.");
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_set_color(c_white);
            var text_draw_x_item = box_draw_x_item + actual_box_width_item / 2;
            var text_draw_y_item = content_area_y_start_item + list_line_h / 2;
            draw_text(text_draw_x_item, text_draw_y_item, no_items_message);
        }
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_alpha(1.0); 
        draw_set_color(c_white);
    } // End of "item_select"

} else if (_current_battle_state == "skill_select" || _current_battle_state == "item_select" || _current_battle_state == "player_input") {
    // This else branch is for when menus *should* draw but active_player_data_valid is false.
    show_debug_message("DEBUG_GUI: In menu state (" + _current_battle_state + ") but active_player_data_valid is FALSE. No menu will be drawn for player commands/skills/items.");
    // You could draw a generic "Waiting for player..." or error message here if desired,
    // but typically if active_player_data is invalid, something is wrong with the battle flow.
}


// --- Draw Target Cursor ---
// Simplified to avoid excessive debug messages if it's working, but keeping structure
if (_current_battle_state == "TargetSelect") {
    if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list) && variable_global_exists("battle_target")) {
        var n_enemies = ds_list_size(global.battle_enemies);
        var current_target_idx = global.battle_target ?? -1;
        if (n_enemies > 0 && current_target_idx >= 0 && current_target_idx < n_enemies) {
            var tid_enemy = global.battle_enemies[| current_target_idx];
            if (instance_exists(tid_enemy)) {
                var tx = tid_enemy.x;
                var ty = tid_enemy.bbox_top; // Use bbox_top for consistency above sprite
                var cursor_y_final = ty + target_cursor_y_offset; // Apply offset
                if (sprite_exists(target_cursor_sprite)) {
                    draw_sprite(target_cursor_sprite, -1, tx, cursor_y_final);
                } else { // Fallback cursor
                    draw_set_halign(fa_center); draw_set_valign(fa_bottom);
                    draw_text_color(tx, cursor_y_final, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1);
                    draw_set_halign(fa_left); draw_set_valign(fa_top);
                }
            }
        }
    }
} else if (_current_battle_state == "TargetSelectAlly") {
    if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list) && variable_global_exists("battle_ally_target")) {
        var n_party = ds_list_size(global.battle_party);
        var ally_target_idx = global.battle_ally_target ?? -1;
        if (n_party > 0 && ally_target_idx >= 0 && ally_target_idx < n_party) {
            if (ally_target_idx < array_length(party_hud_positions_x)) { // Check against HUD positions array length
                var tid_ally = global.battle_party[| ally_target_idx]; // Get ally instance
                if (instance_exists(tid_ally)) { // Check instance exists
                    var hud_x_pos_ally = party_hud_positions_x[ally_target_idx];
                    var hud_bg_sprite_width_val = sprite_exists(spr_pc_hud_bg) ? sprite_get_width(spr_pc_hud_bg) : 200; // Default width
                    var hud_center_x_ally = hud_x_pos_ally + hud_bg_sprite_width_val / 2;
                    var hud_top_y_ally = party_hud_y; // Top Y of the HUD box itself for the target
                    var tx_cursor_ally = hud_center_x_ally;
                    var ty_cursor_ally = hud_top_y_ally + target_cursor_y_offset; // Offset from top of HUD

                    if (sprite_exists(target_cursor_sprite)) {
                        draw_sprite(target_cursor_sprite, -1, tx_cursor_ally, ty_cursor_ally);
                    } else { // Fallback cursor
                        draw_set_halign(fa_center); draw_set_valign(fa_bottom); // Or fa_top if offset is negative enough
                        draw_text_color(tx_cursor_ally, ty_cursor_ally, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1);
                        draw_set_halign(fa_left); draw_set_valign(fa_top);
                    }
                }
            }
        }
    }
}


// === Draw Turn Order Display ===
if (instance_exists(obj_battle_manager) && variable_instance_exists(obj_battle_manager, "turnOrderDisplay") && is_array(obj_battle_manager.turnOrderDisplay)) {
    var _turn_order_list  = obj_battle_manager.turnOrderDisplay;
    var _order_count = array_length(_turn_order_list);
    if (_order_count > 0) { // Only draw if there's something in the turn order
        var turn_order_box_padding = 16;
        var turn_order_box_shift_right = 0; // Adjusted, original had 80, assuming text starts at turn_order_x now
        var max_name_width = 0;
        var current_actor_name_txt;

        for (var i = 0; i < _order_count; i++) {
            var actor_id_in_turn = _turn_order_list[i];
            if (!instance_exists(actor_id_in_turn)) continue;
            if (variable_instance_exists(actor_id_in_turn, "data") && is_struct(actor_id_in_turn.data) && variable_struct_exists(actor_id_in_turn.data, "name")) {
                current_actor_name_txt = actor_id_in_turn.data.name;
            } else {
                current_actor_name_txt = object_get_name(actor_id_in_turn.object_index);
            }
            max_name_width = max(max_name_width, string_width(current_actor_name_txt));
        }

        var box_display_w = max_name_width + turn_order_box_padding * 2;
        // Calculate height based on actual lines to draw, not fixed spacing if some are skipped
        var actual_lines_in_turn_order = 0;
        for (var i = 0; i < _order_count; i++) { if (instance_exists(_turn_order_list[i])) actual_lines_in_turn_order++; }
        var box_display_h = actual_lines_in_turn_order * turn_order_spacing + turn_order_box_padding * 2 - (actual_lines_in_turn_order > 0 ? turn_order_spacing / 2 : 0) ; // More compact list


        var box_display_x = turn_order_x + turn_order_box_shift_right - turn_order_box_padding;
        var box_display_y = turn_order_y - turn_order_box_padding;

        var box_sprite_turn_order = spr_box1;
        if (sprite_exists(box_sprite_turn_order)) {
           var sw_box = sprite_get_width(box_sprite_turn_order); var sh_box = sprite_get_height(box_sprite_turn_order);
           if (sw_box > 0 && sh_box > 0) draw_sprite_ext(box_sprite_turn_order, -1, box_display_x, box_display_y, box_display_w / sw_box, box_display_h / sh_box, 0, c_white, 0.8);
        } else {
            // Fallback for turn order box
            draw_set_alpha(0.8); draw_set_color(c_black);
            draw_rectangle(box_display_x, box_display_y, box_display_x + box_display_w, box_display_y + box_display_h, false);
            draw_set_alpha(1.0); draw_set_color(c_white);
        }
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle);
        var drawn_lines_count = 0;
        for (var i = 0; i < _order_count; i++) {
            var actor_id_current_draw = _turn_order_list[i];
            if (!instance_exists(actor_id_current_draw)) continue;
            
            var draw_text_y_turn_order = turn_order_y + drawn_lines_count * turn_order_spacing + (turn_order_spacing / 2);
            
            if (variable_instance_exists(actor_id_current_draw, "data") && is_struct(actor_id_current_draw.data) && variable_struct_exists(actor_id_current_draw.data, "name")) {
                current_actor_name_txt = actor_id_current_draw.data.name;
            } else {
                current_actor_name_txt = object_get_name(actor_id_current_draw.object_index);
            }
            
            var tint_color_turn_order = c_white; // Default
            var is_player = false;
            for(var p_idx = 0; p_idx < ds_list_size(global.battle_party); p_idx++){
                if(global.battle_party[| p_idx] == actor_id_current_draw){ is_player = true; break;}
            }
            tint_color_turn_order = is_player ? c_lime : c_red;

            if (variable_instance_exists(actor_id_current_draw, "data") && is_struct(actor_id_current_draw.data) && 
                variable_struct_exists(actor_id_current_draw.data, "hp") && actor_id_current_draw.data.hp <= 0) {
                tint_color_turn_order = merge_color(tint_color_turn_order, c_dkgray, 0.6);
            }
            draw_text_color(turn_order_x + turn_order_box_shift_right, draw_text_y_turn_order, current_actor_name_txt, tint_color_turn_order, tint_color_turn_order, tint_color_turn_order, tint_color_turn_order, 1);
            drawn_lines_count++;
        }
    }
}

// === Reset draw state ===
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0);
if (font_exists(Font1) && current_gui_font != -1) { // Only reset if Font1 was used and exists
    // If Font1 is your global default GUI font, you might not need to reset it here,
    // but if it was specific to this script, reset it.
    // draw_set_font(-1); // Or to your actual default game font if not system default
}
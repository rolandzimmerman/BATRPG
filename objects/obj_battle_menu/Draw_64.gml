/// obj_battle_menu :: Draw GUI
/// Draws battle UI elements. Reads data from obj_battle_player.data and turn order from obj_battle_manager. Uses global string states.

// --- Basic Checks ---
if (!visible || image_alpha <= 0) exit;
if (!instance_exists(obj_battle_manager)) exit;
if (!variable_global_exists("battle_state")) exit;
var _current_battle_state = global.battle_state;
// show_debug_message("DEBUG_GUI: Frame Start. Current battle state: " + _current_battle_state);

// --- Active Player Data Validation ---
var active_player_data_valid = false;
var active_p_inst = noone;
var active_p_data = noone;
var active_idx = -1;

if (variable_global_exists("active_party_member_index")
 && variable_global_exists("battle_party")
 && ds_exists(global.battle_party, ds_type_list)) {
    active_idx = global.active_party_member_index;
    var party_size_validation = ds_list_size(global.battle_party);
    if (active_idx >= 0 && active_idx < party_size_validation) {
        active_p_inst = global.battle_party[| active_idx];
        if (instance_exists(active_p_inst)
         && variable_instance_exists(active_p_inst, "data")
         && is_struct(active_p_inst.data)) {
            active_p_data = active_p_inst.data;
            if (variable_struct_exists(active_p_data, "hp")
             && variable_struct_exists(active_p_data, "mp")
             && variable_struct_exists(active_p_data, "name")
             && variable_struct_exists(active_p_data, "skills")
             && variable_struct_exists(active_p_data, "skill_index")
             && variable_struct_exists(active_p_data, "item_index")
            ) {
                active_player_data_valid = true;
            }
        }
    }
}

// === Set Font ===
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1);
}
var five_char_width = string_width("MMMMM"); // Using "M" for a wider gap

// === Constants ===
var party_hud_y = 48;
var initial_hud_x_pos = 64;
// ... (other existing constants like original_hud_spacing_step etc. remain the same) ...
var party_hud_positions_x = array_create(4); // Assuming this is populated as before
party_hud_positions_x[0] = initial_hud_x_pos;
for (var i = 1; i < array_length(party_hud_positions_x); i++) { party_hud_positions_x[i] = party_hud_positions_x[i-1] + (320 + 32); } // Simplified original logic


var menu_x_offset = 48;
var menu_y_offset = 632;
var menu_cx = 160;
var menu_cy = 600;
var menu_r = 80;
var button_scale = .8;
var list_x_base = (menu_cx + menu_x_offset) + menu_r + 80;
var list_y = menu_y_offset;

var const_font_size = 24;
var general_list_padding = 8; // General internal padding, used for vertical in line_h
var list_line_h = const_font_size + (general_list_padding * 2); // e.g. 24 + 16 = 40

var list_qty_w = string_width("x00");
var list_select_color = c_yellow;
var target_cursor_sprite = spr_target_cursor;
var target_cursor_y_offset= -20;
var turn_order_x = display_get_gui_width() - 250;
var turn_order_y = 10;
var turn_order_spacing = 40;

// === Set Color and Alignments ===
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// === Draw Party HP/MP/Overdrive HUDs ===
if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    // ... (Your existing HUD drawing code - assumed correct and complete) ...
    var party_size = ds_list_size(global.battle_party);
    var _spr_hud_bg = sprite_exists(spr_pc_hud_bg);
    var _spr_hp = sprite_exists(spr_pc_hud_hp);
    var _spr_mp = sprite_exists(spr_pc_hud_mp);
    var _spr_od = sprite_exists(spr_pc_hud_od);
    var _spr_hp_w = _spr_hp ? sprite_get_width(spr_pc_hud_hp) : 0;
    var _spr_hp_h = _spr_hp ? sprite_get_height(spr_pc_hud_hp) : 0;
    var _spr_mp_w = _spr_mp ? sprite_get_width(spr_pc_hud_mp) : 0;
    var _spr_mp_h = _spr_mp ? sprite_get_height(spr_pc_hud_mp) : 0;
    var _spr_od_w = _spr_od ? sprite_get_width(spr_pc_hud_od) : 0;
    var _spr_od_h = _spr_od ? sprite_get_height(spr_pc_hud_od) : 0;
    var mp_text_additional_y_offset = 16;
    for (var i = 0; i < party_size; i++) {
        if (i >= array_length(party_hud_positions_x)) continue;
        var x0 = party_hud_positions_x[i];
        var y0 = party_hud_y;
        var inst = global.battle_party[| i];
        if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data)) continue;
        var d = inst.data;
        var active = (i == active_idx);
        var alpha = active ? 1 : 0.7;
        var tint = active ? c_white : c_gray;
        if (d.hp <= 0) { alpha *= 0.5; tint = merge_color(tint, c_dkgray, 0.5); }
        if (_spr_hud_bg) draw_sprite_ext(spr_pc_hud_bg, 0, x0, y0, 1, 1, 0, tint, alpha);
        draw_set_alpha(alpha); draw_set_valign(fa_top);
        draw_text_color(x0 + 10, y0 - 48, d.name ?? "???", tint, tint, tint, tint, alpha);
        if (_spr_hp && variable_struct_exists(d, "hp") && variable_struct_exists(d, "maxhp")) {
            var r_hp = clamp(d.hp / max(1,d.maxhp), 0, 1);
            var w_hp = floor(_spr_hp_w * r_hp);
            if (w_hp > 0) draw_sprite_part_ext(spr_pc_hud_hp, 0, 0, 0, w_hp, _spr_hp_h, x0 + 32, y0, 1, 1, c_white, alpha);
        }
        draw_set_valign(fa_middle);
        draw_text_color(x0 + 180, y0 - 16 + (_spr_hp_h / 2), string(floor(d.hp)) + "/" + string(floor(d.maxhp)), tint, tint, tint, tint, alpha);
        draw_set_valign(fa_top);
        if (_spr_mp && variable_struct_exists(d, "mp") && variable_struct_exists(d, "maxmp")) {
            var r_mp = clamp(d.mp / max(1,d.maxmp), 0, 1);
            var w_mp = floor(_spr_mp_w * r_mp);
            if (w_mp > 0) draw_sprite_part_ext(spr_pc_hud_mp, 0, 0, 0, w_mp, _spr_mp_h, x0 + 32, y0, 1, 1, c_white, alpha);
        }
        draw_set_valign(fa_middle);
        draw_text_color(x0 + 180, y0 + (_spr_mp_h / 2) + mp_text_additional_y_offset, string(floor(d.mp)) + "/" + string(floor(d.maxmp)), tint, tint, tint, tint, alpha);
        draw_set_valign(fa_top);
        if (_spr_od && variable_struct_exists(d, "overdrive") && variable_struct_exists(d, "overdrive_max")) {
            var ro = clamp(d.overdrive / max(1, d.overdrive_max), 0, 1);
            var xo_od = x0 + 32; var yo_od = y0;
            if (ro < 1) {
                var wo_od = floor(_spr_od_w * ro);
                if (wo_od > 0) draw_sprite_part_ext(spr_pc_hud_od, 0, 0, 0, wo_od, _spr_od_h, xo_od, yo_od, 1, 1, c_white, alpha);
            } else {
                var num_frames_od = sprite_get_number(spr_pc_hud_od);
                var frame_od = (current_time div 100) mod num_frames_od;
                draw_sprite_ext(spr_pc_hud_od, frame_od, xo_od, yo_od, 1, 1, 0, c_white, alpha);
            }
        }
        draw_set_alpha(1);
    }
}

// === Main Command / Skill / Item Menues ===
if (active_player_data_valid && active_p_inst != noone) {
    var menu_box_side_padding = 32; // Increased side padding for skill/item boxes (e.g., 20px)

    if (_current_battle_state == "player_input") {
        // ... (Player Input command drawing - confirmed working) ...
        var ybutton_draw_x = 96 + menu_x_offset;  var ybutton_draw_y = 0 + menu_y_offset;
        // ... (rest of button positions)
        var xbutton_draw_x = 0 + menu_x_offset;   var xbutton_draw_y = 96 + menu_y_offset;
        var bbutton_draw_x = 192 + menu_x_offset; var bbutton_draw_y = 96 + menu_y_offset;
        var abutton_draw_x = 96 + menu_x_offset;  var abutton_draw_y = 192 + menu_y_offset;
        if (sprite_exists(Ybutton)) draw_sprite_ext(Ybutton,0,ybutton_draw_x,ybutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Xbutton)) draw_sprite_ext(Xbutton,0,xbutton_draw_x,xbutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Bbutton)) draw_sprite_ext(Bbutton,0,bbutton_draw_x,bbutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Abutton)) draw_sprite_ext(Abutton,0,abutton_draw_x,abutton_draw_y,button_scale,button_scale,0,c_white,1);
        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        var default_button_dim = 32;
        var ybutton_sprite_actual = Ybutton;
        var ybutton_actual_w = (sprite_exists(ybutton_sprite_actual) ? sprite_get_width(ybutton_sprite_actual) * button_scale : default_button_dim);
        var ybutton_actual_h = (sprite_exists(ybutton_sprite_actual) ? sprite_get_height(ybutton_sprite_actual) * button_scale : default_button_dim);
        var ybutton_center_x = ybutton_draw_x + ybutton_actual_w / 2;
        var ybutton_center_y = ybutton_draw_y + ybutton_actual_h / 2;
        draw_text(ybutton_center_x, ybutton_center_y, "Item");
        var xbutton_sprite_actual = Xbutton;
        var xbutton_actual_w = (sprite_exists(xbutton_sprite_actual) ? sprite_get_width(xbutton_sprite_actual) * button_scale : default_button_dim);
        var xbutton_actual_h = (sprite_exists(xbutton_sprite_actual) ? sprite_get_height(xbutton_sprite_actual) * button_scale : default_button_dim);
        var xbutton_center_x = xbutton_draw_x + xbutton_actual_w / 2;
        var xbutton_center_y = xbutton_draw_y + xbutton_actual_h / 2;
        draw_text(xbutton_center_x, xbutton_center_y, "Spec");
        var bbutton_sprite_actual = Bbutton;
        var bbutton_actual_w = (sprite_exists(bbutton_sprite_actual) ? sprite_get_width(bbutton_sprite_actual) * button_scale : default_button_dim);
        var bbutton_actual_h = (sprite_exists(bbutton_sprite_actual) ? sprite_get_height(bbutton_sprite_actual) * button_scale : default_button_dim);
        var bbutton_center_x = bbutton_draw_x + bbutton_actual_w / 2;
        var bbutton_center_y = bbutton_draw_y + bbutton_actual_h / 2;
        draw_text(bbutton_center_x, bbutton_center_y, "Def");
        var abutton_sprite_actual = Abutton;
        var abutton_actual_w = (sprite_exists(abutton_sprite_actual) ? sprite_get_width(abutton_sprite_actual) * button_scale : default_button_dim);
        var abutton_actual_h = (sprite_exists(abutton_sprite_actual) ? sprite_get_height(abutton_sprite_actual) * button_scale : default_button_dim);
        var abutton_center_x = abutton_draw_x + abutton_actual_w / 2;
        var abutton_center_y = abutton_draw_y + abutton_actual_h / 2;
        draw_text(abutton_center_x, abutton_center_y, "Att");
        draw_set_halign(fa_left); draw_set_valign(fa_top);
    }
    else if (_current_battle_state == "skill_select") {
        var skills_to_display = [];
        var current_selection_index = 0;
        if (active_player_data_valid && instance_exists(active_p_inst)) {
            if (variable_instance_exists(active_p_inst, "display_skills") && is_array(active_p_inst.display_skills)) {
                skills_to_display = active_p_inst.display_skills;
            } else { /* Log warning if needed */ }
            if (variable_struct_exists(active_p_data, "skill_index")) {
                current_selection_index = active_p_data.skill_index;
            }
        }
        var cnt_skills = array_length(skills_to_display);
        var sel_skill = (cnt_skills > 0) ? clamp(current_selection_index, 0, max(0, cnt_skills - 1)) : -1;
        
        var current_list_x_skill = list_x_base;
        var current_list_y_skill = list_y;
        
        var max_skill_name_only_w = 0;
        var max_mp_cost_str_w = 0;
        if (cnt_skills > 0) {
            for (var j_calc = 0; j_calc < cnt_skills; j_calc++) {
                var skc = skills_to_display[j_calc];
                if (!is_struct(skc)) { continue; }
                max_skill_name_only_w = max(max_skill_name_only_w, string_width(skc.name ?? "???"));
                max_mp_cost_str_w = max(max_mp_cost_str_w, string_width("(MP " + string(skc.cost ?? 0) + ")"));
            }
        } else {
            max_skill_name_only_w = string_width("No Skills Available");
        }
        
        var desired_skill_content_width = max_skill_name_only_w + five_char_width + max_mp_cost_str_w;
        var actual_skill_box_w = desired_skill_content_width + (menu_box_side_padding * 2); // Use new side padding
        
        var current_box_list_padding = general_list_padding; // Use general for vertical consistency in line_h
        if (cnt_skills == 0) current_box_list_padding = menu_box_side_padding; // Or use menu_box_side_padding if list is empty for wider "No skills" box
        
        var box_h_skill = (cnt_skills == 0) ? list_line_h + (current_box_list_padding * 2) : cnt_skills * list_line_h + (current_box_list_padding * 2);
        var box_x_skill = current_list_x_skill - menu_box_side_padding; // Use new side padding
        var box_y_skill = current_list_y_skill - current_box_list_padding; // Use current_box_list_padding for Y

        if (sprite_exists(spr_box1)) {
            var sw_sprite = sprite_get_width(spr_box1), sh_sprite = sprite_get_height(spr_box1);
            if (sw_sprite > 0 && sh_sprite > 0) { draw_sprite_ext(spr_box1, -1, box_x_skill, box_y_skill, actual_skill_box_w / sw_sprite, box_h_skill / sh_sprite, 0, c_white, 0.9); }
        }
        
        var right_align_x_skill = box_x_skill + actual_skill_box_w - menu_box_side_padding;

        if (cnt_skills > 0) {
            draw_set_valign(fa_middle);
            for (var j = 0; j < cnt_skills; j++) {
                var sk = skills_to_display[j];
                if (!is_struct(sk)) continue;
                var nm = sk.name ?? "???";
                var cs = sk.cost ?? 0;
                var mp_cost_str = "(MP " + string(cs) + ")";
                var y_center_for_text = current_list_y_skill + (j * list_line_h) + (list_line_h / 2);

                if (j == sel_skill) {
                    draw_set_color(list_select_color); draw_set_alpha(0.5);
                    draw_rectangle(box_x_skill, current_list_y_skill + j * list_line_h,
                                   box_x_skill + actual_skill_box_w, current_list_y_skill + (j + 1) * list_line_h, false);
                    draw_set_alpha(1);
                }
                
                var can_afford = true;
                if (active_player_data_valid && is_struct(active_p_data)) { if (variable_struct_exists(sk, "overdrive") && sk.overdrive) { can_afford = (active_p_data.overdrive >= active_p_data.overdrive_max); } else { can_afford = (active_p_data.mp >= cs); } } else { can_afford = false; }
                draw_set_color(can_afford ? c_white : c_gray);
                
                draw_set_halign(fa_left);
                draw_text(current_list_x_skill, y_center_for_text, nm);
                
                draw_set_halign(fa_right);
                draw_text(right_align_x_skill, y_center_for_text, mp_cost_str);
            }
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        } else {
            draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_text(current_list_x_skill, current_list_y_skill + list_line_h / 2, "No Skills Available");
            draw_set_valign(fa_top);
        }
        draw_set_alpha(1); draw_set_color(c_white);
    }
    else if (_current_battle_state == "item_select") {
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var items = [];
        if (variable_global_exists("battle_usable_items") && is_array(global.battle_usable_items)) {
            items = global.battle_usable_items;
        }

        var cnt_items = array_length(items);
        var sel_item = -1;
        if (active_player_data_valid && is_struct(active_p_data) && variable_struct_exists(active_p_data,"item_index")) {
             sel_item = active_p_data.item_index;
        } else if (cnt_items > 0) { sel_item = 0; }
        sel_item = (cnt_items > 0) ? clamp(sel_item, 0, max(0, cnt_items - 1)) : -1;
        
        var current_list_x_item = list_x_base;
        var current_list_y_item = list_y;
        
        var max_item_name_only_w = 0;
        var max_qty_str_w = 0;
        
        if (cnt_items > 0) {
            for (var j_calc = 0; j_calc < cnt_items; j_calc++) {
                var it_calc = items[j_calc]; if(!is_struct(it_calc)) continue;
                max_item_name_only_w = max(max_item_name_only_w, string_width(it_calc.name ?? "???"));
                max_qty_str_w = max(max_qty_str_w, string_width("x" + string(it_calc.quantity ?? 0)));
            }
        } else {
            max_item_name_only_w = string_width("No Usable Items");
        }
        
        var desired_item_content_width = max_item_name_only_w + five_char_width + max_qty_str_w;
        var actual_item_box_w = desired_item_content_width + (menu_box_side_padding * 2); // Use new side padding
        
        var current_box_list_padding_item = general_list_padding;
        if (cnt_items == 0) current_box_list_padding_item = menu_box_side_padding;

        var box_h_item = (cnt_items == 0) ? list_line_h + (current_box_list_padding_item * 2) : cnt_items * list_line_h + (current_box_list_padding_item * 2);
        var box_x_item = current_list_x_item - menu_box_side_padding; // Use new side padding
        var box_y_item = current_list_y_item - current_box_list_padding_item;
        
        if (sprite_exists(spr_box1)) {
            var sw = sprite_get_width(spr_box1); var sh = sprite_get_height(spr_box1);
            if (sw > 0 && sh > 0) draw_sprite_ext(spr_box1,-1,box_x_item,box_y_item,actual_item_box_w/sw,box_h_item/sh,0,c_white,0.9);
        }
        
        var right_align_x_item = box_x_item + actual_item_box_w - menu_box_side_padding;

        if (cnt_items > 0) {
            draw_set_valign(fa_middle);
            for (var j = 0; j < cnt_items; j++) {
                var it = items[j]; if (!is_struct(it)) continue;
                var nm = it.name ?? "???";
                var qt = it.quantity ?? 0;
                var qty_str = "x" + string(qt);
                var y_center_for_text = current_list_y_item + (j * list_line_h) + (list_line_h / 2);

                if (j == sel_item) {
                    draw_set_color(list_select_color); draw_set_alpha(0.5);
                    draw_rectangle(box_x_item, current_list_y_item + j * list_line_h,
                                   box_x_item + actual_item_box_w, current_list_y_item + (j+1) * list_line_h ,false);
                    draw_set_alpha(1);
                }
                draw_set_color(c_white);

                draw_set_halign(fa_left);
                draw_text(current_list_x_item, y_center_for_text, nm);
                
                draw_set_halign(fa_right);
                draw_text(right_align_x_item, y_center_for_text, qty_str);
            }
            draw_set_halign(fa_left);
            draw_set_valign(fa_top);
        } else {
            draw_set_valign(fa_middle);
            draw_set_color(c_white);
            draw_text(current_list_x_item, current_list_y_item + list_line_h / 2, "No Usable Items");
            draw_set_valign(fa_top);
        }
        draw_set_alpha(1); draw_set_color(c_white);
    }
}

// --- Draw Target Cursor ---
// Ensure this section is complete and correct
show_debug_message("DEBUG_GUI_CURSOR: Checking conditions. State: " + _current_battle_state);
if (_current_battle_state == "TargetSelect") {
    show_debug_message("DEBUG_GUI_CURSOR: In TargetSelect branch.");
    if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list) && variable_global_exists("battle_target")) {
        var n_enemies = ds_list_size(global.battle_enemies);
        var current_target_idx = global.battle_target ?? -1;
        show_debug_message("DEBUG_GUI_CURSOR: n_enemies=" + string(n_enemies) + ", current_target_idx=" + string(current_target_idx));
        if (n_enemies > 0 && current_target_idx >= 0 && current_target_idx < n_enemies) {
            var tid_enemy = global.battle_enemies[| current_target_idx];
            if (instance_exists(tid_enemy)) {
                var tx = tid_enemy.x, ty = tid_enemy.bbox_top, off = 10;
                show_debug_message("DEBUG_GUI_CURSOR: Drawing ENEMY target cursor at x=" + string(tx) + ", y_adj=" + string(ty - off));
                if (sprite_exists(target_cursor_sprite)) {
                    draw_sprite(target_cursor_sprite, -1, tx, ty - off);
                } else {
                    draw_set_halign(fa_center); draw_set_valign(fa_bottom);
                    draw_text_color(tx, ty - off, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1);
                    draw_set_halign(fa_left); draw_set_valign(fa_top);
                }
            } else { show_debug_message("DEBUG_GUI_CURSOR: tid_enemy " + string(tid_enemy) + " does not exist."); }
        } else { show_debug_message("DEBUG_GUI_CURSOR: Enemy target index invalid or no enemies."); }
    } else { show_debug_message("DEBUG_GUI_CURSOR: Globals for enemy targeting not properly set for TargetSelect."); }
}
else if (_current_battle_state == "TargetSelectAlly") {
    show_debug_message("DEBUG_GUI_CURSOR: In TargetSelectAlly branch.");
    if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list) && variable_global_exists("battle_ally_target")) {
        var n_party = ds_list_size(global.battle_party);
        var ally_target_idx = global.battle_ally_target ?? -1;
        show_debug_message("DEBUG_GUI_CURSOR: n_party=" + string(n_party) + ", ally_target_idx=" + string(ally_target_idx));
        if (n_party > 0 && ally_target_idx >= 0 && ally_target_idx < n_party) {
            if (ally_target_idx < array_length(party_hud_positions_x)) {
                var tid_ally = global.battle_party[| ally_target_idx];
                if (instance_exists(tid_ally)) {
                    var hud_x_pos_ally = party_hud_positions_x[ally_target_idx];
                    var hud_bg_sprite_width = sprite_exists(spr_pc_hud_bg) ? sprite_get_width(spr_pc_hud_bg) : 200;
                    var hud_center_x_ally = hud_x_pos_ally + hud_bg_sprite_width / 2;
                    var hud_top_y_ally = party_hud_y;
                    var tx_cursor = hud_center_x_ally;
                    var ty_cursor = hud_top_y_ally + target_cursor_y_offset;
                    show_debug_message("DEBUG_GUI_CURSOR: Drawing ALLY target cursor at x=" + string(tx_cursor) + ", y=" + string(ty_cursor));
                    if (sprite_exists(target_cursor_sprite)) {
                        draw_sprite(target_cursor_sprite, -1, tx_cursor, ty_cursor);
                    } else {
                        draw_set_halign(fa_center); draw_set_valign(fa_bottom);
                        draw_text_color(tx_cursor, ty_cursor, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1);
                        draw_set_halign(fa_left); draw_set_valign(fa_top);
                    }
                } else { show_debug_message("DEBUG_GUI_CURSOR: tid_ally " + string(tid_ally) + " does not exist."); }
            } else { show_debug_message("DEBUG_GUI_CURSOR: ally_target_idx out of bounds for party_hud_positions_x."); }
        } else { show_debug_message("DEBUG_GUI_CURSOR: Invalid ally target index or no party members."); }
    } else { show_debug_message("DEBUG_GUI_CURSOR: Globals for ally targeting not properly set for TargetSelectAlly."); }
}


// === Draw Turn Order Display ===
if (instance_exists(obj_battle_manager) && variable_instance_exists(obj_battle_manager, "turnOrderDisplay") && is_array(obj_battle_manager.turnOrderDisplay)) {
    // ... (Your existing turn order display code - confirmed working) ...
    var _turn_order_list  = obj_battle_manager.turnOrderDisplay;
    var _order_count = array_length(_turn_order_list);
    var turn_order_box_padding = 16;
    var turn_order_box_shift_right = 80;
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
    var box_display_h = _order_count * turn_order_spacing + turn_order_box_padding * 2;
    var box_display_x = turn_order_x + turn_order_box_shift_right - turn_order_box_padding;
    var box_display_y = turn_order_y - turn_order_box_padding;
    if (sprite_exists(spr_box1)) {
       var sw_box = sprite_get_width(spr_box1); var sh_box = sprite_get_height(spr_box1);
       if (sw_box > 0 && sh_box > 0) draw_sprite_ext(spr_box1, -1, box_display_x, box_display_y, box_display_w / sw_box, box_display_h / sh_box, 0, c_white, 0.8);
    }
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    for (var i = 0; i < _order_count; i++) {
        var actor_id_current_draw = _turn_order_list[i];
        if (!instance_exists(actor_id_current_draw)) continue;
        var draw_text_y_turn_order = turn_order_y + i * turn_order_spacing + (turn_order_spacing / 2);
        if (variable_instance_exists(actor_id_current_draw, "data") && is_struct(actor_id_current_draw.data) && variable_struct_exists(actor_id_current_draw.data, "name")) {
            current_actor_name_txt = actor_id_current_draw.data.name;
        } else {
            current_actor_name_txt = object_get_name(actor_id_current_draw.object_index);
        }
        var tint_color_turn_order = (instance_exists(obj_battle_player) && actor_id_current_draw.object_index == obj_battle_player) ? c_lime : c_red;
        if (variable_instance_exists(actor_id_current_draw, "data") && is_struct(actor_id_current_draw.data) && variable_struct_exists(actor_id_current_draw.data, "hp") && actor_id_current_draw.data.hp <= 0) {
            tint_color_turn_order = merge_color(tint_color_turn_order, c_dkgray, 0.6);
        }
        draw_text_color(turn_order_x + turn_order_box_shift_right, draw_text_y_turn_order, current_actor_name_txt, tint_color_turn_order, tint_color_turn_order, tint_color_turn_order, tint_color_turn_order, 1);
    }
}

// === Reset draw state ===
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
/// obj_battle_menu :: Draw GUI
/// Draws battle UI elements. Reads data from obj_battle_player.data and turn order from obj_battle_manager. Uses global string states.

// --- Basic Checks ---
if (!visible || image_alpha <= 0) exit;
// Check if manager exists
if (!instance_exists(obj_battle_manager)) exit;
// Use the global string state
if (!variable_global_exists("battle_state")) exit; // Exit if state var doesn't exist
var _current_battle_state = global.battle_state; // Read the global string state

// --- Active Player Data Validation ---
var active_player_data_valid = false;
var active_p_inst = noone;
var active_p_data = noone;
var active_idx = -1; // Local index for highlighting HUD

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
// If not in a state where a player index is set, active_idx remains -1, active_p_inst is noone.

// === Set Font (Done early to allow constants to use its size) ===
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1);
}

// === Constants ===
var party_hud_y = 48;

var initial_hud_x_pos = 64;
var original_hud_spacing_step = 320; // User's value
var extra_spacing_between_huds = 32;
var new_hud_spacing_step = original_hud_spacing_step + extra_spacing_between_huds;

var party_hud_positions_x = array_create(4);
party_hud_positions_x[0] = initial_hud_x_pos;
for (var i = 1; i < array_length(party_hud_positions_x); i++) {
    party_hud_positions_x[i] = party_hud_positions_x[i-1] + new_hud_spacing_step;
}

var menu_x_offset         = 48;    // User's value
var menu_y_offset         = 632;   // User's value
var menu_cx               = 160;
var menu_cy               = 600;   // User's value
var menu_r                = 80;
var button_scale          = .8;     // User's value

var list_x_base           = (menu_cx + menu_x_offset) + menu_r + 80; // User's formula
var list_y                = menu_y_offset; // Adjusted for visibility

var _font_for_lists = draw_get_font();
var _font_size_for_lists = font_exists(Font1) ? font_get_size(Font1) : 24;
var list_line_h           = _font_size_for_lists + floor(_font_size_for_lists * 0.5); // Dynamic line height

var list_padding          = 8;     // Internal padding for content
var overall_list_padding  = list_padding + 4; // Total padding for the background box (a bit bigger)

// list_item_w will be made dynamic for items, list_box_w for items also dynamic
var list_qty_w            = 40;  // Fixed width for quantity like "x99"

var list_select_color     = c_yellow;
var target_cursor_sprite  = spr_target_cursor;
var target_cursor_y_offset= -20;

var turn_order_x = display_get_gui_width() - 250; // User's value
var turn_order_y = 10;
var turn_order_spacing = 40;

// === Set Color and Alignments (Font already set) ===
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// === Draw Party HP/MP/Overdrive HUDs ===
// (This section remains unchanged from your last provided version based on my previous response)
if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    var party_size      = ds_list_size(global.battle_party);
    var _spr_hud_bg     = sprite_exists(spr_pc_hud_bg);
    var _spr_hp         = sprite_exists(spr_pc_hud_hp);
    var _spr_mp         = sprite_exists(spr_pc_hud_mp);
    var _spr_od         = sprite_exists(spr_pc_hud_od);
    var _spr_hp_w       = _spr_hp ? sprite_get_width(spr_pc_hud_hp) : 0;
    var _spr_hp_h       = _spr_hp ? sprite_get_height(spr_pc_hud_hp) : 0;
    var _spr_mp_w       = _spr_mp ? sprite_get_width(spr_pc_hud_mp) : 0;
    var _spr_mp_h       = _spr_mp ? sprite_get_height(spr_pc_hud_mp) : 0;
    var _spr_od_w       = _spr_od ? sprite_get_width(spr_pc_hud_od) : 0;
    var _spr_od_h       = _spr_od ? sprite_get_height(spr_pc_hud_od) : 0;
    var mp_text_additional_y_offset = 16;
    for (var i = 0; i < party_size; i++) {
        if (i >= array_length(party_hud_positions_x)) continue;
        var x0   = party_hud_positions_x[i];
        var y0   = party_hud_y;
        var inst = global.battle_party[| i];
        if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data)) continue;
        var d    = inst.data;
        var active = (i == active_idx);
        var alpha  = active ? 1 : 0.7;
        var tint   = active ? c_white : c_gray;
        if (d.hp <= 0) { alpha *= 0.5; tint = merge_color(tint, c_dkgray, 0.5); }
        if (_spr_hud_bg) draw_sprite_ext(spr_pc_hud_bg, 0, x0, y0, 1, 1, 0, tint, alpha);
        draw_set_alpha(alpha); draw_set_valign(fa_top);
        draw_text_color(x0 + 10, y0 - 48, d.name ?? "???", tint, tint, tint, tint, alpha);
        if (_spr_hp && variable_struct_exists(d, "hp") && variable_struct_exists(d, "maxhp")) {
            var r  = clamp(d.hp / max(1,d.maxhp), 0, 1);
            var w  = floor(_spr_hp_w * r);
            if (w > 0) draw_sprite_part_ext(spr_pc_hud_hp, 0, 0, 0, w, _spr_hp_h, x0 + 32, y0, 1, 1, c_white, alpha);
        }
        draw_set_valign(fa_middle);
        draw_text_color(x0 + 180, y0 - 16 + (_spr_hp_h / 2), string(floor(d.hp)) + "/" + string(floor(d.maxhp)), tint, tint, tint, tint, alpha);
        draw_set_valign(fa_top);
        if (_spr_mp && variable_struct_exists(d, "mp") && variable_struct_exists(d, "maxmp")) {
            var r2  = clamp(d.mp / max(1,d.maxmp), 0, 1);
            var w2  = floor(_spr_mp_w * r2);
            if (w2 > 0) draw_sprite_part_ext(spr_pc_hud_mp, 0, 0, 0, w2, _spr_mp_h, x0 + 32, y0, 1, 1, c_white, alpha);
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
    if (_current_battle_state == "player_input") {
        var ybutton_draw_x = 96 + menu_x_offset;  var ybutton_draw_y = 0 + menu_y_offset;
        var xbutton_draw_x = 0 + menu_x_offset;   var xbutton_draw_y = 96 + menu_y_offset;
        var bbutton_draw_x = 192 + menu_x_offset; var bbutton_draw_y = 96 + menu_y_offset;
        var abutton_draw_x = 96 + menu_x_offset;  var abutton_draw_y = 192 + menu_y_offset;

        if (sprite_exists(Ybutton)) draw_sprite_ext(Ybutton,0,ybutton_draw_x,ybutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Xbutton)) draw_sprite_ext(Xbutton,0,xbutton_draw_x,xbutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Bbutton)) draw_sprite_ext(Bbutton,0,bbutton_draw_x,bbutton_draw_y,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Abutton)) draw_sprite_ext(Abutton,0,abutton_draw_x,abutton_draw_y,button_scale,button_scale,0,c_white,1);

        draw_set_halign(fa_center); draw_set_valign(fa_middle);
        var default_button_dim = 32; // User's button_scale is 1, so this is unscaled fallback

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
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        var skills = (variable_struct_exists(active_p_data,"skills") && is_array(active_p_data.skills)) ? active_p_data.skills : [];
        var sel    = variable_struct_exists(active_p_data,"skill_index") ? active_p_data.skill_index : 0;
        var cnt    = array_length(skills);
        sel = (cnt>0) ? clamp(sel,0,cnt-1) : -1;
        
        var current_list_x = list_x_base;
        var current_list_y = list_y;
        
        var skill_list_content_w = 0;
        if (cnt > 0) {
            for (var j_calc = 0; j_calc < cnt; j_calc++) {
                var sk_calc = skills[j_calc]; if (!is_struct(sk_calc)) continue;
                skill_list_content_w = max(skill_list_content_w, string_width((sk_calc.name ?? "???") + " (MP " + string(sk_calc.cost ?? 0) + ")"));
            }
        } else {
            skill_list_content_w = string_width("No Skills");
        }
        var actual_skill_box_w = skill_list_content_w + overall_list_padding * 2;

        var box_h;
        if (cnt==0) { box_h = list_line_h + overall_list_padding * 2; }
        else { box_h = cnt*list_line_h + overall_list_padding * 2; }
        
        var box_x = current_list_x - overall_list_padding; 
        var box_y = current_list_y - overall_list_padding;

        if (sprite_exists(spr_box1)) { 
            var sw = sprite_get_width(spr_box1); var sh = sprite_get_height(spr_box1); 
            if (sw > 0 && sh > 0) draw_sprite_ext(spr_box1,-1,box_x,box_y,actual_skill_box_w/sw,box_h/sh,0,c_white,0.9); 
        }
        
        if (cnt>0) {
            for (var j=0; j<cnt; j++) {
                var sk = skills[j]; if (!is_struct(sk)) continue;
                var nm = sk.name ?? "???"; var cs = sk.cost ?? 0;
                var yj = current_list_y + j*list_line_h; // Top of text line
                if (j==sel) { 
                    draw_set_color(list_select_color); draw_set_alpha(0.5); 
                    draw_rectangle(box_x, yj, box_x + actual_skill_box_w, yj + list_line_h ,false); // Highlight full line slot
                    draw_set_alpha(1); 
                }
                var can_afford = true;
                if (variable_struct_exists(sk,"overdrive") && sk.overdrive) { can_afford = (active_p_data.overdrive >= active_p_data.overdrive_max); }
                else { can_afford = (active_p_data.mp >= cs); }
                draw_set_color(can_afford ? c_white : c_gray);
                draw_text(current_list_x, yj, nm + " (MP " + string(cs) + ")");
            }
        } else {
            draw_set_color(c_white);
            draw_text(current_list_x, current_list_y, "No Skills");
        }
        draw_set_alpha(1); draw_set_color(c_white);
    }
    else if (_current_battle_state == "item_select") {
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        var items = (variable_global_exists("battle_usable_items") && is_array(global.battle_usable_items)) ? global.battle_usable_items : [];
        var cnt   = array_length(items);
        var sel   = variable_struct_exists(active_p_data,"item_index") ? active_p_data.item_index : 0;
        sel = (cnt>0) ? clamp(sel, 0, cnt-1) : -1;
        
        var current_list_x = list_x_base;
        var current_list_y = list_y;
        
        var dynamic_item_name_w = 0;
        var item_list_content_w = 0;

        if (cnt > 0) {
            for (var j_calc = 0; j_calc < cnt; j_calc++) {
                var it_calc = items[j_calc]; if(!is_struct(it_calc)) continue;
                dynamic_item_name_w = max(dynamic_item_name_w, string_width(it_calc.name ?? "???")) + 48;
            }
            item_list_content_w = dynamic_item_name_w + list_padding + list_qty_w; // name + padding + quantity column
        } else {
            item_list_content_w = string_width("No Usable Items");
            dynamic_item_name_w = item_list_content_w; // Placeholder takes full content width
        }
        var actual_item_box_w = item_list_content_w + overall_list_padding * 2;
        
        var box_h;
        if (cnt==0) { box_h = list_line_h + overall_list_padding * 2; }
        else { box_h = cnt*list_line_h + overall_list_padding * 2; }

        var box_x = current_list_x - overall_list_padding; 
        var box_y = current_list_y - overall_list_padding;

        if (sprite_exists(spr_box1)) { 
            var sw = sprite_get_width(spr_box1); var sh = sprite_get_height(spr_box1); 
            if (sw > 0 && sh > 0) draw_sprite_ext(spr_box1,-1,box_x,box_y,actual_item_box_w/sw,box_h/sh,0,c_white,0.9); 
        }
        
        if (cnt>0) {
            for (var j=0; j<cnt; j++) {
                var it = items[j]; if (!is_struct(it)) continue;
                var nm = it.name ?? "???"; var qt = it.quantity;
                var yj = current_list_y + j*list_line_h; // Top of text line
                if (j == sel) { 
                    draw_set_color(list_select_color); draw_set_alpha(0.5); 
                    draw_rectangle(box_x, yj, box_x + actual_item_box_w, yj + list_line_h ,false); // Highlight full line slot
                    draw_set_alpha(1); 
                }
                draw_set_color(c_white);
                draw_text(current_list_x, yj, nm); // Draw item name
                draw_set_halign(fa_right);
                // X for quantity: start of list + dynamic name width + padding + fixed quantity width (this is right edge of qty column)
                draw_text(current_list_x + dynamic_item_name_w + list_padding + list_qty_w, yj, "x"+string(qt));
                draw_set_halign(fa_left);
            }
        } else {
            draw_set_color(c_white);
            draw_text(current_list_x, current_list_y, "No Usable Items");
        }
        draw_set_alpha(1); draw_set_color(c_white);
    }
}

// --- Draw Target Cursor ---
// (This section remains unchanged from your last provided version)
if (_current_battle_state == "TargetSelect"
 && variable_global_exists("battle_enemies")
 && ds_exists(global.battle_enemies, ds_type_list)
 && variable_global_exists("battle_target")) {
    var n_enemies = ds_list_size(global.battle_enemies);
    if (n_enemies > 0 && global.battle_target >= 0 && global.battle_target < n_enemies) {
        var tid_enemy = global.battle_enemies[| global.battle_target];
        if (instance_exists(tid_enemy)) {
            var tx = tid_enemy.x, ty = tid_enemy.bbox_top, off = 10;
            if (sprite_exists(spr_target_cursor)) draw_sprite(spr_target_cursor, -1, tx, ty - off);
            else { draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_text_color(tx, ty - off, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1); }
        }
    }
}
else if (_current_battle_state == "TargetSelectAlly" && variable_global_exists("battle_ally_target")) {
    if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
        var n_party = ds_list_size(global.battle_party);
        var ally_target_idx = global.battle_ally_target ?? -1;
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
                    if (sprite_exists(target_cursor_sprite)) {
                        draw_sprite(target_cursor_sprite, -1, tx_cursor, ty_cursor);
                    } else {
                        draw_set_halign(fa_center); draw_set_valign(fa_bottom);
                        draw_text_color(tx_cursor, ty_cursor, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1);
                    }
                }
            }
        }
    }
}

// === Draw Turn Order Display ===
// (This section remains unchanged from your last provided version)
if (instance_exists(obj_battle_manager)
 && variable_instance_exists(obj_battle_manager, "turnOrderDisplay")
 && is_array(obj_battle_manager.turnOrderDisplay)) {
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
/// obj_equipment_menu :: Draw GUI Event
/// Draws the equipment menu, character stats, and item selection sub-menu.

// 1) Bail if inactive or missing data
if (!variable_instance_exists(id, "active") || !active) {
    return;
}
if (!variable_instance_exists(id, "equipment_data") || !is_struct(equipment_data)
 || !variable_instance_exists(id, "menu_state")
 || !variable_instance_exists(id, "equipment_slots")
 || !variable_instance_exists(id, "selected_slot")
 || !variable_instance_exists(id, "item_submenu_choices")
 || !variable_instance_exists(id, "item_submenu_scroll_top")
 || !variable_instance_exists(id, "item_submenu_selected_index")
 || !variable_instance_exists(id, "item_submenu_display_count")
 || !variable_instance_exists(id, "margin"))
{
    if (font_exists(Font1)) draw_set_font(Font1);
    draw_text(10, 10, "Equipment Menu Error: Missing variables.");
    if (font_exists(Font1)) draw_set_font(-1);
    return;
}

// 2) GUI dims
var guiWidth     = display_get_gui_width();
var guiHeight    = display_get_gui_height();

// 3) Font & line metrics
if (font_exists(Font1)) draw_set_font(Font1);
else                       draw_set_font(-1);

var txtHeight    = string_height("HgAg");
var lineHeight   = ceil(txtHeight + 10);
var titleHeight  = ceil(txtHeight + 12);
var padOuter     = 20;
var padInner     = 8;
var menuMargin   = self.margin;

// 4) Colors
var colInc       = make_color_rgb(100,255,100);
var colDec       = make_color_rgb(255,100,100);
var colText      = c_white;
var colDim       = c_black;
var colPanel     = make_color_rgb(30,30,30);
var colHighlight = c_yellow;

// 5) Panel bounds
var panelX      = self.boxX;
var panelY      = self.boxY;
var panelW      = self.boxW;
var panelH      = self.boxH;

// 6) Compute final stats once
var statsFinal  = scr_CalculateEquippedStats(equipment_data);
if (!is_struct(statsFinal)) {
    draw_text(panelX + padOuter, panelY + padOuter, "Error: Stats unavailable.");
    draw_set_font(-1);
    return;
}

// 7) Dim BG
draw_set_alpha(0.7);
draw_set_color(colDim);
draw_rectangle(0,0,guiWidth,guiHeight,false);
draw_set_alpha(1.0);
draw_set_color(colText);

// 8) Draw panel box
if (sprite_exists(spr_box1)) {
    var sW = sprite_get_width(spr_box1);
    var sH = sprite_get_height(spr_box1);
    if (sW>0 && sH>0) {
        draw_sprite_ext(spr_box1,0,panelX,panelY,panelW/sW,panelH/sH,0,c_white,1);
    } else {
        draw_set_color(colPanel);
        draw_rectangle(panelX,panelY,panelX+panelW,panelY+panelH,false);
    }
} else {
    draw_set_color(colPanel);
    draw_rectangle(panelX,panelY,panelX+panelW,panelY+panelH,false);
}
draw_set_color(colText);

// 9) Title
var titleX  = panelX + panelW/2;
var titleY  = panelY + padOuter + titleHeight/2;
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var charName = variable_struct_get(statsFinal, "name") ?? "?";
draw_text(titleX, titleY, "Equipment - " + charName);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// 10) Columns
var startY      = panelY + padOuter + titleHeight + padOuter;
var slotColumnX = panelX + padOuter;

// compute widest slot label
var widestSlotW = 0;
for (var iSlot=0; iSlot<array_length(equipment_slots); iSlot++) {
    var w = string_width("> " + string_upper(equipment_slots[iSlot]) + ":");
    if (w > widestSlotW) widestSlotW = w;
}
var itemColumnX = slotColumnX + widestSlotW + padOuter;

// stats column
var statsColumnX = panelX + panelW * 0.55;
var widestStatW  = 0;
var statKeys     = ["hp","mp","atk","def","matk","mdef","spd","luk"];
for (var iKey=0; iKey<array_length(statKeys); iKey++) {
    var w = string_width(string_upper(statKeys[iKey]));
    if (w > widestStatW) widestStatW = w;
}
var statsValueX  = statsColumnX + widestStatW + padOuter;
var statsValueW  = string_width("999/9999");

// 11) Draw slots + equipped items
for (var iSlot=0; iSlot<array_length(equipment_slots); iSlot++) {
    var rowPos = startY + iSlot * lineHeight;
    var slotName = equipment_slots[iSlot];
    var isSelectedSlot = (iSlot == selected_slot && menu_state == EEquipMenuState.BrowseSlots);

    // slot label
    draw_set_color(isSelectedSlot ? colHighlight : colText);
    draw_text(slotColumnX, rowPos, (isSelectedSlot ? "> " : "  ") + string_upper(slotName) + ":");

    // equipped item
    var eqKey = variable_struct_get(statsFinal.equipment, slotName);
    var itemLabel = "(none)";
    if (is_string(eqKey) && eqKey!="" && eqKey!="noone") {
        var info = scr_GetItemData(eqKey);
        if (is_struct(info) && variable_struct_exists(info,"name")) {
            itemLabel = info.name;
        } else {
            itemLabel = eqKey + " (Inv!)";
        }
    }
    draw_set_color(isSelectedSlot ? colHighlight : colText);
    draw_text(itemColumnX, rowPos, itemLabel);
}

// 12) Draw stats
for (var iStat=0; iStat<array_length(statKeys); iStat++) {
    var statPos = startY + iStat * lineHeight;
    var keyName = statKeys[iStat];
    var valNum  = variable_struct_get(statsFinal, keyName) ?? 0;
    var txt     = string(valNum);

    if (keyName == "hp" && variable_struct_exists(statsFinal,"maxhp")) {
        var mh = variable_struct_get(statsFinal,"maxhp");
        txt = string(variable_struct_get(statsFinal,"hp")) + "/" + string(mh);
    }
    if (keyName == "mp" && variable_struct_exists(statsFinal,"maxmp")) {
        var mm = variable_struct_get(statsFinal,"maxmp");
        txt = string(variable_struct_get(statsFinal,"mp")) + "/" + string(mm);
    }

    draw_set_color(colText);
    draw_set_halign(fa_left);
    draw_text(statsColumnX, statPos, string_upper(keyName));
    draw_set_halign(fa_right);
    draw_text(statsValueX + statsValueW, statPos, txt);
}
draw_set_halign(fa_left);

// 13) Item sub-menu
if (menu_state == EEquipMenuState.SelectingItem) {
    var baseX        = slotColumnX + padInner;
    var baseY        = startY + selected_slot * lineHeight;
    var totalChoices = array_length(item_submenu_choices);
    var visibleCount = min(item_submenu_display_count, totalChoices);

    // measure widest item label
    var widestItemW  = 0;
    var diffLabelW   = string_width("MDEF +999");
    for (var iChoice=0; iChoice<totalChoices; iChoice++) {
        var cKey = item_submenu_choices[iChoice];
        var cName = "(Unequip)";
        if (is_string(cKey)) {
            var cInfo = scr_GetItemData(cKey);
            if (is_struct(cInfo) && variable_struct_exists(cInfo,"name")) {
                cName = cInfo.name;
            }
        }
        var w = string_width("> " + cName);
        if (w > widestItemW) widestItemW = w;
    }
    var maxDiffLines = array_length(statKeys); 
    var subBoxW = min(widestItemW*1.25 + padOuter + diffLabelW + padOuter*2,
                      guiWidth - baseX - menuMargin);
    var subBoxH = visibleCount * lineHeight 
            + padOuter*2 
            + maxDiffLines * lineHeight;

    if (baseY + subBoxH > guiHeight - menuMargin) {
        baseY = guiHeight - menuMargin - subBoxH;
    }
    if (baseY < menuMargin) {
        baseY = menuMargin;
    }

    // draw sub-box
    if (sprite_exists(spr_box1)) {
        var sW2 = sprite_get_width(spr_box1), sH2 = sprite_get_height(spr_box1);
        if (sW2>0 && sH2>0) {
            draw_sprite_ext(spr_box1,0,baseX,baseY,subBoxW/sW2,subBoxH/sH2,0,c_white,1);
        } else {
            draw_set_color(colPanel);
            draw_rectangle(baseX,baseY,baseX+subBoxW,baseY+subBoxH,false);
        }
    } else {
        draw_set_color(colPanel);
        draw_rectangle(baseX,baseY,baseX+subBoxW,baseY+subBoxH,false);
    }

    var textX = baseX + padOuter;
    var textY = baseY + padOuter;
    var diffX  = textX + widestItemW + padOuter;

    // draw each choice + stat diffs
    for (var iVis=0; iVis<visibleCount; iVis++) {
        var idxChoice = item_submenu_scroll_top + iVis;
        if (idxChoice >= totalChoices) break;

        var choicePos = textY + iVis * lineHeight;
        var cKey      = item_submenu_choices[idxChoice];
        var cName     = "(Unequip)";
        if (is_string(cKey)) {
            var cInfo = scr_GetItemData(cKey);
            if (is_struct(cInfo) && variable_struct_exists(cInfo,"name")) {
                cName = cInfo.name;
            }
        }
        var isSelChoice = (idxChoice == item_submenu_selected_index);

        draw_set_color(isSelChoice ? colHighlight : colText);
        draw_set_halign(fa_left);
        draw_text(textX, choicePos, (isSelChoice ? "> " : "") + cName);

        if (isSelChoice && is_struct(item_submenu_stat_diffs)) {
            var diffs  = item_submenu_stat_diffs;
            var offset = 0;
            var dLine  = lineHeight * 0.75;

            // hp_total
            var vHP = diffs.hp_total ?? 0;
            if (vHP != 0) {
                draw_set_color(vHP > 0 ? colInc : colDec);
                draw_text(diffX, choicePos + offset, "HP " + (vHP>0?"+":"") + string(vHP));
                offset += dLine;
            }
            // mp_total
            var vMP = diffs.mp_total ?? 0;
            if (vMP != 0) {
                draw_set_color(vMP > 0 ? colInc : colDec);
                draw_text(diffX, choicePos + offset, "MP " + (vMP>0?"+":"") + string(vMP));
                offset += dLine;
            }
            // atk
            var vAT = diffs.atk ?? 0;
            if (vAT != 0) {
                draw_set_color(vAT > 0 ? colInc : colDec);
                draw_text(diffX, choicePos + offset, "ATK " + (vAT>0?"+":"") + string(vAT));
                offset += dLine;
            }
            // def
            var vDF = diffs.def ?? 0;
            if (vDF != 0) {
                draw_set_color(vDF > 0 ? colInc : colDec);
                draw_text(diffX, choicePos + offset, "DEF " + (vDF>0?"+":"") + string(vDF));
                offset += dLine;
            }
            // matk
            var vMT = diffs.matk ?? 0;
            if (vMT != 0) {
                draw_set_color(vMT > 0 ? colInc : colDec);
                draw_text(diffX, choicePos + offset, "MATK " + (vMT>0?"+":"") + string(vMT));
                offset += dLine;
            }
            // mdef
            var vMD = diffs.mdef ?? 0;
            if (vMD != 0) {
                draw_set_color(vMD > 0 ? colInc : colDec);
                draw_text(diffX, choicePos + offset, "MDEF " + (vMD>0?"+":"") + string(vMD));
                offset += dLine;
            }
            // spd
            var vSP = diffs.spd ?? 0;
            if (vSP != 0) {
                draw_set_color(vSP > 0 ? colInc : colDec);
                draw_text(diffX, choicePos + offset, "SPD " + (vSP>0?"+":"") + string(vSP));
                offset += dLine;
            }
            // luk
            var vLU = diffs.luk ?? 0;
            if (vLU != 0) {
                draw_set_color(vLU > 0 ? colInc : colDec);
                draw_text(diffX, choicePos + offset, "LUK " + (vLU>0?"+":"") + string(vLU));
                offset += dLine;
            }
        }
    }

    // scroll arrows
    var arrowX   = baseX + subBoxW/2;
    var arrowPad = lineHeight * 0.25;
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    if (item_submenu_scroll_top > 0) {
        draw_text(arrowX, baseY + arrowPad, "▲");
    }
    if (item_submenu_scroll_top + visibleCount < totalChoices) {
        draw_text(arrowX, baseY + subBoxH - arrowPad, "▼");
    }
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// 14) Footer
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_bottom);
var footerTxt = (menu_state == EEquipMenuState.BrowseSlots)
              ? "[U/D] Slot  [L/R] Char  [Confirm] Select Item  [Cancel] Back"
              : "[U/D] Item  [Confirm] Equip Item  [Cancel] Back to Slots";
draw_text(menuMargin, guiHeight - menuMargin, footerTxt);

// 15) Reset
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
draw_set_color(c_white);

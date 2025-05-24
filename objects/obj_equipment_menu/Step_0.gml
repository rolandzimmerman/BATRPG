/// obj_equipment_menu :: Step Event
/// Handles navigation, party switching, opening item list, equipping, and closing.

// Assuming EEquipMenuState enum is defined globally (e.g., in scr_input_manager_init or another global script)
// enum EEquipMenuState { BrowseSlots, SelectingItem } 

// Only run when this menu is active overall
if (!variable_instance_exists(id,"menu_active") || !menu_active) return;

// --- Initialize Instance Variables if they somehow don't exist (Safety) ---
// (This block remains the same, but ensure EEquipMenuState.BrowseSlots is valid)
if (!variable_instance_exists(id, "menu_state"))                  menu_state = EEquipMenuState.BrowseSlots;
if (!variable_instance_exists(id, "equipment_slots"))              equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ];
if (!variable_instance_exists(id, "selected_slot"))                selected_slot = 0;
if (!variable_instance_exists(id, "party_index"))                  party_index = 0;
if (!variable_instance_exists(id, "equipment_character_key"))      equipment_character_key = (variable_global_exists("party_members") && is_array(global.party_members) && array_length(global.party_members)>0) ? global.party_members[0] : "hero";
if (!variable_instance_exists(id, "equipment_data") || !is_struct(equipment_data)) { equipment_data = scr_GetPlayerData(equipment_character_key); if (!is_struct(equipment_data)) { instance_destroy(); exit; } } 
if (!variable_instance_exists(id, "item_submenu_choices"))         item_submenu_choices = [];
if (!variable_instance_exists(id, "item_submenu_selected_index")) item_submenu_selected_index = 0;
if (!variable_instance_exists(id, "item_submenu_scroll_top"))      item_submenu_scroll_top = 0;
if (!variable_instance_exists(id, "item_submenu_display_count"))  item_submenu_display_count = 5;
if (!variable_instance_exists(id, "item_submenu_stat_diffs"))     item_submenu_stat_diffs = {};
if (!variable_instance_exists(id, "calling_menu"))                 calling_menu = noone;


// — INPUT READING —————————————————————————————————————————————
// Assuming player_index 0 for gamepad inputs by default
var up_pressed = input_check_pressed(INPUT_ACTION.MENU_UP);
var down_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN);
var prev_char_pressed = input_check_pressed(INPUT_ACTION.MENU_PREVIOUS_CHARACTER); // For party switching
var next_char_pressed = input_check_pressed(INPUT_ACTION.MENU_NEXT_CHARACTER); // For party switching
var confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);
var back_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL);


// --- State Machine Logic ————————————————————————————————————————————————
switch (menu_state) {

    // #########################################################################
    // ## STATE: Browse EQUIPMENT SLOTS                                       ##
    // #########################################################################
    case EEquipMenuState.BrowseSlots:
        
        // Optional Raw Input Logging (can be removed if not needed for this specific menu anymore)
        // if (up_pressed || down_pressed || prev_char_pressed || next_char_pressed || confirm_pressed || back_pressed) {
        //     show_debug_message("EquipMenu BrowseSlots Input -> Up/Down: " + string(up_pressed) + "/" + string(down_pressed) +
        //                        " | Prev/Next Char: " + string(prev_char_pressed) + "/" + string(next_char_pressed) +
        //                        " | Confirm: " + string(confirm_pressed) + " | Back: " + string(back_pressed));
        // }

        // --- Slot Navigation (Up/Down) ---
        var slot_count = array_length(equipment_slots);
        if (slot_count > 0) { // Ensure there are slots to navigate
            if (up_pressed)   { selected_slot = (selected_slot - 1 + slot_count) mod slot_count; /* Play Sound? */ }
            if (down_pressed) { selected_slot = (selected_slot + 1) mod slot_count; /* Play Sound? */ }
        }

        // --- Party Switching (L-Shoulder/R-Shoulder or mapped keys) ---
        var party_member_list = (variable_global_exists("party_members") && is_array(global.party_members)) ? global.party_members : [];
        var current_party_count = array_length(party_member_list);
        var party_changed_by_input = false; // Renamed to avoid conflict if 'party_changed' is an instance var
        
        if (prev_char_pressed && current_party_count > 1) { 
            party_index = (party_index - 1 + current_party_count) mod current_party_count; 
            party_changed_by_input = true; 
        }
        if (next_char_pressed && current_party_count > 1) { 
            party_index = (party_index + 1) mod current_party_count; 
            party_changed_by_input = true; 
        }
        
        if (party_changed_by_input) { 
            equipment_character_key = party_member_list[party_index];
            show_debug_message("EquipMenu -> Party Switch Attempt: Index=" + string(party_index) + ", Key=" + equipment_character_key); 
            var new_equipment_data = scr_GetPlayerData(equipment_character_key); 
            
            if (!is_struct(new_equipment_data)) { 
                show_debug_message("ERROR [EquipMenu]: scr_GetPlayerData failed for " + equipment_character_key + " during party switch!");
                // Attempt to revert party_index if data fetch failed
                if (prev_char_pressed) party_index = (party_index + 1) mod current_party_count; // Revert Left
                else if (next_char_pressed) party_index = (party_index - 1 + current_party_count) mod current_party_count; // Revert Right
                
                equipment_character_key = party_member_list[party_index]; // Revert key
                // No need to re-fetch equipment_data here as it should revert to previous valid state.
                // The break might be too harsh if equipment_data was already valid.
                // Consider just playing an error sound and not changing character.
            } else {
                equipment_data = new_equipment_data; // Successfully switched
                selected_slot = 0; // Reset slot selection to the first slot for the new character
                show_debug_message("EquipMenu -> Party Switch SUCCESS. Displaying data for: " + equipment_character_key + " (Class: " + string(equipment_data.class ?? "N/A") + ")"); 
                // audio_play_sound(snd_party_switch, 0, false); // Example sound
            }
        }

        // --- Open Item Selection Submenu ---
        if (confirm_pressed && slot_count > 0) { 
            show_debug_message("EquipMenu -> Confirm pressed on slot: " + equipment_slots[selected_slot]);
            // ... (rest of your existing logic for building item_submenu_choices,
            //      finding current equipped, calculating diffs, and changing state to SelectingItem) ...
            // This part seems fine as it doesn't involve direct input checks anymore, but rather uses the 'confirm_pressed' variable.
            // I will include it for completeness:
            var _slotname = equipment_slots[selected_slot];
            var _pers_data_struct; // Renamed
            var _character_class = equipment_data.class ?? "Unknown"; 

            if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) { 
                show_debug_message("ERROR [EquipMenu]: global.party_current_stats missing!"); break; 
            }
            _pers_data_struct = ds_map_find_value(global.party_current_stats, equipment_character_key);
            if (!is_struct(_pers_data_struct)){ 
                show_debug_message("ERROR [EquipMenu]: Persistent data struct missing for " + equipment_character_key); break; 
            }

            item_submenu_choices = [noone]; // Start with "Unequip" / "None"
            var _inv_list = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];
            
            show_debug_message("EquipMenu -> Building item list for slot: " + _slotname + " | Char Class: " + _character_class);
            for (var i = 0; i < array_length(_inv_list); i++) { 
                var entry = _inv_list[i];
                if (!is_struct(entry) || !variable_struct_exists(entry, "item_key") || !variable_struct_exists(entry, "quantity") || entry.quantity <= 0) continue;
                var _item_key = entry.item_key; 
                var _item_data = scr_GetItemData(_item_key); 
                
                var can_equip = false;
                if (is_struct(_item_data)) {
                    if ((_item_data.type ?? "") == "equipment" && (_item_data.equip_slot ?? "") == _slotname) {
                        var _allowed_classes_list = _item_data.allowed_classes ?? []; // Default to empty array if missing
                        if (is_array(_allowed_classes_list)) {
                            if (array_length(_allowed_classes_list) == 0) { 
                                can_equip = true; // Equippable by all classes if list is empty
                            } else { 
                                for (var j = 0; j < array_length(_allowed_classes_list); j++) { 
                                    if (_allowed_classes_list[j] == _character_class) { can_equip = true; break; } 
                                } 
                            }
                        } else { can_equip = true; } // If allowed_classes isn't an array, assume equippable (or log warning)
                    }
                }
                if (can_equip) { array_push(item_submenu_choices, _item_key); }
            } 
            show_debug_message("EquipMenu -> Built item list: " + string(item_submenu_choices));

            var _current_equipped_key = noone;
            if (variable_struct_exists(_pers_data_struct, "equipment") && is_struct(_pers_data_struct.equipment)) {
                var _equip_struct_current = _pers_data_struct.equipment; // Renamed
                if (variable_struct_exists(_equip_struct_current, _slotname)) { 
                    _current_equipped_key = variable_struct_get(_equip_struct_current, _slotname); 
                }
            }
            item_submenu_selected_index = 0; 
            for (var j = 0; j < array_length(item_submenu_choices); j++) { 
                if (item_submenu_choices[j] == _current_equipped_key) { item_submenu_selected_index = j; break; } 
            }
            show_debug_message("EquipMenu -> Current item key: " + string(_current_equipped_key) + ", Selected Index: " + string(item_submenu_selected_index));

            var _potential_key_on_open = item_submenu_choices[item_submenu_selected_index];
            if (script_exists(scr_CalculateStatDifference)) { 
                item_submenu_stat_diffs = scr_CalculateStatDifference(equipment_character_key, _slotname, _current_equipped_key, _potential_key_on_open); // Pass char_key and slot for context
            } else { 
                show_debug_message("Warning [EquipMenu]: scr_CalculateStatDifference script missing!"); item_submenu_stat_diffs = {}; 
            }
            item_submenu_scroll_top = 0;
            if (item_submenu_selected_index >= item_submenu_display_count) { 
                item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1; 
            }
            menu_state = EEquipMenuState.SelectingItem; 
            show_debug_message("EquipMenu -> Changed state to SelectingItem");
            // audio_play_sound(snd_menu_open_sub, 0, false); // Example sound
        } // End if(confirm_pressed)

        // --- Close / Return to Pause Menu ---
        if (back_pressed) { 
            show_debug_message("EquipMenu -> Closing Equipment Menu from BrowseSlots.");
            // audio_play_sound(snd_menu_cancel, 0, false); // Example sound
            if (instance_exists(calling_menu)) { 
                if (variable_instance_exists(calling_menu, "active")) { calling_menu.active = true; } 
                instance_activate_object(calling_menu); // Ensure it's active if it was deactivated
            }
            instance_destroy(); 
            exit;
        }
        break; // End case EEquipMenuState.BrowseSlots


    // #########################################################################
    // ## STATE: SELECTING AN ITEM FROM THE LIST                              ##
    // #########################################################################
    case EEquipMenuState.SelectingItem:
        var _item_list_count = array_length(item_submenu_choices); // Renamed
        var _persistent_char_data; // Renamed
        // ... (rest of your existing SelectingItem state logic, which uses up_pressed, down_pressed, confirm_pressed, back_pressed) ...
        // This part should be largely okay as it now uses the input action variables.
        // I'll include it for completeness:

        if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) { 
            show_debug_message("CRITICAL ERROR [EquipMenu SelectingItem]: global.party_current_stats missing!"); 
            menu_state = EEquipMenuState.BrowseSlots; break; 
        }
        _persistent_char_data = ds_map_find_value(global.party_current_stats, equipment_character_key);
        if (!is_struct(_persistent_char_data)){ 
            show_debug_message("CRITICAL ERROR [EquipMenu SelectingItem]: _persistent_char_data invalid struct for " + equipment_character_key); 
            menu_state = EEquipMenuState.BrowseSlots; break; 
        }

        var _slotname_to_equip = equipment_slots[selected_slot]; // Renamed
        var _current_item_equipped_in_slot = noone; // Renamed
        if (variable_struct_exists(_persistent_char_data, "equipment") && is_struct(_persistent_char_data.equipment)) {
            var _equip_struct_current_select = _persistent_char_data.equipment; // Renamed
            if (variable_struct_exists(_equip_struct_current_select, _slotname_to_equip)) { 
                _current_item_equipped_in_slot = variable_struct_get(_equip_struct_current_select, _slotname_to_equip); 
            }
        }

        var _index_changed_in_submenu = false; // Renamed
        if (up_pressed && _item_list_count > 0) { 
            item_submenu_selected_index = (item_submenu_selected_index - 1 + _item_list_count) mod _item_list_count; 
            _index_changed_in_submenu = true; 
            if (item_submenu_selected_index < item_submenu_scroll_top) { 
                item_submenu_scroll_top = item_submenu_selected_index; 
            } else if (item_submenu_selected_index == _item_list_count - 1 && item_submenu_scroll_top > 0 && _item_list_count > item_submenu_display_count) { 
                item_submenu_scroll_top = max(0, _item_list_count - item_submenu_display_count); 
            } 
        }
        if (down_pressed && _item_list_count > 0) { 
            item_submenu_selected_index = (item_submenu_selected_index + 1) mod _item_list_count; 
            _index_changed_in_submenu = true; 
            if (item_submenu_selected_index >= item_submenu_scroll_top + item_submenu_display_count) { 
                item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1; 
            } else if (item_submenu_selected_index == 0 && item_submenu_scroll_top > 0 && _item_list_count > item_submenu_display_count) { 
                item_submenu_scroll_top = 0; 
            } 
        }
        item_submenu_scroll_top = max(0, min(item_submenu_scroll_top, max(0, _item_list_count - item_submenu_display_count)));

        if (_index_changed_in_submenu && script_exists(scr_CalculateStatDifference)) { 
            var _new_potential_key = (_item_list_count > 0) ? item_submenu_choices[item_submenu_selected_index] : noone; // Renamed
            item_submenu_stat_diffs = scr_CalculateStatDifference(equipment_character_key, _slotname_to_equip, _current_item_equipped_in_slot, _new_potential_key);
            // audio_play_sound(snd_menu_cursor, 0, false); // Example sound
        }

        if (confirm_pressed && _item_list_count > 0) {
            var _new_item_to_equip = item_submenu_choices[item_submenu_selected_index]; // Renamed
            var _equipment_struct_to_modify; // Renamed

            show_debug_message("EquipMenu -> Attempting to equip '" + string(_new_item_to_equip) + "' in slot '" + _slotname_to_equip + "' for " + equipment_character_key);
            // audio_play_sound(snd_equip_item, 0, false); // Example sound

            if (!variable_struct_exists(_persistent_char_data, "equipment") || !is_struct(_persistent_char_data.equipment)) {
                show_debug_message("Note [EquipMenu]: Creating 'equipment' struct on persistent data for '" + equipment_character_key + "'.");
                _persistent_char_data.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
            }
            _equipment_struct_to_modify = _persistent_char_data.equipment; 

            if (variable_struct_exists(_equipment_struct_to_modify, _slotname_to_equip)) { 
                variable_struct_set(_equipment_struct_to_modify, _slotname_to_equip, _new_item_to_equip);
                show_debug_message("EquipMenu -> Set " + _slotname_to_equip + " = " + string(_new_item_to_equip) + " in persistent data.");
                
                // Update player's derived stats if needed (or this is done on menu close / battle start)
                // For example, by calling a function that recalculates stats based on new equipment
                // if (script_exists(scr_RecalculatePlayerStats)) {
                //     scr_RecalculatePlayerStats(equipment_character_key);
                // }

                // Refresh local cache equipment_data to update display immediately
                equipment_data = scr_GetPlayerData(equipment_character_key); 
                if (!is_struct(equipment_data)) { show_debug_message("ERROR [EquipMenu]: scr_GetPlayerData failed after equipping."); }
                
                menu_state = EEquipMenuState.BrowseSlots; 
                item_submenu_choices = []; item_submenu_stat_diffs = {};
            } else {
                show_debug_message("ERROR [EquipMenu]: Invalid slot name '" + _slotname_to_equip + "' in equipment struct!");
                menu_state = EEquipMenuState.BrowseSlots; item_submenu_choices = []; item_submenu_stat_diffs = {};
            }
        }

        if (back_pressed) {
            menu_state = EEquipMenuState.BrowseSlots; item_submenu_choices = []; item_submenu_stat_diffs = {};
            // audio_play_sound(snd_menu_back, 0, false); // Example sound
        }
        break; // End case EEquipMenuState.SelectingItem

    default: // Should ideally not be reached if menu_state is always valid
        show_debug_message("ERROR [obj_equipment_menu]: Unknown menu_state: " + string(menu_state));
        menu_state = EEquipMenuState.BrowseSlots; // Reset to a known safe state
        break;
} // End Switch
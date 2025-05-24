/// obj_item_menu_field :: Step Event
/// Handle navigation, selection, use (via stats DS map), and SFX outside battle.

if (!active) return; // Assuming 'active' is an instance variable initialized in Create

// --- INPUT ---
// Assuming player_index 0 for gamepad inputs by default
var up_pressed = input_check_pressed(INPUT_ACTION.MENU_UP);
var down_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN);
var confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);
var back_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL);

// Ensure menu_state, item_index, and usable_items are initialized (typically in Create event)
menu_state = menu_state ?? "item_select";
item_index = item_index ?? 0;
usable_items = usable_items ?? []; // Should be populated when menu opens
target_party_index = target_party_index ?? 0;


switch (menu_state) {

    // ──────────────────────────────────────────────────────────────────────
    case "item_select":
        var count = array_length(usable_items);
        if (count > 0) {
            // Ensure item_index is valid before use
            item_index = clamp(item_index, 0, max(0, count - 1)); 

            if (up_pressed) {
                item_index = (item_index - 1 + count) mod count;
                // audio_play_sound(snd_menu_cursor, 0, false);
            }
            if (down_pressed) {
                item_index = (item_index + 1) mod count;
                // audio_play_sound(snd_menu_cursor, 0, false);
            }

            if (confirm_pressed && item_index != -1 && item_index < count) { // Check item_index validity again
                var selected_item_struct = usable_items[item_index]; // 'sel' renamed for clarity
                var item_data = scr_GetItemData(selected_item_struct.item_key);
                // audio_play_sound(snd_menu_select, 0, false);

                if (!is_struct(item_data)) {
                    show_debug_message("ERROR [obj_item_menu_field]: No item data for '" + string(selected_item_struct.item_key) + "'");
                } else {
                    var target_type = item_data.target ?? "none"; // 'tgt' renamed

                    // --- single-target items require picking a party member ---
                    if (target_type == "ally" || target_type == "self") {
                        target_party_index = (target_type == "self" && variable_global_exists("active_party_member_index")) ? global.active_party_member_index : 0; // Default to first or self if applicable
                        menu_state = "target_select";
                        show_debug_message("Item Menu: Item '" + string(selected_item_struct.item_key) + "' requires target selection.");
                    
                    // --- apply to all allies via stats map ---
                    } else if (target_type == "all_allies") {
                        show_debug_message("Item Menu: Using '" + string(selected_item_struct.item_key) + "' on ALL allies.");
                        var item_used_on_anyone = false;
                        if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map) &&
                            variable_global_exists("party_members") && is_array(global.party_members)) {
                            
                            for (var i = 0; i < array_length(global.party_members); i++) {
                                var member_key = global.party_members[i];
                                if (ds_map_exists(global.party_current_stats, member_key)) {
                                    var stats_struct = ds_map_find_value(global.party_current_stats, member_key); // 'stats' renamed
                                    
                                    // Example: heal_hp effect (expand for other item effects)
                                    if (item_data.effect == "heal_hp" &&
                                        variable_struct_exists(stats_struct, "hp") &&
                                        variable_struct_exists(stats_struct, "maxhp")) {
                                        
                                        var old_hp = stats_struct.hp;
                                        stats_struct.hp = min(stats_struct.maxhp, stats_struct.hp + (item_data.value ?? 0));
                                        var healed_amount = stats_struct.hp - old_hp; // 'healed' renamed
                                        if (healed_amount > 0) {
                                            item_used_on_anyone = true;
                                            show_debug_message(" -> Healed " + string(member_key) + " for " + string(healed_amount) + " HP.");
                                            // Optional: spawn a "+HP" popup for this member
                                        }
                                    }
                                    // Add other effects like "cure_status", "revive" here for "all_allies" items
                                }
                            }
                        }
                        
                        if (item_used_on_anyone) {
                            // Consume one item from the stack
                            scr_RemoveInventoryItem(selected_item_struct.item_key, 1); // Use new function
                            // Refresh usable_items array after consumption as quantity might change
                            // This requires a function to rebuild usable_items, or carefully manage the current array
                            // For simplicity here, we'll assume scr_RemoveInventoryItem handles global inventory,
                            // and usable_items might need a refresh via a dedicated function call here.
                            // E.g., self.usable_items = scr_GetFieldUsableItems(); 
                            // item_index = clamp(item_index, 0, max(0, array_length(usable_items) -1));

                            // For now, just decrement quantity in the local list and remove if zero
                            selected_item_struct.quantity -= 1;
                            if (selected_item_struct.quantity <= 0) {
                                array_delete(usable_items, item_index, 1);
                                item_index = clamp(item_index, 0, max(0, array_length(usable_items) - 1));
                            }
                            if (audio_exists(snd_sfx_heal)) audio_play_sound(snd_sfx_heal, 1, false); // Generic item use sound
                        } else {
                            show_debug_message("Item Menu: Item '" + string(selected_item_struct.item_key) + "' had no effect on any ally.");
                            // audio_play_sound(snd_menu_error, 0, false);
                        }

                    } else { // Item target type not suitable for field use on allies
                        show_debug_message("Item Menu: Cannot use item '" + string(selected_item_struct.item_key) + "' (target: " + target_type + ") on allies in this way from field menu.");
                        // audio_play_sound(snd_menu_error, 0, false);
                    }
                }
            }
        } else if (count == 0 && confirm_pressed) { // No items, confirmed
            // audio_play_sound(snd_menu_error, 0, false);
        }


        // Back action: resume calling menu (e.g., pause menu) or unpause game
        if (back_pressed) {
            // audio_play_sound(snd_menu_cancel, 0, false);
            if (instance_exists(calling_menu) && variable_instance_exists(calling_menu, "active")) {
                calling_menu.active = true;
            } else if (instance_exists(obj_game_manager)) { // Fallback if no calling_menu
                obj_game_manager.game_state = "playing";
                instance_activate_all(); // Ensure player is active
            }
            instance_destroy(); // Destroy this item menu
            exit; // Exit step
        }
        break;


    // ──────────────────────────────────────────────────────────────────────
    case "target_select":
        var party_keys = global.party_members ?? []; // 'keys' renamed
        var party_count = array_length(party_keys); // 'cnt' renamed
        
        if (party_count <= 0) { // No party members to target
            show_debug_message("Item Menu Target Select: No party members. Returning to item select.");
            menu_state = "item_select";
            break;
        }

        // Navigation
        target_party_index = clamp(target_party_index, 0, max(0, party_count - 1));
        if (up_pressed) {
            target_party_index = (target_party_index - 1 + party_count) mod party_count;
            // audio_play_sound(snd_menu_cursor, 0, false);
        }
        if (down_pressed) {
            target_party_index = (target_party_index + 1) mod party_count;
            // audio_play_sound(snd_menu_cursor, 0, false);
        }

        // Confirm target: apply item to one selected party member
        if (confirm_pressed) {
            if (item_index < 0 || item_index >= array_length(usable_items)) {
                show_debug_message("ERROR [obj_item_menu_field]: Invalid item_index in target_select. Returning to item_select.");
                menu_state = "item_select";
                break;
            }
            var selected_item_struct_target = usable_items[item_index]; // 'sel' renamed
            var item_data_target = scr_GetItemData(selected_item_struct_target.item_key); // 'data' renamed
            var target_member_key = party_keys[target_party_index]; // 'key' renamed

            var item_was_used = false; // 'used' renamed

            // Apply item effect via stats map (global.party_current_stats)
            if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map) &&
                ds_map_exists(global.party_current_stats, target_member_key)) {
                
                var target_stats_struct = ds_map_find_value(global.party_current_stats, target_member_key); // 'stats' renamed

                // Example item effects (expand this switch)
                switch (item_data_target.effect) {
                    case "heal_hp":
                        if (variable_struct_exists(target_stats_struct, "hp") && variable_struct_exists(target_stats_struct, "maxhp")) {
                            if (target_stats_struct.hp > 0 && target_stats_struct.hp < target_stats_struct.maxhp) { // Can only heal if not KO and not full HP
                                var old_hp_target = target_stats_struct.hp; // 'old' renamed
                                target_stats_struct.hp = min(target_stats_struct.maxhp, target_stats_struct.hp + (item_data_target.value ?? 0));
                                if (target_stats_struct.hp > old_hp_target) {
                                    item_was_used = true;
                                    show_debug_message(" -> Healed " + string(target_member_key) + " for " + string(target_stats_struct.hp - old_hp_target) + " HP.");
                                }
                            } else { show_debug_message(" -> Cannot use Heal HP on " + string(target_member_key) + " (HP: " + string(target_stats_struct.hp) + "/" + string(target_stats_struct.maxhp) + ")"); }
                        }
                        break;
                    case "cure_status":
                        if (variable_struct_exists(target_stats_struct, "status_effect") &&
                            target_stats_struct.status_effect == (item_data_target.value ?? "none")) { // 'value' in item data specifies which status to cure
                            
                            target_stats_struct.status_effect = "none";
                            if (variable_struct_exists(target_stats_struct, "status_duration")) {
                                target_stats_struct.status_duration = 0;
                            }
                            item_was_used = true;
                            show_debug_message(" -> Cured status '" + string(item_data_target.value) + "' from " + string(target_member_key));
                        } else { show_debug_message(" -> Status '" + string(item_data_target.value) + "' not present on " + string(target_member_key)); }
                        break;
                    // Add more cases for other item effects like "revive_ally", "buff_stat", etc.
                    default:
                        show_debug_message("Item Menu: Unknown item effect '" + string(item_data_target.effect ?? "none") + "' for item '" + string(selected_item_struct_target.item_key) + "'.");
                        break;
                }

                if (item_was_used) {
                    // Consume item from inventory
                    scr_RemoveInventoryItem(selected_item_struct_target.item_key, 1); // Use global inventory management
                    
                    // Update local usable_items list (decrement quantity or remove)
                    selected_item_struct_target.quantity -= 1;
                    if (selected_item_struct_target.quantity <= 0) {
                        array_delete(usable_items, item_index, 1);
                        // Adjust item_index to be valid after deletion
                        if (array_length(usable_items) > 0) {
                            item_index = clamp(item_index, 0, array_length(usable_items) - 1);
                        } else {
                            item_index = -1; // No items left to select
                        }
                    }
                    
                    // Play SFX (use item_data_target.sfx if available, else a generic one)
                    var sfx_to_play = item_data_target.sfx ?? snd_sfx_heal; // Example fallback
                    if (audio_exists(sfx_to_play)) audio_play_sound(sfx_to_play, 1, false);
                    // audio_play_sound(snd_menu_select, 0, false);
                } else {
                    show_debug_message("Item Menu: Item '" + string(selected_item_struct_target.item_key) + "' had no effect on " + string(target_member_key) + ".");
                    // audio_play_sound(snd_menu_error, 0, false); // Error/fail sound
                }
            } else { // Fallback if target stats not found (should not happen if party_members and party_current_stats are synced)
                show_debug_message("ERROR [obj_item_menu_field]: Could not find stats for target '" + string(target_member_key) + "'.");
                // audio_play_sound(snd_menu_error, 0, false);
            }
            
            // Return to item selection list after attempting to use an item
            menu_state = "item_select";
            show_debug_message("Item Menu: Returning to item_select state after target action.");
        }

        // Cancel target selection: return to item_select state
        if (back_pressed) {
            // audio_play_sound(snd_menu_cancel, 0, false);
            menu_state = "item_select";
            show_debug_message("Item Menu: Canceled target selection. Returning to item_select.");
        }
        break;
        
    default: // Should not happen if menu_state is properly managed
        show_debug_message("ERROR [obj_item_menu_field]: Unknown menu_state: " + string(menu_state));
        menu_state = "item_select"; // Reset to a known state
        break;
}
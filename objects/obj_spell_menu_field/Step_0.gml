/// obj_field_spell_menu - Step Event
/// @description Handle navigation and actions for field spell menu

if (!active) return; 

// --- Input ---
// Assuming player_index 0 for this menu (default for input functions)
var left_pressed = input_check_pressed(INPUT_ACTION.MENU_LEFT);
var right_pressed = input_check_pressed(INPUT_ACTION.MENU_RIGHT);
var up_pressed = input_check_pressed(INPUT_ACTION.MENU_UP);
var down_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN);
var confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);
var back_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL); // MENU_CANCEL is used for "Back"

// --- State Machine ---
switch (menu_state) {
    case "character_select":
        var party_list_keys = variable_global_exists("party_members") ? global.party_members : [];
        var party_count = array_length(party_list_keys);
        if (party_count > 0) {
            if (left_pressed) { 
                character_index = (character_index - 1 + party_count) mod party_count; 
                // audio_play_sound(snd_menu_blip, 0, false); // Example sound
            }
            if (right_pressed) { 
                character_index = (character_index + 1) mod party_count; 
                // audio_play_sound(snd_menu_blip, 0, false); // Example sound
            }
            if (confirm_pressed) { 
                selected_caster_key = party_list_keys[character_index];
                show_debug_message("Spell Menu Field: Confirmed caster '" + selected_caster_key + "'");
                // audio_play_sound(snd_menu_select, 0, false); // Example sound
                
                // Populate usable spells 
                usable_spells = []; 
                spell_index = 0;   
                if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) { 
                    if (ds_map_exists(global.party_current_stats, selected_caster_key)) { 
                        var caster_data = ds_map_find_value(global.party_current_stats, selected_caster_key); 
                        if (is_struct(caster_data) && variable_struct_exists(caster_data, "skills") && is_array(caster_data.skills)) { 
                            var all_skills = caster_data.skills;
                            for (var i = 0; i < array_length(all_skills); i++) {
                                var skill_struct = all_skills[i];
                                if (is_struct(skill_struct) && (variable_struct_get(skill_struct, "usable_in_field") ?? false)) {
                                    array_push(usable_spells, skill_struct); 
                                }
                            }
                        } 
                    } 
                } 
                if (array_length(usable_spells) == 0) { 
                    spell_index = -1; 
                    show_debug_message("  -> FINAL: No field-usable spells found for " + selected_caster_key); 
                    // Potentially play a "no spells" sound or give feedback
                } else { 
                    spell_index = 0; 
                    show_debug_message("  -> FINAL: Populated usable_spells list for " + selected_caster_key + ". Count: " + string(array_length(usable_spells))); 
                }
                menu_state = "spell_select"; 
                show_debug_message(" -> Transitioning to spell_select state.");
            }
        } 
        // Cancel logic (close the menu)
        if (back_pressed) { 
            show_debug_message("Spell Menu Field: Back pressed from character_select. Closing menu.");
            // audio_play_sound(snd_menu_cancel, 0, false); // Example sound
            if (instance_exists(calling_menu)) { 
                instance_activate_all(); // Reactivate all instances that were part of the calling context
                if(variable_instance_exists(calling_menu, "active")) { 
                    calling_menu.active = true; // Reactivate the specific calling menu if it has an 'active' flag
                } 
            } else { 
                // If no calling_menu, perhaps unpause the game if it was paused by this menu
                // e.g., if (instance_exists(obj_game_manager)) obj_game_manager.game_state = "playing";
            } 
            instance_destroy(); 
            exit; // Important to exit after destroy to prevent further code execution on this instance
        }
        break; 
        
    case "spell_select":
        var spell_count = array_length(usable_spells);
        if (spell_count > 0) { 
            if (up_pressed) { 
                spell_index = (spell_index - 1 + spell_count) mod spell_count; 
                // audio_play_sound(snd_menu_blip, 0, false); // Example sound
            }
            if (down_pressed) { 
                spell_index = (spell_index + 1) mod spell_count; 
                // audio_play_sound(snd_menu_blip, 0, false); // Example sound
            }
            
            if (confirm_pressed && spell_index != -1) { 
                var selected_spell = usable_spells[spell_index];
                show_debug_message("Spell Menu Field: Confirmed spell '" + (selected_spell.name ?? "???") + "'");
                // audio_play_sound(snd_menu_select, 0, false); // Example sound

                var cost = selected_spell.cost ?? 0;
                var caster_data_struct; // Renamed to avoid conflict with the variable 'caster_data' in some GML versions
                if (ds_map_exists(global.party_current_stats, selected_caster_key)) {
                    caster_data_struct = ds_map_find_value(global.party_current_stats, selected_caster_key);
                } else {
                    show_debug_message("  -> ERROR: Caster data not found for " + selected_caster_key + " in spell_select.");
                    menu_state = "character_select"; // Go back if data is missing
                    break;
                }
                
                var current_mp = (is_struct(caster_data_struct) && variable_struct_exists(caster_data_struct, "mp")) ? caster_data_struct.mp : 0;
                
                if (current_mp >= cost) { 
                    show_debug_message("  -> MP Check OK (Have " + string(current_mp) + ", Need " + string(cost) + ")");
                    var targetType = variable_struct_get(selected_spell, "target_type") ?? "enemy"; 
                    
                    if (targetType == "ally" || targetType == "self") {
                        target_party_index = (targetType == "self") ? character_index : 0; // Default target to first party member or self
                        menu_state = "target_select_ally"; 
                        show_debug_message("  -> Transitioning to target_select_ally state.");
                    } 
                    else if (targetType == "all_allies") {
                        show_debug_message("  -> Applying '" + selected_spell.name + "' to all allies...");
                        var any_cast_successful = false;
                        var party_keys_for_all_allies = global.party_members ?? [];
                        for (var i_ally = 0; i_ally < array_length(party_keys_for_all_allies); i_ally++) {
                            var current_target_key = party_keys_for_all_allies[i_ally];
                            if (script_exists(scr_CastSkillField)) {
                                // Need to re-check MP for each target if it's a per-target cost, though field spells often have one cost.
                                // Assuming one cost deduction after all successful casts or one overall success.
                                // For simplicity here, we assume scr_CastSkillField handles internal checks if it returns success.
                                if (scr_CastSkillField(selected_caster_key, selected_spell, current_target_key)) {
                                    any_cast_successful = true;
                                }
                            }
                        }
                        if (any_cast_successful) {
                             if (is_struct(caster_data_struct)) { 
                                caster_data_struct.mp = max(0, caster_data_struct.mp - cost); 
                                ds_map_replace(global.party_current_stats, selected_caster_key, caster_data_struct);
                                show_debug_message("    -> Deducted MP for 'all_allies' spell. Caster MP now: " + string(caster_data_struct.mp));
                            }
                            // Play success sound once for "all allies" type
                            if (selected_spell.effect == "heal_hp" && audio_exists(snd_sfx_heal)) { audio_play_sound(snd_sfx_heal, 10, false); }
                        }
                        // Stay in spell_select or close menu, depending on design
                        // menu_state = "character_select"; // Option: go back to char select
                        // instance_destroy(); // Option: close menu
                        show_debug_message("  -> 'All Allies' spell processing complete. Staying in spell select.");
                    } 
                    else { 
                        show_debug_message("  -> Cannot use this spell target type ('" + targetType + "') outside battle in this manner."); 
                        // audio_play_sound(snd_menu_error, 0, false); // Example sound
                    }
                } else { 
                    show_debug_message("  -> MP Check FAILED (Have " + string(current_mp) + ", Need " + string(cost) + ")"); 
                    // audio_play_sound(snd_menu_error, 0, false); // Example sound
                }
            }
        } else { // No spells to select
            if (confirm_pressed) { 
                // audio_play_sound(snd_menu_error, 0, false); // Example sound
                show_debug_message("Spell Menu Field: Confirm pressed but no spells available/selected.");
            } 
        }

        // Handle Back/Cancel - Return to Character Select
        if (back_pressed) {
            show_debug_message("Spell Menu Field Spell Select: Back pressed. Returning to character select.");
            // audio_play_sound(snd_menu_cancel, 0, false); // Example sound
            menu_state = "character_select";
            usable_spells = []; 
            spell_index = 0; 
            selected_caster_key = ""; // Clear selected caster
        }
        break; 
        
    case "target_select_ally":
        var party_list_keys_target = global.party_members ?? []; // Use a different variable name
        var party_count_target = array_length(party_list_keys_target);
        if (party_count_target == 0) { 
            show_debug_message("Spell Menu Field Target: No party members to target. Returning to spell select.");
            menu_state = "spell_select"; 
            break; 
        } 
        target_party_index = clamp(target_party_index, 0, max(0, party_count_target - 1)); 

        if (up_pressed) { 
            target_party_index = (target_party_index - 1 + party_count_target) mod party_count_target; 
            // audio_play_sound(snd_menu_blip, 0, false); // Example sound
        }
        if (down_pressed) { 
            target_party_index = (target_party_index + 1) mod party_count_target; 
            // audio_play_sound(snd_menu_blip, 0, false); // Example sound
        }
        
        if (confirm_pressed) {
            if (spell_index < 0 || spell_index >= array_length(usable_spells)) {
                show_debug_message("ERROR: Invalid spell_index (" + string(spell_index) + ") in target_select_ally confirm!");
                menu_state = "spell_select"; // Go back if error
                break; 
            }
            var target_key = party_list_keys_target[target_party_index];
            var selected_spell_target = usable_spells[spell_index]; // Use a different variable name
            
            var caster_data_struct_target; // Renamed
            if (ds_map_exists(global.party_current_stats, selected_caster_key)) {
                 caster_data_struct_target = ds_map_find_value(global.party_current_stats, selected_caster_key);
            } else {
                 show_debug_message("  -> ERROR: Caster data not found for " + selected_caster_key + " in target_select_ally.");
                 menu_state = "character_select"; // Go back further
                 break;
            }

            var target_data_struct;
            if (ds_map_exists(global.party_current_stats, target_key)) {
                target_data_struct = ds_map_find_value(global.party_current_stats, target_key); 
            } else {
                 show_debug_message("  -> ERROR: Target data not found for " + target_key + " in target_select_ally.");
                 menu_state = "spell_select"; // Go back
                 break;
            }
            
            show_debug_message("Spell Menu Field Target: Confirmed target key '" + target_key + "' for spell '" + (selected_spell_target.name ?? "???") + "'");
            // audio_play_sound(snd_menu_select, 0, false); // Example sound
            
            var can_use_on_target = true; 
            if (!is_struct(target_data_struct)) { 
                can_use_on_target = false; 
                show_debug_message("    -> ERROR: Target persistent data invalid for " + target_key); 
            } else {
                var target_hp = variable_struct_get(target_data_struct, "hp") ?? 0;
                if (selected_spell_target.effect == "heal_hp" && target_hp <= 0) { 
                    can_use_on_target = false; 
                    show_debug_message("    -> Cannot use Heal on KO'd target: " + target_key); 
                }
                // Add other checks (Revive on living target, etc.)
            }

            if (can_use_on_target && script_exists(scr_CastSkillField)) {
                show_debug_message("    -> Attempting to call scr_CastSkillField (CasterKey=" + selected_caster_key + ", TargetKey=" + target_key + ")");
                var cast_success = scr_CastSkillField(selected_caster_key, selected_spell_target, target_key); 
                show_debug_message("    -> scr_CastSkillField returned: " + string(cast_success));
                
                if (cast_success) { 
                    if (selected_spell_target.effect == "heal_hp") { 
                        if (audio_exists(snd_sfx_heal)) { 
                            audio_play_sound(snd_sfx_heal, 10, false); 
                            show_debug_message("    -> Played heal sound (snd_sfx_heal).");
                        } else { show_debug_message("    -> WARNING: snd_sfx_heal asset missing!"); }
                    } 
                    // Add else if for other spell sounds here based on selected_spell_target.effect if needed
                    
                    var cost_target = selected_spell_target.cost ?? 0; // Renamed
                    if (is_struct(caster_data_struct_target)) { 
                        caster_data_struct_target.mp = max(0, caster_data_struct_target.mp - cost_target); 
                        ds_map_replace(global.party_current_stats, selected_caster_key, caster_data_struct_target);
                        show_debug_message("    -> Deducted MP. Caster MP now: " + string(caster_data_struct_target.mp));
                    } else { show_debug_message("    -> ERROR: Could not find caster data to deduct MP!"); }
                    
                    // Option: Close menu after successful cast on a single target
                    // show_debug_message("    -> Spell cast successfully. Closing menu.");
                    // instance_destroy();
                    // exit;
                } else { 
                    show_debug_message("    -> Spell use failed (check logs from scr_CastSkillField)."); 
                    // audio_play_sound(snd_menu_error, 0, false); // Example sound
                }
            } else if (!can_use_on_target) { 
                show_debug_message("    -> Spell cannot be used on target (check validation logs).");
                // audio_play_sound(snd_menu_error, 0, false); // Example sound
            } else if (!script_exists(scr_CastSkillField)) { 
                show_debug_message("    -> ERROR: scr_CastSkillField script missing!"); 
            }

            // Return to spell selection after attempt, regardless of success/failure, for now.
            // You might want to close the menu on success.
            menu_state = "spell_select";
            show_debug_message("    -> Returning to spell_select state.");
        } 
        
        if (back_pressed) {
            show_debug_message("Spell Menu Field Target: Back pressed. Returning to spell select.");
            // audio_play_sound(snd_menu_cancel, 0, false); // Example sound
            menu_state = "spell_select";
        }
        break; 
}
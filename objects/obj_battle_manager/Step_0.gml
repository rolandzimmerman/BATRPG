/// obj_battle_manager :: Step Event
// Manages the battle flow using a state machine based on the speed queue (using string states).

// Check for pause or critical failures
if (instance_exists(obj_pause_menu)) {
    exit; 
}
if (!ds_exists(combatants_all, ds_type_list)) { 
    show_debug_message("CRITICAL ERROR: combatants_all list missing in obj_battle_manager Step!");
    global.battle_state = "defeat"; // Or some error state that leads to game_end or cleanup
    alarm[0] = 1; // Trigger alarm to handle defeat/error state
    exit; 
}
if (!variable_global_exists("battle_state")) { 
    show_debug_message("CRITICAL ERROR: global.battle_state missing in obj_battle_manager Step!");
    global.battle_state = "defeat"; // Attempt recovery
    alarm[0] = 1; // Trigger alarm
    exit; 
}

// --- INPUT GATHERING FOR STATES THAT USE IT ---
// Gather these once if multiple states below might use them in the same step.
// Assuming player_index 0 for the active player controlling targeting.
var up_input_pressed = input_check_pressed(INPUT_ACTION.MENU_UP);
var down_input_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN);
var left_input_pressed = input_check_pressed(INPUT_ACTION.MENU_LEFT);   // Used in TargetSelectAlly
var right_input_pressed = input_check_pressed(INPUT_ACTION.MENU_RIGHT);  // Used in TargetSelectAlly
var confirm_input_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);
var cancel_input_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL);


switch (global.battle_state) {

    case "initializing":
        // This state is usually very brief, set in Create.
        // If it persists, there might be an issue, so a timeout can force it to the next state.
        if (get_timer() > room_speed * 2) { // Safety timeout (e.g., 2 seconds)
            show_debug_message("Battle Manager: Forcing state from 'initializing' to 'calculate_turn' due to timeout.");
            global.battle_state = "calculate_turn"; 
        }
        break;

    case "calculate_turn": 
    {
        show_debug_message("Manager Step: calculate_turn");
        // --- Cleanup dead/destroyed Instances from combatants_all --- 
        for (var i = ds_list_size(combatants_all) - 1; i >= 0; i--) { 
            var _inst_clean = combatants_all[| i];
            if (!instance_exists(_inst_clean)) { 
                ds_list_delete(combatants_all, i); 
                show_debug_message(" -> Removed destroyed instance " + string(_inst_clean) + " from combatants_all list.");
            }
            // Check for units that died but haven't processed death animation yet (e.g. from DOT)
            else if (variable_instance_exists(_inst_clean,"data") && is_struct(_inst_clean.data) && variable_struct_exists(_inst_clean.data,"hp") && _inst_clean.data.hp <= 0) {
                if(variable_instance_exists(_inst_clean,"combat_state") && _inst_clean.combat_state != "dying" && _inst_clean.combat_state != "dead" && _inst_clean.combat_state != "corpse") {
                    show_debug_message(" -> Found unprocessed dead combatant " + string(_inst_clean) + " (State: " + string(_inst_clean.combat_state) + ") during turn calc. Forcing to 'dying' if possible.");
                    // Optionally, force their state to dying here if they have that logic:
                    // _inst_clean.combat_state = "dying"; 
                    // Or just remove from active turn consideration for now by deleting from combatants_all
                    // ds_list_delete(combatants_all, i); // Be careful if they need to animate death
                } else if (!variable_instance_exists(_inst_clean,"combat_state")) {
                    // No combat state, assume dead units shouldn't act and might have been missed by cleanup
                     show_debug_message(" -> Found dead combatant " + string(_inst_clean) + " with no combat_state. Removing from combatants_all.");
                    ds_list_delete(combatants_all, i); 
                }
            }
        }
        
        // --- Check for immediate win/loss conditions ---
        var _party_alive = false; 
        var _enemies_alive = false;
        if (ds_exists(global.battle_party, ds_type_list)) { 
            for (var i=0; i<ds_list_size(global.battle_party); i++) {
                var p = global.battle_party[|i];
                if (instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && variable_struct_exists(p.data, "hp") && p.data.hp > 0) {
                    _party_alive = true; 
                    break;
                }
            }
        }
        if (ds_exists(global.battle_enemies, ds_type_list)) { 
            for (var i=0; i<ds_list_size(global.battle_enemies); i++) {
                var e = global.battle_enemies[|i];
                if (instance_exists(e) && variable_instance_exists(e,"data") && is_struct(e.data) && variable_struct_exists(e.data, "hp") && e.data.hp > 0) {
                    _enemies_alive = true; 
                    break;
                }
            }
        }

        if (!_enemies_alive && _party_alive) { global.battle_state = "victory"; alarm[0] = 1; break; } // Trigger victory sequence
        if (!_party_alive) { global.battle_state = "defeat"; alarm[0] = 1; break; }                  // Trigger defeat sequence
        if (!_enemies_alive && !_party_alive) { global.battle_state = "defeat"; alarm[0] = 1; break; } // Should ideally be caught by !party_alive

        // --- Determine next actor via speed queue ---
        var turn_result = (script_exists(scr_SpeedQueue))
                          ? scr_SpeedQueue(combatants_all, BASE_TICK_VALUE)
                          : { actor: noone, time_advance: 0 }; // Fallback if script missing
        currentActor = turn_result.actor;

        // Update turnOrderDisplay immediately after determining the next actor and advancing time
        if (script_exists(scr_CalculateTurnOrderDisplay)) {
            turnOrderDisplay = scr_CalculateTurnOrderDisplay(
                combatants_all,
                BASE_TICK_VALUE,
                TURN_ORDER_DISPLAY_COUNT
            );
            show_debug_message(" -> Updated turnOrderDisplay after speed queue.");
        }

        if (currentActor == noone || !instance_exists(currentActor)) { // Check if actor is valid
            show_debug_message(" -> No valid actor found by scr_SpeedQueue or instance destroyed. Re-checking win/loss.");
            currentActor = noone; // Ensure it's noone if invalid
            global.battle_state = "check_win_loss"; // Go to a state that re-evaluates win/loss
            break;
        }
         if (variable_instance_exists(currentActor,"data") && is_struct(currentActor.data) && (currentActor.data.hp ?? 0) <= 0) {
             show_debug_message(" -> Selected actor " + string(currentActor) + " is KO'd (HP: " + string(currentActor.data.hp) + "). Skipping turn, recalculating.");
             // This actor shouldn't have been chosen if dead; SpeedQueue or cleanup might need review.
             // For safety, reset its turn counter high or remove from consideration and recalc.
             if (script_exists(scr_ResetTurnCounter)) scr_ResetTurnCounter(currentActor, BASE_TICK_VALUE * 10); // Penalize heavily
             global.battle_state = "calculate_turn"; // Recalculate immediately
             break;
         }


        // --- Check for BIND (skip turn) ---
        var status_info = (script_exists(scr_GetStatus))
                          ? scr_GetStatus(currentActor)
                          : undefined; // Fallback
        if (is_struct(status_info) && (status_info.effect ?? "") == "bind") {
            show_debug_message(" -> Actor " + string(currentActor) + " (Name: " + string(currentActor.data.name ?? "N/A") + ") is bound and skips their turn.");
            // Optional: Show "Bound!" popup over the character
            global.battle_state = "action_complete"; // Skip to end of this actor's turn
            break;
        }

        // --- Normal flow: Player vs Enemy ---
        if (currentActor.object_index == obj_battle_player) {
            show_debug_message(" -> Next Actor is Player: " + string(currentActor) + " (Name: " + string(currentActor.data.name ?? "N/A") + ")");
            stored_action_data = undefined;
            selected_target_id = noone;

            var idx = ds_list_find_index(global.battle_party, currentActor);
            if (idx == -1) {
                show_debug_message("ERROR: Player actor " + string(currentActor) + " not in global.battle_party list! Skipping turn.");
                global.battle_state = "action_complete"; // Skip turn
            } else {
                global.active_party_member_index = idx;
                show_debug_message(" -> active_party_member_index = " + string(idx));
                global.battle_state = "player_input";
                show_debug_message(" -> battle_state changed to player_input");
            }
        } else { // Assuming any other actor is an enemy
            show_debug_message(" -> Next Actor is Enemy: " + string(currentActor) + " (Name: " + string(currentActor.data.name ?? "N/A") + ")");
            global.battle_state = "enemy_turn"; // This state will set up enemy AI and then likely go to ExecutingAction
            show_debug_message(" -> battle_state changed to enemy_turn");
        }
    }
    break;

    case "player_input": 
    case "skill_select": 
    case "item_select":
        // This state primarily waits for obj_battle_player to handle input and change global.battle_state.
        // We just check if the currentActor (active player) gets KO'd while it's their turn to choose.
        if (instance_exists(currentActor)) { 
            if (variable_instance_exists(currentActor,"data") && is_struct(currentActor.data) && (currentActor.data.hp ?? 0) <= 0) { 
                show_debug_message(" -> Player actor " + string(currentActor) + " KO'd while in input state ("+global.battle_state+"). Skipping turn.");
                global.battle_state = "action_complete"; 
            }
        } else if (global.battle_state == "player_input") { // If currentActor is gone specifically during player_input
            show_debug_message(" -> CurrentActor (player) missing during player_input state. Recalculating turn.");
            currentActor = noone; 
            global.battle_state = "calculate_turn";
        }
        break; 

    case "TargetSelect": 
    {
        show_debug_message("Manager Step: In TargetSelect State for Actor: " + string(currentActor)); 
        // --- Validations ---
        if (!instance_exists(currentActor) || stored_action_data == undefined) { 
            show_debug_message("TargetSelect: Actor/Action invalid. Recalculating turn."); 
            global.battle_state = "calculate_turn"; break; 
        }
        if (variable_instance_exists(currentActor,"data") && is_struct(currentActor.data) && (currentActor.data.hp ?? 0) <= 0) { 
            show_debug_message("TargetSelect: Actor " + string(currentActor) + " KO'd. Action complete."); 
            global.battle_state = "action_complete"; break; 
        }
        if (!variable_global_exists("battle_enemies") || !ds_exists(global.battle_enemies, ds_type_list) || ds_list_empty(global.battle_enemies)) { 
            show_debug_message("TargetSelect: No enemies to target. Returning to player input."); 
            global.battle_state = "player_input"; // Or previous menu if applicable
            break; 
        }
        var _enemy_count = ds_list_size(global.battle_enemies);
        global.battle_target = clamp(global.battle_target, 0, max(0, _enemy_count - 1)); // Ensure target index is valid

        // --- Use new input variables ---
        if (up_input_pressed) { 
            show_debug_message(" -> TargetSelect: Input UP detected."); 
            global.battle_target = (global.battle_target - 1 + _enemy_count) mod _enemy_count; 
            show_debug_message(" -> New Target Index: " + string(global.battle_target)); 
        } else if (down_input_pressed) { 
            show_debug_message(" -> TargetSelect: Input DOWN detected."); 
            global.battle_target = (global.battle_target + 1) % _enemy_count; 
            show_debug_message(" -> New Target Index: " + string(global.battle_target)); 
        } else if (confirm_input_pressed) { 
            show_debug_message(" -> TargetSelect: Input CONFIRM detected.");
            if (global.battle_target >= 0 && global.battle_target < _enemy_count) {
                var potential_target_id = global.battle_enemies[| global.battle_target]; // Use accessor for ds_list
                if (instance_exists(potential_target_id)) { // Check if instance itself exists
                    selected_target_id = potential_target_id; 
                    show_debug_message("     -> Potential Target Instance ID: " + string(selected_target_id));
                    if (variable_instance_exists(selected_target_id, "data") && is_struct(selected_target_id.data) && (selected_target_id.data.hp ?? 0) > 0) { 
                        show_debug_message("     -> Target instance " + string(selected_target_id) + " valid and alive. Setting state to ExecutingAction.");
                        global.battle_state = "ExecutingAction"; 
                    } else { 
                        show_debug_message("     -> Selected target instance " + string(selected_target_id) + " invalid or dead (HP: " + string(selected_target_id.data.hp ?? "N/A") + "). Resetting selection."); 
                        selected_target_id = noone; 
                        // Keep target cursor, let player re-confirm or cancel
                    }
                } else { 
                    show_debug_message("     -> ERROR: Instance at target index " + string(global.battle_target) + " (ID: " + string(potential_target_id) + ") does not exist. Resetting selection."); 
                    selected_target_id = noone; 
                    // Potentially remove from list if it's truly gone and shouldn't be selectable
                }
            } else { 
                show_debug_message(" -> ERROR: Invalid target index " + string(global.battle_target) + ". Resetting selection."); 
                selected_target_id = noone; global.battle_target = 0; 
            }
        } else if (cancel_input_pressed) { 
            show_debug_message(" -> TargetSelect: Input CANCEL detected.");
            // Return consumed item if action was an item
            if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle") && script_exists(scr_AddInventoryItem)) { 
                if (variable_struct_exists(stored_action_data, "item_key")) {
                    show_debug_message("    -> Cancelling item use, attempting to return item: " + string(stored_action_data.item_key));
                    scr_AddInventoryItem(stored_action_data.item_key, 1); // Add it back
                }
            }
            var _previous_menu_state = "player_input"; // Default
            if (is_struct(stored_action_data)) { 
                if (variable_struct_exists(stored_action_data,"usable_in_battle")) _previous_menu_state="item_select"; 
                else if (variable_struct_exists(stored_action_data,"effect")) _previous_menu_state="skill_select"; // Assuming skills have an 'effect' field
            }
            global.battle_ignore_b = true; // Tell player object to ignore this B press
            global.battle_state = _previous_menu_state; 
            stored_action_data = undefined; 
            selected_target_id = noone;
            show_debug_message("    -> Returned to state: " + _previous_menu_state);
        }
    }
    break; 
    
    case "TargetSelectAlly":
    {
        show_debug_message("Manager Step: In TargetSelectAlly State for Actor: " + string(currentActor)); 
        // --- Validations ---
        if (!instance_exists(currentActor) || stored_action_data == undefined) { show_debug_message("TargetSelectAlly: Actor/Action invalid. Recalculating."); global.battle_state = "calculate_turn"; break; }
        if (variable_instance_exists(currentActor,"data") && is_struct(currentActor.data) && (currentActor.data.hp ?? 0) <= 0) { show_debug_message("TargetSelectAlly: Actor KO'd. Action complete."); global.battle_state = "action_complete"; break; }
        if (!ds_exists(global.battle_party, ds_type_list) || ds_list_empty(global.battle_party)) { show_debug_message("TargetSelectAlly: Party list invalid. Returning to player input."); global.battle_state = "player_input"; break; } 
        
        var _party_count = ds_list_size(global.battle_party);
        if (!variable_global_exists("battle_ally_target")) global.battle_ally_target = global.active_party_member_index ?? 0; 
        global.battle_ally_target = clamp(global.battle_ally_target, 0, max(0, _party_count - 1));

        // --- Use new input variables ---
        // Note: TargetSelectAlly in original code used _left and _right for navigation.
        // MENU_UP and MENU_DOWN are typically for vertical lists.
        // If you want Up/Down for ally list, use up_input_pressed / down_input_pressed.
        // If you want Left/Right, use left_input_pressed / right_input_pressed.
        // Assuming Up/Down for vertical party list selection.
        var _nav_direction = 0;
        if (up_input_pressed) _nav_direction = -1;
        else if (down_input_pressed) _nav_direction = 1;
        // Or if using Left/Right for a horizontal party display:
        // if (left_input_pressed) _nav_direction = -1;
        // else if (right_input_pressed) _nav_direction = 1;


        if (_nav_direction != 0) { // Replaces (_left || _right) or (_up || _down)
            var _current_target_index = global.battle_ally_target; 
            var _new_target_index = _current_target_index;
            var _attempts = 0; 
            repeat(_party_count) { 
                _new_target_index = (_current_target_index + (_nav_direction * (_attempts + 1)) + _party_count * _party_count) mod _party_count; // ensure positive for mod
                var _check_inst = global.battle_party[| _new_target_index];
                var _can_target_this_ally = instance_exists(_check_inst); 
                if (_can_target_this_ally && is_struct(stored_action_data) && variable_instance_exists(_check_inst, "data") && is_struct(_check_inst.data)) {
                    var effect_type = stored_action_data.effect ?? "";
                    var target_hp = _check_inst.data.hp ?? -1;
                    if (effect_type == "heal_hp" && target_hp <= 0) { _can_target_this_ally = false; }
                    // else if (effect_type == "revive" && target_hp > 0) { _can_target_this_ally = false; }
                } else if (!_can_target_this_ally) { /* Instance doesn't exist, so cannot target */ }
                
                if (_can_target_this_ally) break; 
                _attempts++;
                if (_attempts >= _party_count) { _new_target_index = _current_target_index; break;} // Prevent infinite loop
            }
            global.battle_ally_target = _new_target_index; 
            show_debug_message(" -> TargetSelectAlly: Moved cursor to party index " + string(global.battle_ally_target));
        }
        // Handle Confirmation
        else if (confirm_input_pressed) { 
            show_debug_message(" -> TargetSelectAlly: Input CONFIRM detected.");
            if (global.battle_ally_target >= 0 && global.battle_ally_target < _party_count) {
                var potential_target_id = global.battle_party[| global.battle_ally_target]; 
                
                var _can_target_this_ally_on_confirm = instance_exists(potential_target_id);
                if (_can_target_this_ally_on_confirm && is_struct(stored_action_data) && variable_instance_exists(potential_target_id, "data") && is_struct(potential_target_id.data)) {
                    var effect_type_on_confirm = stored_action_data.effect ?? "";
                    var target_hp_on_confirm = potential_target_id.data.hp ?? -1;
                    if (effect_type_on_confirm == "heal_hp" && target_hp_on_confirm <= 0) { _can_target_this_ally_on_confirm = false;}
                    // Add more validation rules here based on action type
                } else if (!_can_target_this_ally_on_confirm) { /* Instance doesn't exist */ }

                if (_can_target_this_ally_on_confirm) { 
                    selected_target_id = potential_target_id; 
                    show_debug_message("     -> Ally target " + string(selected_target_id) + " confirmed. Setting state to ExecutingAction.");
                    global.battle_state = "ExecutingAction"; 
                } else { show_debug_message("     -> Selected ally " + string(potential_target_id) + " is not a valid target for this action."); /* Fail sound? */ }
            } else { show_debug_message("     -> Invalid ally target index: " + string(global.battle_ally_target)); selected_target_id = noone; }
        } 
        // Handle Cancellation
        else if (cancel_input_pressed) { 
            show_debug_message(" -> TargetSelectAlly: Input CANCEL detected.");
            var previous_menu_state_ally = "player_input"; 
            if (is_struct(stored_action_data)) {
                if (variable_struct_exists(stored_action_data, "usable_in_battle")) { previous_menu_state_ally = "item_select"; }
                else if (variable_struct_exists(stored_action_data, "effect")) { previous_menu_state_ally = "skill_select"; }
            }
            global.battle_ignore_b = true; // Tell player object to ignore this B press
            global.battle_state = previous_menu_state_ally; 
            stored_action_data = undefined; 
            selected_target_id = noone;
            show_debug_message("     -> Reset state to " + previous_menu_state_ally);
        }
    }
    break; 

    case "ExecutingAction": 
        show_debug_message("Manager: State ExecutingAction -> Actor: " + string(currentActor));
        if (instance_exists(currentActor)) {
            if (!variable_instance_exists(currentActor,"data") || !is_struct(currentActor.data) || (currentActor.data.hp ?? 0) <= 0) { 
                show_debug_message(" -> Actor " + string(currentActor) + " KO'd before action execution.");
                global.battle_state = "action_complete"; break; 
            } 

            var _action_data = stored_action_data; 
            var _target = selected_target_id;   
            var next_actor_state = "idle";   
            var _action_succeeded = false;     

            if (is_string(_action_data)) { 
                if (_action_data == "Attack") {
                    show_debug_message(" -> Executing: Basic Attack by " + string(currentActor.data.name ?? "Actor") + " on " + string(_target.data.name ?? "Target"));
                    if (script_exists(scr_PerformAttack)) {
                        _action_succeeded = scr_PerformAttack(currentActor, _target); 
                        if (_action_succeeded) next_actor_state = "attack_start"; 
                    } else { show_debug_message("ERROR: scr_PerformAttack missing!");}
                } else if (_action_data == "Defend") {
                    show_debug_message(" -> Executing: Defend by " + string(currentActor.data.name ?? "Actor"));
                    if (variable_instance_exists(currentActor,"data") && is_struct(currentActor.data)) currentActor.data.is_defending = true; 
                    _action_succeeded = true; 
                    next_actor_state = "idle"; 
                    global.battle_state = "action_complete"; 
                    break; 
                }
            } else if (is_struct(_action_data)) { 
                if (variable_struct_exists(_action_data, "usable_in_battle")) { // ITEM
                    show_debug_message(" -> Executing: Item Use (" + string(_action_data.name ?? "Item") + ") by " + string(currentActor.data.name ?? "Actor"));
                    if (script_exists(scr_UseItem)) {
                        _action_succeeded = scr_UseItem(currentActor, _action_data, _target); 
                        if (_action_succeeded) next_actor_state = "item_start"; 
                    } else { show_debug_message("ERROR: scr_UseItem missing!");}
                } 
                else if (variable_struct_exists(_action_data, "effect")) { // SKILL
                    show_debug_message(" -> Executing: Skill Cast (" + string(_action_data.name ?? "Skill") + ") by " + string(currentActor.data.name ?? "Actor"));
                    if (script_exists(scr_CastSkill)) {
                        _action_succeeded = scr_CastSkill(currentActor, _action_data, _target); 
                        if (_action_succeeded) { 
                            var anim_type = _action_data.animation_type ?? "magic";
                            if (anim_type == "physical") { next_actor_state = "attack_start"; } 
                            else { next_actor_state = "cast_start"; } 
                        }
                    } else { show_debug_message("ERROR: scr_CastSkill missing!");}
                }
            } else { show_debug_message(" -> ERROR: Unknown action type in ExecutingAction!"); }

            if (next_actor_state != "idle") {
                show_debug_message(" -> Telling actor " + string(currentActor) + " to start state '" + next_actor_state + "'");
                currentActor.stored_action_for_anim = _action_data; 
                currentActor.target_for_attack = _target;     
                currentActor.combat_state = next_actor_state; 
                
                current_attack_animation_complete = false; 
                global.battle_state = "waiting_for_animation"; 
                show_debug_message(" -> Manager state set to waiting_for_animation.");
            } else if (global.battle_state != "action_complete") { 
                show_debug_message(" -> Action has no animation or failed pre-animation. Proceeding to action_complete.");
                global.battle_state = "action_complete"; 
            }

        } else { 
            show_debug_message("ERROR: currentActor " + string(currentActor) + " invalid in ExecutingAction state!");
            global.battle_state = "calculate_turn"; 
        }
        break;

    case "enemy_turn": 
        show_debug_message(">>> MANAGER STATE: enemy_turn for Actor: " + string(currentActor) + " <<<"); 
        
        if (!instance_exists(currentActor) || !variable_instance_exists(currentActor,"data") || !is_struct(currentActor.data)) { 
            show_debug_message(" -> ERROR: Invalid enemy actor instance or missing data struct! Skipping turn."); 
            currentActor = noone; global.battle_state = "action_complete"; break; 
        }
        if ((currentActor.data.hp ?? 0) <= 0) { 
            show_debug_message(" -> Enemy " + string(currentActor.data.name ?? "N/A") + " already KO'd. Skipping turn.");
            global.battle_state = "action_complete"; break; 
        }
        
        show_debug_message(" -> " + string(currentActor.data.name ?? "Enemy") + " selecting target..."); 
        var _target_enemy_action = noone; var living_players_list = []; // Renamed
        if(ds_exists(global.battle_party, ds_type_list)){ 
            var party_list_size = ds_list_size(global.battle_party); // Renamed
            for(var k=0; k<party_list_size; k++){ 
                var p_inst = global.battle_party[|k]; // Renamed
                if(instance_exists(p_inst) && variable_instance_exists(p_inst,"data") && is_struct(p_inst.data) && (p_inst.data.hp ?? 0) > 0) { 
                    array_push(living_players_list,p_inst); 
                }
            }
        }
        if (array_length(living_players_list) > 0) { 
            _target_enemy_action = living_players_list[irandom(array_length(living_players_list)-1)]; 
            show_debug_message("     -> Enemy chose target: " + string(_target_enemy_action.data.name ?? "Player")); 
        } else { 
            show_debug_message(" -> Enemy has no valid player targets! Ending turn."); 
            global.battle_state = "action_complete"; break; 
        }

        show_debug_message(" -> " + string(currentActor.data.name ?? "Enemy") + " getting FX info..."); 
        var fx_info_enemy = { sprite: spr_pow, sound: snd_punch, element: "physical" }; // Renamed
        fx_info_enemy.sprite = currentActor.data.attack_sprite ?? spr_pow;
        fx_info_enemy.sound = currentActor.data.attack_sound ?? snd_punch;
        fx_info_enemy.element = currentActor.data.attack_element ?? "physical";
        if (!sprite_exists(fx_info_enemy.sprite)) { show_debug_message("WARN: Enemy attack sprite " + sprite_get_name(fx_info_enemy.sprite) + " missing!"); fx_info_enemy.sprite = spr_pow; }
        if (!audio_exists(fx_info_enemy.sound)) { show_debug_message("WARN: Enemy attack sound " + audio_get_name(fx_info_enemy.sound) + " missing!"); fx_info_enemy.sound = snd_punch; }
        show_debug_message("     -> Enemy FX Info: Sprite=" + sprite_get_name(fx_info_enemy.sprite) + ", Sound=" + audio_get_name(fx_info_enemy.sound) + ", Element=" + fx_info_enemy.element); 
        
        // --- ENEMY ACTION LOGIC ---
        // For now, enemies only do a basic attack.
        // TODO: Implement scr_EnemyChooseAction(currentActor) to select between Attack, Skills, etc.
        // For now, we assume "Attack" and that scr_PerformAttack will be used by the enemy's "attack_start" state.
        var _enemy_action_chosen = "Attack"; // Placeholder
        
        if (instance_exists(currentActor) && instance_exists(_target_enemy_action)) {
            show_debug_message(" -> Telling enemy actor " + string(currentActor.data.name ?? "Enemy") + " to start combat_state 'attack_start' targeting " + string(_target_enemy_action.data.name ?? "Player") + "."); 
            currentActor.target_for_attack = _target_enemy_action;
            currentActor.attack_fx_sprite = fx_info_enemy.sprite; // Pass the determined FX sprite
            currentActor.attack_fx_sound = fx_info_enemy.sound;   // Pass the determined FX sound
            currentActor.stored_action_for_anim = _enemy_action_chosen; // For enemy, this might be a skill struct or "Attack" string
            currentActor.combat_state = "attack_start"; // Or "cast_start" if it's a spell
            
            show_debug_message(" -> Setting manager state to 'waiting_for_animation'."); 
            global.battle_state = "waiting_for_animation"; 
            current_attack_animation_complete = false;
            show_debug_message(" -> Manager state is now: " + global.battle_state); 
        } else {
            show_debug_message(" -> ERROR: Enemy attacker or target became invalid before triggering animation! Skipping turn."); 
            global.battle_state = "action_complete"; 
        }
        break;
        
    case "waiting_for_animation": 
        // show_debug_message("Manager State: waiting_for_animation (Actor: " + string(currentActor) +")"); // Can be spammy
        if (current_attack_animation_complete) {
            show_debug_message("Manager: Animation complete signal received from Actor " + string(currentActor) ); 
            current_attack_animation_complete = false; 
            global.battle_state = "action_complete"; 
        }
        break;

    case "action_complete": 
    {
        show_debug_message("Manager Step: action_complete for Actor: " + string(currentActor)); 
        if (instance_exists(currentActor)) {
            if (variable_instance_exists(currentActor,"data") && is_struct(currentActor.data) && (currentActor.data.is_defending ?? false)) { 
                currentActor.data.is_defending = false; 
                show_debug_message(" -> Resetting Defend status for " + string(currentActor.data.name ?? "Actor")); 
            }
            if (script_exists(scr_ResetTurnCounter)) { 
                scr_ResetTurnCounter(currentActor, BASE_TICK_VALUE); 
                show_debug_message(" -> Reset turn counter for " + string(currentActor.data.name ?? "Actor"));
            } 
        } else { show_debug_message(" -> Actor " + string(currentActor) + " no longer exists during action_complete."); }
        
        stored_action_data = undefined; 
        selected_target_id = noone; 
        global.active_party_member_index = -1; // No player is actively taking a turn now

        show_debug_message(" -> Transitioning from action_complete to check_win_loss"); 
        global.battle_state = "check_win_loss"; 
    }
    break; 
            
    case "check_win_loss": 
    {
        show_debug_message("Manager Step: In check_win_loss State");
        
        // Cleanup and check dead enemies, accumulate XP
        if (ds_exists(global.battle_enemies, ds_type_list)) {
            for (var i = ds_list_size(global.battle_enemies) - 1; i >= 0; i--) {
                var e_id_check = global.battle_enemies[| i]; // Renamed
                if (instance_exists(e_id_check)) {
                    if (variable_instance_exists(e_id_check, "data") && is_struct(e_id_check.data) && (e_id_check.data.hp ?? 1) <= 0) {
                        if (!variable_instance_exists(e_id_check, "xp_counted") || !e_id_check.xp_counted) { // Count XP only once
                            total_xp_from_battle += (e_id_check.data.xp ?? 0);
                            e_id_check.xp_counted = true; // Mark as counted
                            show_debug_message(" -> Accumulated " + string(e_id_check.data.xp ?? 0) + " XP from " + string(e_id_check.data.name ?? "Enemy") + ". Total XP: " + string(total_xp_from_battle));
                        }
                        // Ensure death processing is triggered if not already in dying/dead state
                        if (variable_instance_exists(e_id_check, "combat_state") && e_id_check.combat_state != "dying" && e_id_check.combat_state != "dead" && e_id_check.combat_state != "corpse") {
                             if (script_exists(scr_ProcessDeathIfNecessary)) scr_ProcessDeathIfNecessary(e_id_check); else e_id_check.combat_state = "dying"; // Fallback
                        }
                    }
                } else { // Instance does not exist, remove from lists
                    ds_list_delete(global.battle_enemies, i);
                    var combatant_idx = ds_list_find_index(combatants_all, e_id_check);
                    if (combatant_idx != -1) ds_list_delete(combatants_all, combatant_idx);
                    show_debug_message(" -> Removed missing enemy instance " + string(e_id_check) + " from battle lists during check_win_loss.");
                }
            }
        }

        // Check party members' status (no need to remove from global.battle_party, just check if any are alive)
        var any_party_member_alive = false; // Renamed
        if (ds_exists(global.battle_party, ds_type_list)) {
            for (var i = 0; i < ds_list_size(global.battle_party); i++) {
                var p_id_check = global.battle_party[| i]; // Renamed
                if (instance_exists(p_id_check) && variable_instance_exists(p_id_check, "data") && is_struct(p_id_check.data) && (p_id_check.data.hp ?? 0) > 0) {
                    any_party_member_alive = true;
                    break; 
                }
            }
        }

        // Check if any enemies are still considered "alive" (HP > 0 and in the list)
        var any_targetable_enemies_alive = false; // Renamed
        if (ds_exists(global.battle_enemies, ds_type_list)) {
             for (var i=0; i<ds_list_size(global.battle_enemies); i++) {
                var e_check = global.battle_enemies[|i]; // Renamed
                if (instance_exists(e_check) && variable_instance_exists(e_check,"data") && is_struct(e_check.data) && (e_check.data.hp ?? 0) > 0) {
                    any_targetable_enemies_alive = true; 
                    break;
                }
            }
        }
        
        currentActor = noone; // No actor is currently taking a turn during this check

        // --- Determine Battle Outcome ---
        if (!any_targetable_enemies_alive && any_party_member_alive) {
            show_debug_message(" -> Outcome: Victory! Setting alarm for victory sequence.");
            global.battle_state = "victory";
            alarm[0] = 60; // Delay before processing victory (e.g., for last death animations)
        } else if (!any_party_member_alive) {
            show_debug_message(" -> Outcome: Defeat! Setting alarm for defeat sequence.");
            global.battle_state = "defeat";
            alarm[0] = 60; // Delay before processing defeat
        } else { // Battle continues
            show_debug_message(" -> Outcome: Battle Continues. Calculating next turn.");
            // Ensure battle_target is valid if there are still enemies
            if (!any_targetable_enemies_alive) {
                global.battle_target = -1; // No valid targets
            } else {
                global.battle_target = clamp(global.battle_target, 0, max(0, ds_list_size(global.battle_enemies) - 1));
            }
            global.battle_state = "calculate_turn"; // Loop back to calculate next turn
        }
        show_debug_message(" -> Exiting check_win_loss. Next state: " + global.battle_state);
    }
    break;

    case "victory":
    case "defeat":
    case "return_to_field":
    case "show_levelup": // Added this state if it's used by Alarm[0] for level up popups
        // These states are primarily handled by Alarm[0] or transition from it.
        // The Step event might handle continuous effects like fading for "defeat".
        if (global.battle_state == "defeat" && fade_fading) {
            fade_alpha = min(1.0, fade_alpha + fade_speed); // Ensure fade_alpha doesn't exceed 1
            // The actual room_goto to rm_game_over is in Alarm[0] after fade completes
        }
        if (global.battle_state == "show_levelup") {
            // Waiting for obj_levelup_popup to handle itself and advance global.battle_levelup_index
            // or set state to "return_to_field"
            // This manager just waits. If obj_levelup_popup gets stuck, this could be an issue.
            // Consider a timeout here if necessary.
        }
        break;

    default:
        show_debug_message("WARNING [obj_battle_manager Step]: Reached default switch case with unknown battle_state: " + string(global.battle_state));
        global.battle_state = "calculate_turn"; // Attempt to recover
        break;
} // End Switch

// --- Screen Flash Logic (remains unchanged from your provided code) ---
if (screen_flash_timer > 0) { 
    screen_flash_timer -= 1;
    var fade_in_duration = max(1, floor(screen_flash_duration * 0.2)); 
    if (screen_flash_timer > screen_flash_duration - fade_in_duration) {
        var progress = 1 - ((screen_flash_timer - (screen_flash_duration - fade_in_duration)) / max(1, fade_in_duration)); 
        screen_flash_alpha = lerp(0, screen_flash_peak_alpha, progress);
    } else {
        screen_flash_alpha = max(0, screen_flash_alpha - screen_flash_fade_speed); 
    }
    screen_flash_alpha = clamp(screen_flash_alpha, 0, screen_flash_peak_alpha); 
} else { 
    screen_flash_alpha = max(0, screen_flash_alpha - screen_flash_fade_speed * 2); 
}

// --- Defeat Fade Handling (already partially covered in the "defeat" case) ---
// This is redundant if already in the defeat case, but ensures fade continues if state is defeat.
if (global.battle_state == "defeat" && fade_fading) {
    // fade_alpha is already being incremented above.
    // Alarm[0] will handle the room_goto when fade_alpha is >= 1.
}

show_debug_message("--- End of obj_battle_manager Step Event --- (State: " + global.battle_state + ")");
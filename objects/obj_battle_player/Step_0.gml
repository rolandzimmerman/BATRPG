/// obj_battle_player :: Step Event
/// Handles player input processing AND combat animation state machine.
/// 
// — AUTO‐TRIGGER PLAYER DEATH —
if (variable_instance_exists(id, "data")
 && is_struct(data)
 && data.hp <= 0
 && combat_state != "dying"
 && combat_state != "idle"
 && combat_state != "corpse"
 && combat_state != "dead") {
    death_started = false;       // reset the flag
    combat_state    = "dying";   // enter your dying logic
    show_debug_message("Player " + string(id) + " entering dying state");
    show_debug_message(
      (object_index == obj_battle_player ? "Player " : "Enemy ")
      + string(id)
      + " entering dying state"
    );
}


// --- One-Time Sprite Assignment --- 
if (!variable_instance_exists(id, "sprite_assigned") || !sprite_assigned) { 
    if (variable_instance_exists(id, "data") && is_struct(data)) { 
        if (variable_struct_exists(data, "character_key")) {
            var _char_key = data.character_key;
            show_debug_message("Attempting sprite assignment for key: " + _char_key);
            var base_char_info = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_char_key) : undefined; 
            
            if (is_struct(base_char_info)) {
                 var base_scale = 1.0; 
                 if (variable_global_exists("party_positions") && is_array(global.party_positions) && variable_instance_exists(id,"party_slot_index") && party_slot_index >= 0 && party_slot_index < array_length(global.party_positions)) { base_scale = global.party_positions[party_slot_index][2] ?? 1.0; }
                 image_xscale = base_scale; image_yscale = base_scale; original_scale = base_scale; 
                 
                 // --- Get Sprites ---
                 idle_sprite = variable_struct_get(base_char_info,"battle_sprite") ?? sprite_index;
                 attack_sprite_asset = variable_struct_get(base_char_info,"attack_sprite") ?? idle_sprite;
                 casting_sprite_asset = variable_struct_get(base_char_info,"cast_sprite") ?? idle_sprite; // Assign casting sprite
                 // --- <<< ADDED MISSING ASSIGNMENT for Item Sprite >>> ---
                 item_sprite_asset = variable_struct_get(base_char_info,"item_sprite") ?? idle_sprite; // Assign item sprite, fallback to idle
                 // --- <<< END ADDED ASSIGNMENT >>> ---
                 sprite_index = idle_sprite; 
                 sprite_before_attack = idle_sprite; 
                 
                 // Get FX/Sound Defaults
                 attack_fx_sprite = variable_struct_get(base_char_info,"attack_fx_sprite") ?? spr_pow; 
                 attack_fx_sound = variable_struct_get(base_char_info,"attack_sound") ?? snd_punch;

                 show_debug_message("    -> Assigned Sprites: Idle=" + sprite_get_name(idle_sprite) + 
                                    ", Attack=" + sprite_get_name(attack_sprite_asset) + 
                                    ", Cast=" + sprite_get_name(casting_sprite_asset)); 

            } else { 
                 idle_sprite = sprite_index; attack_sprite_asset = idle_sprite; casting_sprite_asset = idle_sprite;
                 attack_fx_sprite = spr_pow; attack_fx_sound = snd_punch;
                 original_scale = image_xscale; 
                 show_debug_message(" -> WARNING: Failed to get base_char_info, using default sprites.");
            }
            
            image_index = 0; image_speed = 1; 
            sprite_assigned = true; 
            show_debug_message("Player " + string(id) + " Sprites Initialized & Assigned."); 
        } else { /* Missing character_key */ }
    } else { /* Data not assigned yet */ }
} 

// --- Player INPUT Handling (Only if it's my turn and in an input state) ---
if (variable_global_exists("active_party_member_index")
 && variable_global_exists("battle_state")
 && variable_instance_exists(id, "data") && is_struct(data)
 && variable_struct_exists(data, "party_slot_index") 
 && data.party_slot_index == global.active_party_member_index) // Is it my turn?
{
    var st = global.battle_state; // Get current manager state
    
    // Check if we are in a state where this player should process input
    // The player_index for input functions defaults to 0, which is fine if this object
    // always represents the player whose turn it is and uses the first mapped gamepad.
    if (st == "player_input" || st == "skill_select" || st == "item_select") {
        var d = data; // Shortcut to my data

        // Read Inputs using the new system
        var confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);
        var cancel_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL);
        var skill_menu_pressed = input_check_pressed(INPUT_ACTION.MENU_SKILL);
        var item_menu_pressed = input_check_pressed(INPUT_ACTION.MENU_ITEM);
        var up_pressed = input_check_pressed(INPUT_ACTION.MENU_UP);
        var down_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN);

        // Handle flag for ignoring cancel after target selection
        if (variable_global_exists("battle_ignore_b") && global.battle_ignore_b) {
            if (cancel_pressed) { // Check if it was the cancel button specifically
                 cancel_pressed = false; // Ignore this specific press
            }
            global.battle_ignore_b = false; // Clear flag
        }
        
        // Process based on Manager's State (global.battle_state)
        switch (st) {
            case "player_input":
                var hasEnemies = ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0;
                if (confirm_pressed && hasEnemies) { // Attack selected
                    if (!instance_exists(obj_battle_manager)) break; 
                    obj_battle_manager.stored_action_data = "Attack";
                    global.battle_target = 0; 
                    global.battle_state  = "TargetSelect"; 
                    show_debug_message(" -> Action Selected: Attack -> TargetSelect");
                }
                else if (cancel_pressed) { // Defend selected
                    if (!instance_exists(obj_battle_manager)) break; 
                    obj_battle_manager.stored_action_data  = "Defend";
                    obj_battle_manager.selected_target_id  = noone; 
                    global.battle_state = "ExecutingAction"; 
                    show_debug_message(" -> Action Selected: Defend -> ExecutingAction");
                }
                else if (skill_menu_pressed) { // Skills menu selected
                    show_debug_message("Player " + string(d.name) + " selected Skills command.");
                    if (!variable_struct_exists(d, "skill_index")) {
                        d.skill_index = 0;
                    } else {
                        d.skill_index = 0; // Always reset to top
                    }
                    global.battle_state = "skill_select";
                    show_debug_message(" -> Action Selected: Skills. Transitioning to global state: skill_select");
                }
                else if (item_menu_pressed) { // Items menu selected
                    global.battle_usable_items = []; 
                    var inv = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];
                    for (var i_item = 0; i_item < array_length(inv); i_item++) {
                        var inv_entry = inv[i_item];
                        if (!is_struct(inv_entry) || !variable_struct_exists(inv_entry,"item_key") || !variable_struct_exists(inv_entry,"quantity") || inv_entry.quantity <= 0) continue;
                        var it_key = inv_entry.item_key;
                        var it_data = scr_GetItemData(it_key); 
                        if (is_struct(it_data) && (it_data.usable_in_battle ?? false) ) { 
                            array_push(global.battle_usable_items, { item_key: it_key, quantity: inv_entry.quantity, name: it_data.name ?? "???" }); 
                        }
                    }
                    if (array_length(global.battle_usable_items) > 0) {
                        if (!variable_struct_exists(d, "item_index")) d.item_index = 0; 
                        d.item_index = clamp(d.item_index, 0, max(0, array_length(global.battle_usable_items) - 1)); 
                        global.battle_state = "item_select"; 
                        show_debug_message(" -> Action Selected: Items -> item_select");
                    } else { 
                        show_debug_message(" -> Action Selected: Items (No usable items available)");
                    }
                }
                break; // End "player_input" case

            case "skill_select":
                // Prepare display_skills (this logic remains the same)
                show_debug_message("DEBUG skill_select (Player Step): Active battler " + string(data.character_key) + " preparing display_skills.");
                var key_list_from_data = (variable_struct_exists(data,"skills") && is_array(data.skills)) ? data.skills : [];
                display_skills = []; 
                for (var i_skill = 0; i_skill < array_length(key_list_from_data); i_skill++) {
                    var s_struct = key_list_from_data[i_skill];
                    if(!is_struct(s_struct) || !variable_struct_exists(s_struct, "name")){
                        continue;
                    }
                    var can_display_skill = true;
                    if (variable_struct_exists(s_struct, "unlock_item")) {
                        if (!scr_HaveItem(s_struct.unlock_item, 1)) {
                            can_display_skill = false;
                        }
                    }
                    if (can_display_skill) {
                        array_push(display_skills, s_struct);
                    }
                }
                // Input handling for navigating the display_skills list
                var _display_count_skill = array_length(display_skills);
                if (_display_count_skill > 0) {
                    data.skill_index = clamp(data.skill_index, 0, max(0, _display_count_skill - 1));
                    if (up_pressed) {
                        data.skill_index = (data.skill_index - 1 + _display_count_skill) % _display_count_skill;
                    }
                    if (down_pressed) {
                        data.skill_index = (data.skill_index + 1) % _display_count_skill;
                    }
                    if (confirm_pressed) {
                        var selected_skill_struct_confirm = display_skills[data.skill_index];
                        var can_afford_selected_confirm = true;
                        var skill_cost_confirm = selected_skill_struct_confirm.cost ?? 0;
                        if (variable_struct_exists(selected_skill_struct_confirm, "overdrive") && selected_skill_struct_confirm.overdrive) {
                            can_afford_selected_confirm = (data.overdrive >= (data.overdrive_max ?? 100));
                        } else {
                            can_afford_selected_confirm = (data.mp >= skill_cost_confirm);
                        }
                        if (can_afford_selected_confirm) {
                            if (instance_exists(obj_battle_manager)) {
                                obj_battle_manager.stored_action_data = selected_skill_struct_confirm;
                                var target_type_confirm = selected_skill_struct_confirm.target_type ?? "enemy";
                                if (target_type_confirm == "enemy" || target_type_confirm == "all_enemies") {
                                    global.battle_target = 0; 
                                    global.battle_state = "TargetSelect";
                                } else if (target_type_confirm == "ally" || target_type_confirm == "all_allies" || target_type_confirm == "self") {
                                    global.battle_ally_target = global.active_party_member_index ?? 0; 
                                    global.battle_state = "TargetSelectAlly";
                                } else { 
                                    global.battle_target = 0;
                                    global.battle_state = "TargetSelect";
                                }
                            }
                        } else { /* Play "cannot afford" sound */ }
                    }
                } else { 
                    if (confirm_pressed) { /* Optional: Play "buzz" or do nothing */ }
                }
                if (cancel_pressed) {
                    global.battle_state = "player_input";
                }
                break; // End of case "skill_select"

            case "item_select":
                var items_nav = global.battle_usable_items ?? []; 
                var count_items_nav = array_length(items_nav);
                if (count_items_nav > 0) {
                    data.item_index = clamp(data.item_index, 0, max(0, count_items_nav - 1));
                    if (up_pressed) data.item_index = (data.item_index - 1 + count_items_nav) % count_items_nav;
                    if (down_pressed) data.item_index = (data.item_index + 1) % count_items_nav;
                    
                    if (confirm_pressed && instance_exists(obj_battle_manager)) { 
                        var item_info_nav = items_nav[data.item_index]; 
                        var item_data_nav = scr_GetItemData(item_info_nav.item_key); 
                        
                        if (is_struct(item_data_nav)) {
                            obj_battle_manager.stored_action_data = item_data_nav; 
                            var itemTargetType_nav = item_data_nav.target ?? "enemy"; 
                            if (itemTargetType_nav == "enemy") {
                                global.battle_target = 0; 
                                global.battle_state  = "TargetSelect"; 
                            } 
                            else if (itemTargetType_nav == "ally") {
                                global.battle_ally_target = global.active_party_member_index ?? 0; 
                                global.battle_state = "TargetSelectAlly"; 
                            } 
                            else if (itemTargetType_nav == "self" || itemTargetType_nav == "all_allies" || itemTargetType_nav == "all_enemies") {
                                obj_battle_manager.selected_target_id = (itemTargetType_nav == "self") ? id : noone; 
                                global.battle_state  = "ExecutingAction"; 
                            } 
                            else { 
                                global.battle_target = 0; global.battle_state  = "TargetSelect"; 
                            }
                        }
                    }
                } else { // No items
                    if (confirm_pressed) { /* Optional: Play "buzz" sound */ }
                }
                if (cancel_pressed) { 
                    global.battle_usable_items = []; 
                    global.battle_state = "player_input";
                } 
                break; // End "item_select" case
        } // End input state switch (global.battle_state)
    } // End if correct state for input
} // End if my turn 


// --- Combat Animation State Machine ---
if (combat_state == "idle") { origin_x = x; origin_y = y; original_scale = image_xscale; }
switch (combat_state) {
    case "idle":
        if (sprite_index != idle_sprite) { sprite_index = idle_sprite; image_index = 0; }
        if (image_xscale != original_scale) { image_xscale = original_scale; image_yscale = original_scale; }
        if (image_speed != 0) image_speed = 1; 
        break;

    // --- Physical Attack / Physical Skill Animation ---
    case "attack_start": 
        show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> attack_start (Physical)...");
        origin_x = x; origin_y = y; 
        sprite_before_attack = idle_sprite; 
        if (sprite_exists(attack_sprite_asset)) { sprite_index = attack_sprite_asset; } else { sprite_index = idle_sprite; } 
        image_index = 0; image_speed = attack_anim_speed; 
        
        // --- Determine TARGET FX based on Action (Attack or Physical Skill) ---
        var current_fx_sprite = spr_pow; var current_fx_sound = snd_punch; 
        if (stored_action_for_anim == "Attack") { // Basic Attack uses weapon FX
             if (script_exists(scr_GetWeaponAttackFX)) { var weapon_fx = scr_GetWeaponAttackFX(id); current_fx_sprite = weapon_fx.sprite; current_fx_sound = weapon_fx.sound; }
        } else if (is_struct(stored_action_for_anim)) { // Physical Skill uses skill's FX
             current_fx_sprite = stored_action_for_anim.fx_sprite ?? spr_pow;
             current_fx_sound = stored_action_for_anim.fx_sound ?? snd_punch;
        }
        
        // --- Calculate Position & Match Scale ---
        var _target_x = origin_x; var _target_y = origin_y; 
        var target_exists = instance_exists(target_for_attack);
        if (target_exists) { _target_x = target_for_attack.x; _target_y = target_for_attack.y; } 
        var _offset_dist = 192; 
        var _dir_to_target = point_direction(x, y, _target_x, _target_y);
        var _move_to_x = _target_x - lengthdir_x(_offset_dist, _dir_to_target);
        var _move_to_y = _target_y - lengthdir_y(_offset_dist, _dir_to_target);
        if (target_exists) { image_xscale = target_for_attack.image_xscale; image_yscale = target_for_attack.image_yscale;}
        
        // --- Teleport ---
        x = _move_to_x; y = _move_to_y; 
        if (audio_exists(current_fx_sound)) audio_play_sound(current_fx_sound, 10, false); // Play sound at start of anim
        
        // --- Create TARGET Visual Effect ---
        // NOTE: Effect (damage etc) was ALREADY APPLIED by the manager
        if (target_exists) { 
             if (object_exists(obj_attack_visual)) {
                 var _fx_x = target_for_attack.x; var _fx_y = target_for_attack.y - 32; 
                 var _layer_id = layer_get_id("Instances_FX"); 
                 if (_layer_id != -1) { 
                     var fx = instance_create_layer(_fx_x, _fx_y, _layer_id, obj_attack_visual); 
                     if (instance_exists(fx)) {
                          fx.sprite_index = current_fx_sprite; fx.image_speed = attack_anim_speed;
                          fx.depth = target_for_attack.depth - 1; fx.owner_instance = id; 
                          attack_animation_finished = false; // Wait for this FX
                     } else { attack_animation_finished = true; } 
                 } else { attack_animation_finished = true; } 
             } else { attack_animation_finished = true; } 
        } else { attack_animation_finished = true; } // Target doesn't exist, finish immediately

        combat_state = "waiting_for_effect"; 
        break; 

    // --- Magic Casting Animation ---
/// obj_battle_player :: Step Event (replace your cast_start case with this)
case "cast_start":
    // Log entry
    show_debug_message("obj_battle_player " + string(id) + ": State -> cast_start (Magic)");

    // 1) Prepare casting pose
    origin_x = x;
    origin_y = y;
    sprite_before_attack = idle_sprite;
    if (sprite_exists(casting_sprite_asset)) {
        sprite_index = casting_sprite_asset;
    } else {
        sprite_index = idle_sprite;
    }
    image_index = 0;
    image_speed = attack_anim_speed;

    // 2) Retrieve character info (contains cast_fx_sprite)
    var info = scr_FetchCharacterInfo(character_key);
    if (!is_struct(info)) {
        show_debug_message("❌ ERROR: scr_FetchCharacterInfo returned undefined for '" + character_key + "'");
    }

    // 3) Select the FX sprite
    var caster_fx = spr_caster_glow;
    if (is_struct(info) && sprite_exists(info.cast_fx_sprite)) {
        caster_fx = info.cast_fx_sprite;
    }
    show_debug_message("    → Using cast FX sprite: " 
                     + string(caster_fx)
                     + " (" + sprite_get_name(caster_fx) + ")");

    // 4) Play the skill’s sound
    var skill_struct = stored_action_for_anim;
    var sfx = snd_punch;
    if (is_struct(skill_struct) && variable_struct_exists(skill_struct, "fx_sound")) {
        sfx = skill_struct.fx_sound;
    }
    if (audio_exists(sfx)) audio_play_sound(sfx, 10, false);

    // 5) Spawn the caster visual effect
    if (object_exists(obj_caster_visual)) {
        var lid = layer_get_id("Instances_FX");
        if (lid != -1) {
            var fx = instance_create_layer(x, y - 48, lid, obj_caster_visual);
            if (instance_exists(fx)) {
                fx.sprite_index = caster_fx;
                fx.image_speed  = attack_anim_speed;
                fx.depth        = depth - 1;
            }
        }
    }

    // 6) Spawn the target visual effect (unchanged)
    var target_fx_sp = spr_pow;
    if (is_struct(skill_struct) && variable_struct_exists(skill_struct, "fx_sprite")) {
        target_fx_sp = skill_struct.fx_sprite;
    }
    if (instance_exists(target_for_attack) && object_exists(obj_attack_visual)) {
        var lid2 = layer_get_id("Instances_FX");
        var fxt  = instance_create_layer(
            target_for_attack.x,
            target_for_attack.y - 32,
            lid2,
            obj_attack_visual
        );
        if (instance_exists(fxt)) {
            fxt.sprite_index   = target_fx_sp;
            fxt.image_speed    = attack_anim_speed;
            fxt.depth          = target_for_attack.depth - 100;
            fxt.owner_instance = id;
        } else {
            attack_animation_finished = true;
        }
    } else {
        attack_animation_finished = true;
    }

    // 7) Advance to waiting state
    combat_state = "waiting_for_effect";
    break;






        case "item_select":
             var items = global.battle_usable_items ?? []; var c = array_length(items);
              if (c > 0) {
                  // Navigation
                  if (U) d.item_index = (d.item_index - 1 + c) mod c;
                  if (D) d.item_index = (d.item_index + 1) mod c;
                  
                  // Confirm Selection
                  if (A && instance_exists(obj_battle_manager)) { 
                      var item_info = items[d.item_index]; 
                      var item_data = scr_GetItemData(item_info.item_key); 
                      
                      if (is_struct(item_data)) {


                          obj_battle_manager.stored_action_data = item_data; // Store item definition struct
                          
                          // --- Determine Next State based on Item Target ---
                          var itemTargetType = item_data.target ?? "enemy"; // Get target type, default to enemy
                           show_debug_message(" -> Item '" + (item_data.name ?? "???") + "' selected. Target Type: " + itemTargetType);

                           if (itemTargetType == "enemy") {
                               global.battle_target = 0; // Reset enemy cursor
                               global.battle_state  = "TargetSelect"; 
                               show_debug_message("    -> Transitioning to TargetSelect (Enemy)");
                           } 
                           else if (itemTargetType == "ally") {
                               global.battle_ally_target = global.active_party_member_index ?? 0; // Start cursor on self
                               global.battle_state = "TargetSelectAlly"; // <<< USE ALLY TARGETING STATE
                               show_debug_message("    -> Transitioning to TargetSelectAlly");
                           } 
                           else if (itemTargetType == "self" || itemTargetType == "all_allies" || itemTargetType == "all_enemies") {
                               obj_battle_manager.selected_target_id = (itemTargetType == "self") ? id : noone; // Target self or no specific instance for 'all' types
                               global.battle_state  = "ExecutingAction"; 
                               show_debug_message("    -> " + itemTargetType + " target item. Transitioning to ExecutingAction");
                           } 
                           else { // Default for unknown types
                                show_debug_message("    -> Unknown item target_type '" + itemTargetType + "'. Defaulting to Enemy TargetSelect.");
                                global.battle_target = 0; 
                                global.battle_state  = "TargetSelect"; 
                           }
                          // --- End Item Target Type Check ---

                      } else { show_debug_message("ERROR: Invalid item data for key: " + item_info.item_key); }
                  } // End Confirm (A)
              } // End if c > 0
              
              // Cancel/Back
              if (B) { global.battle_usable_items = []; global.battle_state = "player_input"; show_debug_message(" -> Cancelled Item Select -> player_input");} 
              
              break; // End "item_select" case
    // --- <<< NEW: Item Usage Animation >>> ---
case "item_start":
    show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> item_start ...");
    origin_x = x; origin_y = y; 
    sprite_before_attack = idle_sprite; 

    // Set player to your item‐use pose
    if (sprite_exists(item_sprite_asset)) {
        sprite_index = item_sprite_asset;
    } else {
        sprite_index = idle_sprite;
    }
    image_index = 0;
    image_speed = attack_anim_speed;
    show_debug_message(
      "    -> Set player sprite to ITEM pose: "
    + sprite_get_name(sprite_index)
    + " | Speed: "
    + string(image_speed)
    );

    // Get FX info from the item struct
    var item_struct    = stored_action_for_anim;
    var target_fx_sp   = spr_pow;
    var target_fx_snd  = snd_punch;
    if (is_struct(item_struct)) {
        target_fx_sp  = item_struct.fx_sprite ?? spr_pow;
        target_fx_snd = item_struct.fx_sound  ?? snd_punch;
    }
    if (audio_exists(target_fx_snd)) audio_play_sound(target_fx_snd, 10, false);

    // Spawn the visual‐effect over the target
    if (instance_exists(target_for_attack) && object_exists(obj_attack_visual)) {
        var _fx_x = target_for_attack.x;
        var _fx_y = target_for_attack.y - 32;
        var _lid = layer_get_id("Instances_FX");
        if (_lid != -1) {
            var fx = instance_create_layer(_fx_x, _fx_y, _lid, obj_attack_visual);
            if (instance_exists(fx)) {
                fx.sprite_index    = target_fx_sp;
                fx.image_speed     = attack_anim_speed;
                fx.depth           = target_for_attack.depth - 1;
                fx.owner_instance  = id;

                // <<< NEW: Tell the FX which item icon to draw over the user >>>
                if (is_struct(item_struct) && variable_struct_exists(item_struct, "sprite_index")) {
                    fx.item_icon = item_struct.sprite_index;
                } else {
                    fx.item_icon = -1;
                }

                attack_animation_finished = false;
                show_debug_message(
                  "    -> Created TARGET FX for item: "
                + sprite_get_name(fx.sprite_index)
                );
            } else {
                attack_animation_finished = true;
            }
        } else {
            attack_animation_finished = true;
        }
    } else {
        attack_animation_finished = true;
    }

    combat_state = "waiting_for_effect";
    break;
        
    // --- Shared Waiting State ---
    case "waiting_for_effect": 
        if (attack_animation_finished) {
             show_debug_message(" -> Target Visual FX finished. Determining return state...");
             // Store previous state to know how to return
             // We check the sprite used DURING the animation state that LED here.
             var _previous_sprite = sprite_index; 
             
             if (_previous_sprite == attack_sprite_asset) { combat_state = "attack_return"; } 
             else if (_previous_sprite == casting_sprite_asset) { combat_state = "cast_return"; } 
             else if (_previous_sprite == item_sprite_asset) { combat_state = "item_return"; } // Needs item_return state
             else { // Fallback 
                  show_debug_message("    -> ERROR: Unknown sprite ("+ sprite_get_name(_previous_sprite) +") in waiting state! Returning to idle.");
                  combat_state = "idle"; 
                  if (instance_exists(obj_battle_manager)) obj_battle_manager.current_attack_animation_complete = true; 
             }
            show_debug_message("    -> Transitioning to: " + combat_state);
            attack_animation_finished = false; 
        }
        break;

    // Return state for physical attacks/skills
    case "attack_return":
        show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> attack_return");
        x = origin_x; y = origin_y; // Teleport Back
        if (sprite_exists(sprite_before_attack)) { sprite_index = sprite_before_attack; } else { sprite_index = idle_sprite; } 
        image_xscale = original_scale; image_yscale = original_scale; // Restore scale
        image_index = 0; image_speed = 1; 
        show_debug_message(" -> Restored sprite and scale"); 
        if (instance_exists(obj_battle_manager)) { obj_battle_manager.current_attack_animation_complete = true; }
        target_for_attack = noone; stored_action_for_anim = undefined; 
        combat_state = "idle"; 
        show_debug_message(" -> Returned to origin. State -> idle.");
        break; 
        
    // Return state for magic casting
    case "cast_return":
         show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> cast_return");
         if (sprite_exists(sprite_before_attack)) { sprite_index = sprite_before_attack; } else { sprite_index = idle_sprite; } 
         image_index = 0; image_speed = 1; 
         // No scale change to restore for casting
         show_debug_message(" -> Restored idle sprite after casting.");
         if (instance_exists(obj_battle_manager)) { obj_battle_manager.current_attack_animation_complete = true; }
         target_for_attack = noone; stored_action_for_anim = undefined; 
         combat_state = "idle"; 
         show_debug_message(" -> Finished casting. State -> idle.");
         break;

     // --- <<< NEW Return State for Items >>> ---
     case "item_return":
         show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> item_return");
         // Restore Sprite (No teleport or scale change happened)
         if (sprite_exists(sprite_before_attack)) { sprite_index = sprite_before_attack; } 
         else { sprite_index = idle_sprite; } 
         image_index = 0; image_speed = 1; 
         show_debug_message(" -> Restored idle sprite after item use.");
         // Signal Manager & Reset
         if (instance_exists(obj_battle_manager)) { obj_battle_manager.current_attack_animation_complete = true; }
         target_for_attack = noone; stored_action_for_anim = undefined; 
         combat_state = "idle"; 
         show_debug_message(" -> Finished item use. State -> idle.");
         break;
        
case "dying":
    if (!death_started) {
        var anim = spr_death;
        if (variable_struct_exists(data, "death_anim_sprite")
         && sprite_exists(data.death_anim_sprite)) {
            anim = data.death_anim_sprite;
        }
        sprite_index  = anim;
        image_index   = 0;
        image_speed   = death_anim_speed;
        death_started = true;
    }
    else if (image_index >= sprite_get_number(sprite_index) - 1) {
        var corpse = spr_dead;
        if (variable_struct_exists(data, "corpse_sprite")
         && sprite_exists(data.corpse_sprite)) {
            corpse = data.corpse_sprite;
        }
        sprite_index = corpse;
        image_index  = 0;
        image_speed  = 1;
        combat_state = "corpse";
    }
    break;

case "corpse":
    // static corpse
    break;
        
} // End Switch
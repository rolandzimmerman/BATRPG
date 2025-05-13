/// obj_battle_manager :: Alarm[0]
show_debug_message("⏰ Alarm[0] Triggered — Battle State: " + string(global.battle_state));

switch (global.battle_state) {

    case "victory":
    {
        // 1) Sum XP from initial_enemy_xp list
        total_xp_from_battle = 0;
        if (variable_instance_exists(id, "initial_enemy_xp")
         && ds_exists(initial_enemy_xp, ds_type_list)) {
            for (var i = 0; i < ds_list_size(initial_enemy_xp); i++) {
                total_xp_from_battle += initial_enemy_xp[| i]; // Correctly access ds_list
            }
        }
        show_debug_message(" -> Total XP to award (from initial_enemy_xp): " + string(total_xp_from_battle));

        // Log the victory
        var add_battle_log_script = asset_get_index("scr_AddBattleLog");
        if (add_battle_log_script != -1 && script_exists(add_battle_log_script)) {
             scr_AddBattleLog("Victory! Gained " + string(total_xp_from_battle) + " XP.");
        }
        if (instance_exists(obj_battle_log)) {
             with (obj_battle_log) holdAtEnd = true;
        }

        // 2) Award XP and collect level-up info
        var _infos = [];
        if (ds_exists(global.battle_party, ds_type_list)) {
            for (var i = 0; i < ds_list_size(global.battle_party); i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst)) continue;
                if (!variable_instance_exists(inst, "data") || !variable_struct_exists(inst.data,"hp") || inst.data.hp <= 0) continue;

                var oldStats = {
                    maxhp: inst.data.maxhp ?? 0,
                    maxmp: inst.data.maxmp ?? 0,
                    atk:   inst.data.atk   ?? 0,
                    def:   inst.data.def   ?? 0,
                    matk:  inst.data.matk  ?? 0,
                    mdef:  inst.data.mdef  ?? 0,
                    spd:   inst.data.spd   ?? 0,
                    luk:   inst.data.luk   ?? 0
                };

                var level_up_result = { leveled_up: false, new_spells: [] };
                var add_xp_script = asset_get_index("scr_AddXPToCharacter");
                if (add_xp_script != -1 && script_exists(add_xp_script)){
                    level_up_result = scr_AddXPToCharacter(inst.character_key, total_xp_from_battle);
                } else {
                    show_debug_message("ERROR: scr_AddXPToCharacter script not found!");
                }

                if (!level_up_result.leveled_up) continue;

                var baseAfter = { name: "Unknown" };
                var get_player_data_script = asset_get_index("scr_GetPlayerData");
                if (get_player_data_script != -1 && script_exists(get_player_data_script)) {
                    baseAfter = scr_GetPlayerData(inst.character_key);
                } else {
                     show_debug_message("ERROR: scr_GetPlayerData script not found!");
                }

                var withEquip = baseAfter;
                var calc_equipped_stats_script = asset_get_index("scr_CalculateEquippedStats");
                if (calc_equipped_stats_script != -1 && script_exists(calc_equipped_stats_script)) {
                    var equipment_data = (variable_instance_exists(inst,"data") && variable_struct_exists(inst.data,"equipment") && is_struct(inst.data.equipment))
                                         ? inst.data.equipment
                                         : {weapon:noone,offhand:noone,armor:noone,helm:noone,accessory:noone};
                    withEquip = scr_CalculateEquippedStats(baseAfter, equipment_data);
                } else {
                     show_debug_message("Warning: scr_CalculateEquippedStats script not found. Using base stats after level up.");
                }

                var newStats = {
                    maxhp: withEquip.maxhp ?? oldStats.maxhp,
                    maxmp: withEquip.maxmp ?? oldStats.maxmp,
                    atk:   withEquip.atk   ?? oldStats.atk,
                    def:   withEquip.def   ?? oldStats.def,
                    matk:  withEquip.matk  ?? oldStats.matk,
                    mdef:  withEquip.mdef  ?? oldStats.mdef,
                    spd:   withEquip.spd   ?? oldStats.spd,
                    luk:   withEquip.luk   ?? oldStats.luk
                };

                array_push(_infos, {
                    name: inst.data.name ?? baseAfter.name ?? "Character",
                    old:  oldStats,
                    new:  newStats,
                    new_spells_learned: level_up_result.new_spells
                });
            }
        }
        global.battle_level_up_infos = _infos;

        // 3) Next step: either show popups or return
        if (array_length(_infos) > 0) {
            global.battle_state         = "show_levelup";
            global.battle_levelup_index = 0;
            
            var popup_layer_name_to_use = ""; // Initialize to an empty string

            // Attempt to find a suitable layer
            if (layer_exists("UI")) {
                popup_layer_name_to_use = "UI";
            } else if (layer_exists("Instances")) {
                popup_layer_name_to_use = "Instances";
            } else {
                // Fallback: Try to get the first available layer
                var all_layer_ids = layer_get_all(); // Returns an array of layer IDs
                if (array_length(all_layer_ids) > 0) {
                    popup_layer_name_to_use = layer_get_name(all_layer_ids[0]); // Get name of the first layer
                    // Ensure the retrieved name actually corresponds to an existing layer
                    if (!layer_exists(popup_layer_name_to_use)) {
                         popup_layer_name_to_use = ""; // Invalidate if something went wrong
                         show_debug_message("Warning: Retrieved layer name '" + popup_layer_name_to_use + "' is invalid.");
                    }
                }
            }

            // Create the popup instance
            if (popup_layer_name_to_use != "") {
                show_debug_message("Creating obj_levelup_popup on layer: " + popup_layer_name_to_use);
                instance_create_layer(0, 0, popup_layer_name_to_use, obj_levelup_popup);
            } else {
                // Absolute fallback if no suitable layer could be determined
                show_debug_message("CRITICAL WARNING: No suitable layer found for obj_levelup_popup. Creating at depth 0.");
                instance_create_depth(0, 0, 0, obj_levelup_popup);
            }

        } else {
            global.battle_state = "return_to_field";
            alarm[0] = 60; 
        }
    }
    break; // End of case "victory"

    case "defeat":
    {
        show_debug_message("💀 Defeat! Showing game over dialog...");
        var create_dialog_script_asset = asset_get_index("create_dialog");
        if (create_dialog_script_asset != -1 && script_exists(create_dialog_script_asset)) {
            create_dialog([{ name: "Defeat", msg: "You have been defeated..." }]);
        } else if (asset_get_index("obj_dialog") != -1 && object_exists(obj_dialog)) {
            var dialog_layer_name = "Instances"; // Default
             if (layer_exists("UI")) {
                dialog_layer_name = "UI";
            } else if (!layer_exists("Instances")) {
                var all_layer_ids_df = layer_get_all();
                if (array_length(all_layer_ids_df) > 0) {
                    dialog_layer_name = layer_get_name(all_layer_ids_df[0]);
                } else { // Should be extremely rare
                    instance_create_depth(0,0, -10000, obj_dialog); // High depth
                    show_debug_message("Fallback: obj_dialog created at depth. Manual text setup might be needed.");
                    break; // Skip instance_create_layer if depth created
                }
            }
            if (layer_exists(dialog_layer_name)) {
                instance_create_layer(0,0,dialog_layer_name, obj_dialog);
                show_debug_message("Fallback: obj_dialog created on layer " + dialog_layer_name + ". Manual text setup might be needed.");
            } else {
                 instance_create_depth(0,0, -10000, obj_dialog); // High depth
                 show_debug_message("Fallback: obj_dialog created at depth as layer "+dialog_layer_name+" not found. Manual text setup might be needed.");
            }
        } else {
             show_debug_message("Warning: Neither create_dialog script nor obj_dialog object found for defeat message.");
        }
        global.battle_state = "return_to_field";
        alarm[0] = 120; // Longer delay for game over message
    }
    break; // End of case "defeat"

    case "return_to_field":
    {
        show_debug_message("Returning to overworld...");

        // Save HP/MP/OD/Level/XP back to global stats
        if (ds_exists(global.battle_party, ds_type_list)
         && variable_global_exists("party_current_stats")
         && ds_exists(global.party_current_stats, ds_type_map)) {
            for (var i = 0; i < ds_list_size(global.battle_party); i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst) || !variable_instance_exists(inst, "character_key") || !variable_instance_exists(inst, "data")) continue;
                var key = inst.character_key;
                var stats = ds_map_find_value(global.party_current_stats, key);
                if (!is_struct(stats)) continue;

                stats.hp         = max(0, inst.data.hp ?? stats.hp ?? 0);
                stats.mp         = max(0, inst.data.mp ?? stats.mp ?? 0);
                stats.overdrive  = clamp(inst.data.overdrive ?? stats.overdrive ?? 0, 0, inst.data.overdrive_max ?? stats.overdrive_max ?? 100);
                
                // Get the absolute latest base stats and skills after all level ups
                var latest_player_data = scr_GetPlayerData(key); 
                if (is_struct(latest_player_data)) {
                    stats.level      = latest_player_data.level ?? stats.level ?? 1;
                    stats.xp         = latest_player_data.xp ?? stats.xp ?? 0;
                    stats.xp_require = latest_player_data.xp_require ?? stats.xp_require ?? scr_GetXPForLevel(stats.level + 1);
                    stats.maxhp = latest_player_data.maxhp;
                    stats.maxmp = latest_player_data.maxmp;
                    stats.atk = latest_player_data.atk;
                    stats.def = latest_player_data.def;
                    stats.matk = latest_player_data.matk;
                    stats.mdef = latest_player_data.mdef;
                    stats.spd = latest_player_data.spd;
                    stats.luk = latest_player_data.luk;
                    if (variable_struct_exists(latest_player_data, "skills")) {
                        stats.skills = latest_player_data.skills; // Ensure skills list is up-to-date
                    }
                 } else { // Fallback if scr_GetPlayerData fails for some reason
                    stats.level      = inst.data.level ?? stats.level ?? 1;
                    stats.xp         = inst.data.xp ?? stats.xp ?? 0;
                    stats.xp_require = inst.data.xp_require ?? stats.xp_require ?? scr_GetXPForLevel(stats.level + 1);
                 }
                ds_map_replace(global.party_current_stats, key, stats);
            }
        }

        // Cleanup instances and DS
        var battle_objects_to_destroy = [obj_battle_player, obj_battle_enemy, obj_battle_menu, obj_dialog, obj_attack_visual, obj_popup_damage, obj_levelup_popup];
        for(var k=0; k < array_length(battle_objects_to_destroy); ++k){ // Changed loop variable to k
            var obj_asset = battle_objects_to_destroy[k];
            // Check if asset is an object and if instances of it exist
            if(asset_get_type(object_get_name(obj_asset)) == asset_object && instance_exists(obj_asset)){
                with (obj_asset) instance_destroy();
            }
        }

        if (ds_exists(global.battle_party, ds_type_list))     { ds_list_destroy(global.battle_party); global.battle_party = -1; }
        if (ds_exists(global.battle_enemies, ds_type_list))   { ds_list_destroy(global.battle_enemies); global.battle_enemies = -1; }
        if (ds_exists(global.battle_status_effects, ds_type_map)) { ds_map_destroy(global.battle_status_effects); global.battle_status_effects = -1; }
        
        if (variable_instance_exists(id, "combatants_all") && ds_exists(combatants_all, ds_type_list)) {
            ds_list_destroy(combatants_all);
            combatants_all = -1;
        }
        if (variable_instance_exists(id, "initial_enemy_xp") && ds_exists(initial_enemy_xp, ds_type_list)) {
            ds_list_destroy(initial_enemy_xp);
            initial_enemy_xp = -1;
        }

        if (variable_instance_exists(id,"battle_fx_surface") && surface_exists(battle_fx_surface)) { surface_free(battle_fx_surface); battle_fx_surface = -1; }

        if (variable_instance_exists(id, "stored_action_data")) stored_action_data = undefined;
        if (variable_instance_exists(id, "selected_target_id")) selected_target_id = noone;
        if (variable_instance_exists(id, "currentActor")) currentActor = noone;
        
        global.active_party_member_index = 0;
        global.battle_target         = 0;
        if (variable_global_exists("battle_levelup_index")) global.battle_levelup_index = 0;
        if (variable_global_exists("battle_level_up_infos")) global.battle_level_up_infos = [];

        if (variable_global_exists("original_room") && room_exists(global.original_room)) {
            room_goto(global.original_room);
        } else {
            show_debug_message("ERROR: No valid return room found. Attempting to go to first room or end game.");
            var first_room_idx = room_first;
            if (room_exists(first_room_idx) && room != first_room_idx) {
                 room_goto(first_room_idx);
            } else {
                 game_end();
            }
        }
    }
    break; // End of case "return_to_field"

    default:
        show_debug_message("⚠️ Alarm[0] reached in unknown battle state: " + string(global.battle_state));
        if (global.battle_state != "return_to_field") {
            show_debug_message(" -> Attempting recovery by setting state to 'return_to_field'");
            global.battle_state = "return_to_field";
            alarm[0] = 1; 
        }
        break; // End of default case
}
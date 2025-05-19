/// obj_npc_recruitable_gabby :: Step Event
/// @description Handles Gob's cinematic recruitment sequence.

// --- Game Pause Check (Affects this instance's animation/path speed) ---
var _is_game_paused_externally = (instance_exists(obj_game_manager) && 
                                obj_game_manager.game_state != "playing" && 
                                obj_game_manager.game_state != "cutscene_gob_recruit");

if (_is_game_paused_externally && 
    sequence_state != GOB_RECRUIT_SEQ.PRE_SEQUENCE_CHECK && 
    sequence_state != GOB_RECRUIT_SEQ.START_CUTSCENE) {
    if (path_exists(path_index) && path_speed != 0) { path_speed = 0; }
    if (image_speed != 0) { image_speed = 0; }
    exit;
}

// --- Recruitment Sequence State Machine ---
switch (sequence_state) {
    case GOB_RECRUIT_SEQ.PRE_SEQUENCE_CHECK:
        // ... (same as previous answer) ...
        var _is_already_in_party = false;
        if (variable_global_exists("party_members") && is_array(global.party_members)) {
            for (var i = 0; i < array_length(global.party_members); i++) {
                if (global.party_members[i] == character_key) {
                    _is_already_in_party = true;
                    break;
                }
            }
        } else {
            show_debug_message(character_key + " Create (ID: " + string(id) + "): ERROR! global.party_members does not exist or is not an array!");
        }

        if (_is_already_in_party) {
            show_debug_message(character_key + " (ID: " + string(id) + "): Already in party. Destroying cutscene NPC.");
            sequence_state = GOB_RECRUIT_SEQ.DONE;
        } else {
            show_debug_message(character_key + " (ID: " + string(id) + "): Not in party. Proceeding to START_CUTSCENE.");
            sequence_state = GOB_RECRUIT_SEQ.START_CUTSCENE;
        }
        break;

    case GOB_RECRUIT_SEQ.START_CUTSCENE:
        // ... (same as previous answer) ...
        show_debug_message(character_key + " Seq: START_CUTSCENE -> Pausing game and starting WALK_PATH_1");
        if (instance_exists(obj_game_manager)) {
            obj_game_manager.game_state = "cutscene_gob_recruit"; 
            show_debug_message("Game state set to 'cutscene_gob_recruit'");
        }
        
        is_busy = true;
        path_start(path1_asset, path1_walk_speed, path_action_stop, true);
        sprite_index = sprite_walk;
        image_speed = 1; 
        sequence_state = GOB_RECRUIT_SEQ.WALK_PATH_1;
        break;

    case GOB_RECRUIT_SEQ.WALK_PATH_1:
        // ... (same as previous answer) ...
        if (path_position >= 1) {
            show_debug_message(character_key + " Seq: WALK_PATH_1 -> DIALOGUE_1_SETUP");
            path_end();
            sprite_index = sprite_idle;
            image_speed = 0;
            image_index = 0;
            sequence_state = GOB_RECRUIT_SEQ.DIALOGUE_1_SETUP;
        }
        if (path_speed != 0 && x != xprevious) { image_xscale = sign(x - xprevious); }
        break;

    case GOB_RECRUIT_SEQ.DIALOGUE_1_SETUP:
        // ... (same as previous answer) ...
        show_debug_message(character_key + " Seq: DIALOGUE_1_SETUP -> DIALOGUE_1_WAIT");
        if (script_exists(create_dialog) && !instance_exists(obj_dialog)) {
            create_dialog(dialogue_set_1);
            sequence_state = GOB_RECRUIT_SEQ.DIALOGUE_1_WAIT;
        } else if (instance_exists(obj_dialog)) {
            // Waiting
        } else {
            show_debug_message(character_key + " Seq: ERROR - create_dialog script missing or dialog exists! Skipping.");
            sequence_state = GOB_RECRUIT_SEQ.WALK_PATH_2_FAST;
        }
        break;

    case GOB_RECRUIT_SEQ.DIALOGUE_1_WAIT:
        // ... (same as previous answer) ...
        if (!instance_exists(obj_dialog)) { 
            show_debug_message(character_key + " Seq: DIALOGUE_1_WAIT -> WALK_PATH_2_FAST");
            sequence_state = GOB_RECRUIT_SEQ.WALK_PATH_2_FAST;
        }
        break;

    case GOB_RECRUIT_SEQ.WALK_PATH_2_FAST:
        // ... (blast sound and start path, same as previous) ...
        show_debug_message(character_key + " Seq: WALK_PATH_2_FAST (starting)");
        if (audio_exists(snd_sfx_gob_blast)) { 
             audio_play_sound(snd_sfx_gob_blast, 10, false, 1); 
        }
        path_start(path2_asset, path2_super_fast_speed, path_action_stop, true);
        sprite_index = sprite_walk; 
        image_speed = 2; 
        sequence_state = GOB_RECRUIT_SEQ.WALK_PATH_2_REVERSE_SETUP;
        break;

    case GOB_RECRUIT_SEQ.WALK_PATH_2_REVERSE_SETUP:
        if (path_position >= 1) { // Fast path ended
            show_debug_message(character_key + " Seq: WALK_PATH_2_FAST ended -> CRASH, SHAKE, and starting REVERSE");
            path_end(); 
            
            // --- Play Crash Sound ---
            if (audio_exists(snd_fx_crash)) {
                audio_play_sound(snd_fx_crash, 8, false, 1);
            }
            
            // --- Trigger Screen Shake by Toggling Layer Visibility ---
            if (script_exists(scr_show_layer_for_duration)) {
                // Use the EXACT name of your Effect Layer from the Room Editor
                var _effect_layer_name_to_show = "MyScreenShakeEffect"; // FROM YOUR SCREENSHOT
                var _shake_duration_frames = floor(game_get_speed(gamespeed_fps) * 0.5); // 0.5 seconds
                
                show_debug_message(character_key + ": Calling scr_show_layer_for_duration for Layer: '" + _effect_layer_name_to_show + "'");
                scr_show_layer_for_duration(_effect_layer_name_to_show, _shake_duration_frames);
            } else {
                show_debug_message("ERROR: scr_show_layer_for_duration script not found!");
            }
            
            // Start reverse path
            path_start(path2_asset, path2_reverse_slow_speed, path_action_stop, true);
            sprite_index = sprite_walk;
            image_speed = 0.75; 
            sequence_state = GOB_RECRUIT_SEQ.WALK_PATH_2_REVERSE;
        }
        if (path_speed > 0 && x != xprevious) { image_xscale = sign(x - xprevious); }
        break;
        
    case GOB_RECRUIT_SEQ.WALK_PATH_2_REVERSE:
        // ... (same as previous answer) ...
         if (path_position <= 0) { 
            show_debug_message(character_key + " Seq: WALK_PATH_2_REVERSE ended -> DIALOGUE_2_SETUP");
            path_end();
            sprite_index = sprite_idle;
            image_speed = 0;
            image_index = 0;
            sequence_state = GOB_RECRUIT_SEQ.DIALOGUE_2_SETUP;
        }
        if (path_speed < 0 && x != xprevious) { image_xscale = sign(x - xprevious); }
        break;

    case GOB_RECRUIT_SEQ.DIALOGUE_2_SETUP:
        // ... (same as previous answer) ...
        show_debug_message(character_key + " Seq: DIALOGUE_2_SETUP -> DIALOGUE_2_WAIT");
        if (script_exists(create_dialog) && !instance_exists(obj_dialog)) {
            create_dialog(dialogue_set_2);
            sequence_state = GOB_RECRUIT_SEQ.DIALOGUE_2_WAIT;
        } else if (instance_exists(obj_dialog)) {
            // Waiting
        } else {
            show_debug_message(character_key + " Seq: ERROR - create_dialog script missing or dialog exists! Skipping.");
            sequence_state = GOB_RECRUIT_SEQ.PERFORM_RECRUIT; 
        }
        break;

    case GOB_RECRUIT_SEQ.DIALOGUE_2_WAIT:
        // ... (same as previous answer) ...
        if (!instance_exists(obj_dialog)) {
            show_debug_message(character_key + " Seq: DIALOGUE_2_WAIT -> PERFORM_RECRUIT");
            sequence_state = GOB_RECRUIT_SEQ.PERFORM_RECRUIT;
        }
        break;

    case GOB_RECRUIT_SEQ.PERFORM_RECRUIT:
        // ... (Full recruitment logic, same as previous answer) ...
        show_debug_message(character_key + " Seq: PERFORM_RECRUIT");
        var _char_key = character_key; 
        
        if (variable_global_exists("party_members") && is_array(global.party_members)) {
            var _already_in_party_final_check = false;
            for (var i = 0; i < array_length(global.party_members); i++) {
                if (global.party_members[i] == _char_key) { _already_in_party_final_check = true; break; }
            }
            if (!_already_in_party_final_check) {
                array_push(global.party_members, _char_key);
                show_debug_message(character_key + " Seq: Party is now: " + string(global.party_members));

                if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
                    if (!ds_map_exists(global.party_current_stats, _char_key)) { 
                        show_debug_message(character_key + " Seq: Adding initial persistent stats for: " + _char_key);
                        var _base_data = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_char_key) : undefined;
                        if (is_struct(_base_data)) {
                            var _xp_req = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
                            var _skills_arr = variable_struct_exists(_base_data, "skills") && is_array(_base_data.skills) ? variable_clone(_base_data.skills, true) : [];
                            var _equip_struct = variable_struct_exists(_base_data, "equipment") && is_struct(_base_data.equipment) ? variable_clone(_base_data.equipment, true) : { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
                            var _resists_struct = variable_struct_exists(_base_data, "resistances") && is_struct(_base_data.resistances) ? variable_clone(_base_data.resistances, true) : { physical: 0 };
                            var _initial_maxhp = variable_struct_get(_base_data, "hp_total") ?? 30;
                            var _initial_maxmp = variable_struct_get(_base_data, "mp_total") ?? 20;
                            var _initial_stats = {
                                hp: _initial_maxhp, maxhp: _initial_maxhp, 
                                mp: _initial_maxmp, maxmp: _initial_maxmp,
                                atk: variable_struct_get(_base_data, "atk") ?? 7, 
                                def: variable_struct_get(_base_data, "def") ?? 5, 
                                matk: variable_struct_get(_base_data, "matk") ?? 10,
                                mdef: variable_struct_get(_base_data, "mdef") ?? 8, 
                                spd: variable_struct_get(_base_data, "spd") ?? 7, 
                                luk: variable_struct_get(_base_data, "luk") ?? 6, 
                                level: 1, xp: 0, xp_require: _xp_req,
                                skills: _skills_arr, 
                                equipment: _equip_struct,
                                resistances: _resists_struct, 
                                overdrive: 0, overdrive_max: 100,
                                name: variable_struct_get(_base_data, "name") ?? _char_key,
                                class: variable_struct_get(_base_data, "class") ?? "Scout",
                                character_key: _char_key
                            };
                            ds_map_add(global.party_current_stats, _char_key, _initial_stats);
                            show_debug_message(character_key + " Seq: Added '" + _char_key + "' to global.party_current_stats map.");
                        } else { show_debug_message(character_key + " Seq ERROR: Could not fetch base data for '" + _char_key + "'."); }
                    } else { show_debug_message(character_key + " Seq: '" + _char_key + "' already in persistent stats map."); }
                } else { show_debug_message(character_key + " Seq ERROR: global.party_current_stats map missing!"); }
                
                var char_display_name_success = (is_struct(_base_data) && variable_struct_exists(_base_data, "name")) ? _base_data.name : _char_key;
                if (script_exists(create_dialog) && !instance_exists(obj_dialog)) {
                     create_dialog([{ name: "System", msg: string(char_display_name_success) + " joined your adventure!" }]);
                } else {
                    show_debug_message(string(char_display_name_success) + " joined your adventure! (Dialog system unavailable for join message)");
                }
            } else { show_debug_message(character_key + " Seq: Already in party (final check)."); }
        } else {
            show_debug_message(character_key + " Seq CRITICAL ERROR: global.party_members missing! Cannot add " + _char_key);
        }
        sequence_state = GOB_RECRUIT_SEQ.UNPAUSE_AND_FINISH;
        break;

    case GOB_RECRUIT_SEQ.UNPAUSE_AND_FINISH:
        // ... (same as previous answer) ...
        if (!instance_exists(obj_dialog)) { 
            show_debug_message(character_key + " Seq: UNPAUSE_AND_FINISH -> DONE. Unpausing game.");
            if (instance_exists(obj_game_manager)) {
                obj_game_manager.game_state = "playing"; 
                show_debug_message("Game state set to 'playing'");
            }
            sequence_state = GOB_RECRUIT_SEQ.DONE;
        }
        break;

    case GOB_RECRUIT_SEQ.DONE:
        // ... (same as previous answer) ...
        show_debug_message(character_key + " Seq: DONE. Destroying instance " + string(id));
        instance_destroy();
        break;
}
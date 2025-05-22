/// @function scr_load_game(filename)
/// @description Deserializes and reads game state from JSON file, preparing data for room load.
/// @param filename {string}
/// @returns {bool}
function scr_load_game(filename) {
    show_debug_message("[Load] Starting load from: " + filename);

    // 1) Read from disk (Your existing code here)
    if (!file_exists(filename)) {
        show_debug_message("[Load] File not found: " + filename);
        return false;
    }
    var fh = file_text_open_read(filename);
    if (fh < 0) {
        show_debug_message("[Load] Could not open file: " + filename);
        return false;
    }
    var json_in = "";
    while (!file_text_eof(fh)) {
        json_in += file_text_read_string(fh);
        file_text_readln(fh);
    }
    file_text_close(fh);
    if (json_in == "") {
        show_debug_message("[Load] File was empty: " + filename);
        return false;
    }

    // 2) JSON parse (Your existing code here)
    var data; // This 'data' is the root struct from the JSON file
    try {
        data = json_parse(json_in);
    } catch (e) {
        show_debug_message("[Load] JSON parse failed: " + string(e));
        return false;
    }
    if (!is_struct(data)) {
        show_debug_message("[Load] Parsed JSON is not a struct.");
        return false;
    }
    show_debug_message("[Load] JSON parsed. Struct keys = " + string(variable_struct_get_names(data)));

    // 3) Core party globals - Clearing (Your existing code or logic here)
    // … (your existing party_members/party_inventory/party_current_stats clear code) …
    // This part would clear the live globals before scr_apply_post_load_state repopulates them.

    // 4) Simple globals (Applied directly as they don't depend on room context)
    if (variable_struct_exists(data, "globals")) {
        var G = data.globals;
        if (variable_struct_exists(G, "quest_stage")) global.quest_stage    = G.quest_stage;
        if (variable_struct_exists(G, "party_currency")) global.party_currency = G.party_currency;
        if (variable_struct_exists(G, "has_collected_main_echo_gem"))      global.has_collected_main_echo_gem      = G.has_collected_main_echo_gem;
        if (variable_struct_exists(G, "has_collected_main_flurry_flower")) global.has_collected_main_flurry_flower = G.has_collected_main_flurry_flower;
        if (variable_struct_exists(G, "has_collected_main_meteor_shard"))  global.has_collected_main_meteor_shard  = G.has_collected_main_meteor_shard;
    }

    // 5) Restore DS-map globals (Applied directly)
    if (variable_struct_exists(data, "ds")) {
        var DS = data.ds; // This is data.ds, not the root 'data'
        var dsNames = ["gate_states_map","recruited_npcs_map","broken_blocks_map","loot_drops_map"];
        for (var i = 0; i < array_length(dsNames); i++) {
            var nm = dsNames[i];
            if (variable_global_exists(nm) && ds_exists(variable_global_get(nm), ds_type_map)) {
                ds_map_destroy(variable_global_get(nm));
            }
            var m = ds_map_create();
            variable_global_set(nm, m);
            var key = nm + "_string";
            if (variable_struct_exists(DS, key)) {
                var s = variable_struct_get(DS, key);
                if (is_string(s) && s != "") {
                    var ok = ds_map_read(m, s);
// Change this:
// show_debug_message("[Load] ds_map_read('" + nm + "') -> " + string(ok));
// To this for clearer success/failure:
if (ok == true) { // Explicitly check for true
    show_debug_message("[Load] Successfully read ds_map '" + nm + "'.");
} else {
    show_debug_message("[Load] FAILED to read ds_map '" + nm + "'. Return value: " + string(ok));
}
                }
            }
        }
    }

    // 6) Party arrays & stats ARE NO LONGER APPLIED HERE.
    // They will be packaged into global.pending_load_data instead.

    // 7) Figure out target room & pending data
    var target_room_asset = noone;
    var player_struct_data = undefined; // From data.player
    var npcs_struct_data = undefined;   // From data.npcs
    //var instance_ds_map_strings = undefined; // From data.ds (already handled directly above for global maps, but could be passed if needed for scr_apply_instance_states specifically)

    if (variable_struct_exists(data, "player") && is_struct(data.player)) {
        player_struct_data = data.player;
        if (variable_struct_exists(player_struct_data, "room")) {
            target_room_asset = asset_get_index(player_struct_data.room);
        }
    }
    if (variable_struct_exists(data, "npcs") && is_struct(data.npcs)) {
        npcs_struct_data = data.npcs;
    }
    //var instance_ds_map_strings = variable_struct_exists(data, "ds") ? data.ds : {};


    if (target_room_asset != noone && room_exists(target_room_asset)) {
        // --- MODIFICATION: Pass the entire 'data' struct, or specific parts needed by scr_apply_post_load_state ---
        // Passing the whole 'data' struct is simplest if scr_apply_post_load_state will handle various parts of it.
        // This 'data' includes .player, .npcs, .ds (for instances), AND .party_members, .party_inventory, .party_stats
        global.pending_load_data = data; // Pass the entire parsed JSON struct

        global.isLoadingGame = true;
        show_debug_message("[Load] Transition to " + room_get_name(target_room_asset));
        room_goto(target_room_asset);
    } else {
        show_debug_message("[Load] Invalid target room, applying in current room.");
        // If applying in current room, we'd still need pending_load_data for scr_apply_post_load_state
        global.pending_load_data = data; // Pass the entire parsed JSON struct
        scr_apply_post_load_state(); // Call it directly
    }
    return true;
}

/// @function scr_apply_post_load_state()
/// @description Applies loaded player/NPC/instance/party states after room transition.
function scr_apply_post_load_state() {
    if (!global.isLoadingGame || !is_struct(global.pending_load_data)) {
        show_debug_message("[Load_Apply] Aborted: isLoadingGame is false or pending_load_data is not a struct.");
        global.isLoadingGame = false; 
        global.pending_load_data = undefined;
        return;
    }
    
    var L = global.pending_load_data; // 'L' is the entire data struct from the JSON file
    show_debug_message("[Load_Apply] Applying save in room " + room_get_name(room) + ". Root keys in L: " + string(variable_struct_get_names(L)));

    // 1) Activate everything
    instance_activate_all();
    show_debug_message("[Load_Apply] Activated all instances.");

    // Restore party_members and party_inventory arrays
    if (variable_struct_exists(L, "party_members")) {
        if (is_array(L.party_members)) {
            global.party_members = variable_clone(L.party_members, true); 
            show_debug_message("[Load_Apply] Restored party_members. Count: " + string(array_length(global.party_members)));
        } else {
            show_debug_message("[Load_Apply] WARNING: party_members in loaded data was not an array. Type: " + typeof(L.party_members));
            global.party_members = []; 
        }
    } else {
        show_debug_message("[Load_Apply] 'party_members' key not found in loaded data. Initializing as empty array.");
        global.party_members = [];
    }

    if (variable_struct_exists(L, "party_inventory")) {
         if (is_array(L.party_inventory)) {
            global.party_inventory = variable_clone(L.party_inventory, true); 
            show_debug_message("[Load_Apply] Restored party_inventory. Count: " + string(array_length(global.party_inventory)));
        } else {
            show_debug_message("[Load_Apply] WARNING: party_inventory in loaded data was not an array. Type: " + typeof(L.party_inventory));
            global.party_inventory = []; 
        }
    } else {
        show_debug_message("[Load_Apply] 'party_inventory' key not found in loaded data. Initializing as empty array.");
        global.party_inventory = [];
    }
    
    // ----------------------------------------------------------------------------------
    // REVISED SECTION: Restore party_stats (global.party_current_stats DS Map)
    // ----------------------------------------------------------------------------------
    // Ensure global.party_current_stats is a valid DS map to load into.
    if (!variable_global_exists("party_current_stats") || 
        !(is_real(global.party_current_stats) && ds_exists(global.party_current_stats, ds_type_map))) {
        show_debug_message("[Load_Apply - Party Stats] global.party_current_stats was invalid or did not exist. Creating a new map.");
        global.party_current_stats = ds_map_create();
    } else {
        ds_map_clear(global.party_current_stats); // Clear existing entries before loading new ones
    }

    if (variable_struct_exists(L, "party_stats")) { // This key now holds the JSON string from json_stringify
        var ps_json_string = L.party_stats; 

        if (is_string(ps_json_string) && ps_json_string != "" && ps_json_string != "{}") {
            show_debug_message("[Load_Apply - DEBUG] Party Stats JSON String to Parse: |" + ps_json_string + "|");
            var parsed_stats_struct; // This will be a GML struct after parsing
            var parse_success = false;
            try {
                parsed_stats_struct = json_parse(ps_json_string);
                if (is_struct(parsed_stats_struct)) {
                    parse_success = true;
                } else {
                     show_debug_message("[Load_Apply] json_parse for party_stats did not return a struct. Type: " + typeof(parsed_stats_struct));
                }
            } catch (e) {
                show_debug_message("[Load_Apply] FAILED to json_parse party_stats string. Error: " + string(e) + ". Party stats map will be empty.");
                parsed_stats_struct = undefined; // Ensure it's undefined on error
            }

            if (parse_success) {
                // Populate the global.party_current_stats DS Map from the parsed_stats_struct
                var char_keys_from_json = variable_struct_get_names(parsed_stats_struct);
                for (var i = 0; i < array_length(char_keys_from_json); i++) {
                    var char_key = char_keys_from_json[i];
                    var char_stat_data = variable_struct_get(parsed_stats_struct, char_key);
                    // char_stat_data should be the sanitized struct (or null) for the character
                    ds_map_add(global.party_current_stats, char_key, char_stat_data); 
                }
                show_debug_message("[Load_Apply] Successfully parsed and applied party_stats from JSON string. DS Map size: " + string(ds_map_size(global.party_current_stats)));
            } else {
                show_debug_message("[Load_Apply] Parsed party_stats string did not result in a valid struct. Party stats map remains empty.");
            }
        } else if (ps_json_string == "{}" || ps_json_string == "") { // An empty object string or truly empty string
            show_debug_message("[Load_Apply] party_stats string in save data was empty or an empty JSON object ('{}'). Party stats map is empty.");
        } else { // Not a string
             show_debug_message("[Load_Apply] WARNING: party_stats in save data was not a processable string. Party stats map will be empty. Type: " + typeof(ps_json_string));
        }
    } else {
        show_debug_message("[Load_Apply] 'party_stats' key not found in loaded data. Party stats map is empty.");
    }
    // ----------------------------------------------------------------------------------
    // END OF PARTY STATS RESTORE SECTION
    // ----------------------------------------------------------------------------------

    // Restore player (Adjusted to use L.player directly)
    if (variable_struct_exists(L, "player") && is_struct(L.player)) {
        var P = L.player; 
        if (instance_exists(obj_player)) {
            var p_inst = obj_player; // Changed var name to avoid conflict
            if (variable_struct_exists(P, "x")) p_inst.x = P.x;
            if (variable_struct_exists(P, "y")) p_inst.y = P.y;
            if (variable_struct_exists(P, "p_state")) p_inst.player_state = P.p_state;
            if (variable_struct_exists(P, "f_dir"))   p_inst.face_dir     = P.f_dir;
            p_inst.isDashing = p_inst.isDiving = p_inst.is_in_knockback = false;
            p_inst.v_speed = p_inst.knockback_hspeed = p_inst.knockback_vspeed = 0;
            show_debug_message("[Load_Apply] Player placed at (" + string(p_inst.x)+"," + string(p_inst.y) + ")");
        }
    }

    // NPCs (Adjusted to use L.npcs directly)
    if (variable_struct_exists(L, "npcs") && is_struct(L.npcs)) {
        apply_npc_states(L.npcs); 
    }

    // Instances (broken blocks, loot, gates, switches…) 
    if (variable_struct_exists(L, "ds") && is_struct(L.ds)) {
        scr_apply_instance_states(L.ds); 
    }

    // Unpause
    if (instance_exists(obj_game_manager)) obj_game_manager.game_state = "playing";
    global.isLoadingGame = false;
    global.pending_load_data = undefined;
    show_debug_message("[Load_Apply] Complete.");
}

/// @function scr_apply_instance_states(D)
/// @description Hides/destroys or re-creates world instances based on saved DS-map strings.
function scr_apply_instance_states(D) {
    show_debug_message("[ApplyInstances] Begin");

    // broken blocks
    if (variable_struct_exists(D, "broken_blocks_map_string")) {
        var s = variable_struct_get(D, "broken_blocks_map_string");
        var tmp = ds_map_create();
        if (is_string(s) && s != "" && ds_map_read(tmp, s)) {
            // iterate all keys: if a block with that key exists, destroy it
            var keys = ds_map_keys(tmp);
            for (var i = 0; i < array_length(keys); i++) {
                var key = keys[i];
                with (obj_destructible_block) {
                    if (variable_instance_exists(id, "block_unique_key") 
                     && block_unique_key == key) {
                        instance_destroy();
                    }
                }
            }
        }
        ds_map_destroy(tmp);
    }

    // loot
    if (variable_struct_exists(D, "loot_drops_map_string")) {
        var s2 = variable_struct_get(D, "loot_drops_map_string");
        var tmp2 = ds_map_create();
        if (is_string(s2) && s2 != "" && ds_map_read(tmp2, s2)) {
            var keys2 = ds_map_keys(tmp2);
            for (var i = 0; i < array_length(keys2); i++) {
                var lk = keys2[i];
                with (obj_loot_drop) {
                    if (variable_instance_exists(id, "loot_key") 
                     && loot_key == lk) {
                        instance_destroy();
                    }
                }
            }
        }
        ds_map_destroy(tmp2);
    }

    // gates/switches
    // their Create events already read global.gate_states_map,
    // so if that DS map was restored above, they’ll initialize correctly.

    show_debug_message("[ApplyInstances] Done");
}

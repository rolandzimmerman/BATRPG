/// @function scr_load_game(filename)
/// @description Deserializes and reads game state from JSON file, loading the room by name.
/// @param filename {string}
/// @returns {bool}
function scr_load_game(filename) {
    show_debug_message("[Load] Starting load from: " + filename);

    // 1) Read from disk
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

    // 2) JSON parse
    var data;
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

    // 3) Core party globals
    // … (your existing party_members/party_inventory/party_current_stats clear code) …

    // 4) Simple globals
    if (variable_struct_exists(data, "globals")) {
        var G = data.globals;
        if (variable_struct_exists(G, "quest_stage")) global.quest_stage   = G.quest_stage;
        if (variable_struct_exists(G, "party_currency")) global.party_currency = G.party_currency;
        // …etc…
    }

    // 5) Restore DS-map globals
    if (variable_struct_exists(data, "ds")) {
        var DS = data.ds;
        var dsNames = ["gate_states_map","recruited_npcs_map","broken_blocks_map","loot_drops_map"];
        for (var i = 0; i < array_length(dsNames); i++) {
            var nm = dsNames[i];
            // destroy old
            if (variable_global_exists(nm) && ds_exists(variable_global_get(nm), ds_type_map)) {
                ds_map_destroy(variable_global_get(nm));
            }
            // create new
            var m = ds_map_create();
            variable_global_set(nm, m);

            var key = nm + "_string";
            if (variable_struct_exists(DS, key)) {
                var s = variable_struct_get(DS, key);
                if (is_string(s) && s != "") {
                    var ok = ds_map_read(m, s);
                    show_debug_message("[Load] ds_map_read('" + nm + "') -> " + string(ok));
                }
            }
        }
    }

    // 6) Party arrays & stats
    if (variable_struct_exists(data, "party_members"))   global.party_members   = data.party_members;
    if (variable_struct_exists(data, "party_inventory")) global.party_inventory = data.party_inventory;
    if (variable_struct_exists(data, "party_stats")) {
        var ps = data.party_stats;
        if (is_string(ps) && ps != "") {
            ds_map_read(global.party_current_stats, ps);
            show_debug_message("[Load] Restored party_stats, size = " + string(ds_map_size(global.party_current_stats)));
        }
    }

    // 7) Figure out target room & pending data
    var target = noone;
    var player_data = undefined, npc_data = undefined;
    if (variable_struct_exists(data, "player") && is_struct(data.player)) {
        player_data = data.player;
        if (variable_struct_exists(player_data, "room")) {
            target = asset_get_index(player_data.room);
        }
    }
    if (variable_struct_exists(data, "npcs") && is_struct(data.npcs)) {
        npc_data = data.npcs;
    }

    if (target != noone && room_exists(target)) {
        global.pending_load_data = {
            player_data: player_data,
            npc_data:    npc_data,
            instance_data: data.ds // pass the DS strings through, the next script will handle broken_blocks_map, loot_drops_map, etc.
        };
        global.isLoadingGame = true;
        show_debug_message("[Load] Transition to " + room_get_name(target));
        room_goto(target);
    } else {
        show_debug_message("[Load] Invalid target room, applying in current room.");
        scr_apply_post_load_state();
    }
    return true;
}

/// @function scr_apply_post_load_state()
/// @description Applies loaded player/NPC/instance states after room transition.
///               Called from obj_game_manager :: Other Event 4 (Room Start).
function scr_apply_post_load_state() {
    if (!global.isLoadingGame || !is_struct(global.pending_load_data)) return;
    var L = global.pending_load_data;
    show_debug_message("[Load_Apply] Applying save in room " + room_get_name(room));

    // 1) activate everything
    instance_activate_all();
    show_debug_message("[Load_Apply] Activated all instances.");

    // 2) restore player
    if (is_struct(L.player_data)) {
        var P = L.player_data;
        if (instance_exists(obj_player)) {
            var p = obj_player;
            if (variable_struct_exists(P, "x")) p.x = P.x;
            if (variable_struct_exists(P, "y")) p.y = P.y;
            if (variable_struct_exists(P, "p_state")) p.player_state = P.p_state;
            if (variable_struct_exists(P, "f_dir"))   p.face_dir    = P.f_dir;
            // reset transient…
            p.isDashing = p.isDiving = p.is_in_knockback = false;
            p.v_speed = p.knockback_hspeed = p.knockback_vspeed = 0;
            show_debug_message("[Load_Apply] Player placed at (" + string(p.x)+"," + string(p.y) + ")");
        }
    }

    // 3) NPCs
    if (is_struct(L.npc_data)) apply_npc_states(L.npc_data);

    // 4) Instances (broken blocks, loot, gates, switches…)
    if (is_struct(L.instance_data)) {
        scr_apply_instance_states(L.instance_data);

    }

    // 5) unpause
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

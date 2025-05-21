/// @function scr_load_game(filename)
/// @description Deserializes JSON, resets globals, restores party & DS maps, then jumps to saved room.
function scr_load_game(filename) {
    show_debug_message("[Load] Starting load from: " + filename);

    // 1) Read file
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
        show_debug_message("[Load] Empty save file.");
        return false;
    }

    // 2) Parse JSON
    var saveData;
    try {
        saveData = json_parse(json_in);
    } catch (e) {
        show_debug_message("[Load] JSON parse error: " + string(e));
        return false;
    }
    if (!is_struct(saveData)) {
        show_debug_message("[Load] Parsed data is not a struct.");
        return false;
    }

    // 3) Reset core globals
    // party_members
    if (variable_struct_exists(saveData, "party_members") && is_array(saveData.party_members)) {
        global.party_members = saveData.party_members;
    } else {
        global.party_members = [];
    }
    // party_inventory
    if (variable_struct_exists(saveData, "party_inventory") && is_array(saveData.party_inventory)) {
        global.party_inventory = saveData.party_inventory;
    } else {
        global.party_inventory = [];
    }
    // party_current_stats
    var pcs_id = variable_global_exists("party_current_stats") ? global.party_current_stats : -1;
    if (!is_real(pcs_id) || !ds_exists(pcs_id, ds_type_map)) {
        if (is_real(pcs_id) && ds_exists(pcs_id, ds_type_map)) ds_map_destroy(pcs_id);
        global.party_current_stats = ds_map_create();
    } else {
        ds_map_clear(global.party_current_stats);
    }
    if (variable_struct_exists(saveData, "party_stats") && is_string(saveData.party_stats) && saveData.party_stats != "") {
        ds_map_read(global.party_current_stats, saveData.party_stats);
    }

    // 4) Restore simple globals
    if (variable_struct_exists(saveData, "globals")) {
        var G = saveData.globals;
        if (variable_struct_exists(G, "quest_stage"))    global.quest_stage    = G.quest_stage;
        if (variable_struct_exists(G, "party_currency")) global.party_currency = G.party_currency;
    }

    // 5) Queue up the room transition + pending world data
    var targetRoom = -1;
    var P = undefined;
    if (variable_struct_exists(saveData, "player") && is_struct(saveData.player)) {
        P = saveData.player;
        if (variable_struct_exists(P, "room") && is_string(P.room)) {
            targetRoom = asset_get_index(P.room);
        }
    }

    global.pending_load_data = {
        player_data : P,
        ds_data     : variable_struct_exists(saveData, "ds") && is_struct(saveData.ds) ? saveData.ds : undefined
    };
    global.isLoadingGame = true;

    if (targetRoom != -1 && room_exists(targetRoom)) {
        show_debug_message("[Load] Going to saved room: " + room_get_name(targetRoom));
        room_goto(targetRoom);
    } else {
        show_debug_message("[Load] Invalid saved room name: " + string(P.room));
    }

    return true;
}

/// @function scr_apply_post_load_state()
/// @description After room change, restores player position/state and prunes saved world state.
function scr_apply_post_load_state() {
    if (!global.isLoadingGame || !variable_struct_exists(global.pending_load_data, "player_data")) {
        return;
    }
    var D = global.pending_load_data;

    // 1) Activate everything
    instance_activate_all();

    // 2) Restore player
    if (is_struct(D.player_data) && instance_exists(obj_player)) {
        var P = D.player_data;
        with (obj_player) {
            x = P.x; y = P.y;
            if (variable_struct_exists(P, "p_state")) player_state = P.p_state;
            if (variable_struct_exists(P, "f_dir"))   face_dir    = P.f_dir;
            // clear transient motion
            isDashing = false; dash_timer = 0;
            isDiving  = false; v_speed = 0;
            is_in_knockback = false; knockback_timer = 0;
        }
    }

    // 3) Rebuild world DS-maps from D.ds_data JSON blobs
    var mapList = ["gate_states_map","recruited_npcs_map","broken_blocks_map","loot_drops_map"];
    var S = D.ds_data;
    for (var i = 0; i < array_length(mapList); i++) {
        var nm  = mapList[i];
        var key = nm + "_string";

        // destroy old
        if (variable_global_exists(nm)) {
            var oldId = variable_global_get(nm);
            if (is_real(oldId) && ds_exists(oldId, ds_type_map)) ds_map_destroy(oldId);
        }
        // create new
        var newId = ds_map_create();
        if (is_struct(S) && variable_struct_exists(S, key)) {
            var blob = variable_struct_get(S, key);
            if (is_string(blob) && blob != "") {
                ds_map_read(newId, blob);
            }
        }
        variable_global_set(nm, newId);
    }

// 4) Unpause the game manager so obj_player's Step will run again
if (instance_exists(obj_game_manager)) {
    obj_game_manager.game_state = "playing";
    show_debug_message("[Load_Apply] obj_game_manager.game_state set to 'playing'");
}

// 5) Clean up Load Flags
global.isLoadingGame = false;
variable_global_set("pending_load_data", undefined);
}

/// @function scr_apply_instance_states()
/// @description Destroys any destructible blocks, loot, or pickups that were already consumed.
function scr_apply_instance_states() {
    // A) Destructible blocks
    if (ds_exists(global.broken_blocks_map, ds_type_map)) {
        with (obj_destructible_block) {
            if (ds_map_exists(global.broken_blocks_map, block_unique_key)) instance_destroy();
        }
    }
    // B) Loot drops
    if (ds_exists(global.loot_drops_map, ds_type_map)) {
        with (obj_loot_drop) {
            if (ds_map_exists(global.loot_drops_map, loot_key)) instance_destroy();
        }
    }
    // C) One-time pickups
    if (variable_global_exists("has_collected_main_echo_gem") && global.has_collected_main_echo_gem) {
        with (obj_pickup_echo_gem) instance_destroy();
    }
    if (variable_global_exists("has_collected_main_flurry_flower") && global.has_collected_main_flurry_flower) {
        with (obj_pickup_flurry_flower) instance_destroy();
    }
    if (variable_global_exists("has_collected_main_meteor_shard") && global.has_collected_main_meteor_shard) {
        with (obj_pickup_meteor_shard) instance_destroy();
    }
}

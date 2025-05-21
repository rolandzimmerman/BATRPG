/// @function scr_save_game(filename)
/// @description Serializes and writes game state (player, globals, DS maps, NPCs, party, instances) to JSON.
function scr_save_game(filename) {
    show_debug_message("[Save] Starting save to: " + filename);

    // 0) Ensure critical globals exist and are correct types
    if (!variable_global_exists("party_members") || !is_array(variable_global_get("party_members")))
        variable_global_set("party_members", []);
    if (!variable_global_exists("party_inventory") || !is_array(variable_global_get("party_inventory")))
        variable_global_set("party_inventory", []);
    var pcs = variable_global_exists("party_current_stats") ? variable_global_get("party_current_stats") : -1;
    if (!is_real(pcs) || !ds_exists(pcs, ds_type_map)) {
        if (is_real(pcs) && ds_exists(pcs, ds_type_map)) ds_map_destroy(pcs);
        pcs = ds_map_create();
        variable_global_set("party_current_stats", pcs);
    }
    var dsList = ["gate_states_map","recruited_npcs_map","broken_blocks_map","loot_drops_map","loot_drops_map"];
    for (var i=0; i<array_length(dsList); i++) {
        var nm = dsList[i];
        if (!variable_global_exists(nm) || !ds_exists(variable_global_get(nm), ds_type_map))
            variable_global_set(nm, ds_map_create());
    }

    // 1) Build data struct
    var data = {};

    // 1.a) Player
    if (instance_exists(obj_player)) {
        data.player = {
            x       : obj_player.x,
            y       : obj_player.y,
            room    : room_get_name(room),
            p_state : obj_player.player_state,
            f_dir   : obj_player.face_dir
        };
    }

    // 1.b) Simple globals
    data.globals = {};
    if (variable_global_exists("quest_stage"))    data.globals.quest_stage    = global.quest_stage;
    if (variable_global_exists("party_currency")) data.globals.party_currency = global.party_currency;

    // 1.c) DS maps → strings
    data.ds = {};
    var dsNames = ["gate_states_map","recruited_npcs_map","broken_blocks_map","loot_drops_map"];
    for (var i=0; i<array_length(dsNames); i++) {
        var nm = dsNames[i], key = nm + "_string", mid = variable_global_get(nm);
        if (is_real(mid) && ds_exists(mid, ds_type_map))
            variable_struct_set(data.ds, key, ds_map_write(mid));
        else
            variable_struct_set(data.ds, key, "");
    }

    // 1.d) NPCs
    data.npcs = {};
    if (instance_exists(obj_npc_parent)) {
        with (obj_npc_parent) {
            if (variable_instance_exists(id,"unique_npc_id") && unique_npc_id!="") {
                data.npcs[$ unique_npc_id] = {
                    x             : x,
                    y             : y,
                    visible       : visible,
                    has_spoken_to : (variable_instance_exists(id,"has_spoken_to")? has_spoken_to : false)
                };
            }
        }
    }

    // 1.e) Party arrays & stats
    data.party_members   = variable_global_get("party_members");
    data.party_inventory = variable_global_get("party_inventory");
    data.party_stats     = ds_map_write(variable_global_get("party_current_stats"));

    // 2) JSON stringify
    var json_out;
    try {
        json_out = json_stringify(data);
    } catch (e) {
        show_debug_message("[Save] JSON stringify failed: " + string(e));
        return false;
    }
    if (json_out == "" || json_out == undefined) {
        show_debug_message("[Save] JSON stringify returned empty or undefined string!");
        return false;
    }

    // 3) Write file
    var fh = file_text_open_write(filename);
    if (fh < 0) {
        show_debug_message("[Save] Could not open file: " + filename);
        return false;
    }
    file_text_write_string(fh, json_out);
    file_text_close(fh);

    show_debug_message("[Save] Success: wrote " + string(string_length(json_out)) + " bytes to " + filename);
    return true;
}
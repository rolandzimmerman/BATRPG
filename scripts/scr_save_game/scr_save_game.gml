/// @function scr_save_game(filename)
/// @description Serializes and writes game state to JSON file, saving the room by name.
function scr_save_game(filename) {
    show_debug_message("[Save] Starting save to: " + filename);

    // … your other global‐existence checks …

    // 1) Build the save struct
    var data = {};

    // 1.a) Player
    if (instance_exists(obj_player)) {
        data.player = {
            x      : obj_player.x,
            y      : obj_player.y,
            room   : room_get_name(room),
            p_state: obj_player.player_state,
            f_dir  : obj_player.face_dir
        };
    }

    // 1.b) Simple globals
    data.globals = {};
    if (variable_global_exists("quest_stage"))    data.globals.quest_stage    = variable_global_get("quest_stage");
    if (variable_global_exists("party_currency")) data.globals.party_currency = variable_global_get("party_currency");

    // 1.c) DS-map globals → JSON strings
    // ---------------------------------------------------
    data.ds = {};
    var dsNames = [
        "gate_states_map",
        "recruited_npcs_map",
        "broken_blocks_map",
        "loot_drops_map"
    ];
    for (var i = 0; i < array_length(dsNames); i++) {
        var nm  = dsNames[i];
        var key = nm + "_string";

        if (variable_global_exists(nm) 
         && ds_exists(variable_global_get(nm), ds_type_map)) {

            var json_str = ds_map_write(variable_global_get(nm));
            show_debug_message("[Save] DS Map '" + nm 
                + "' → length: " + string(string_length(json_str)));

            // *** Use the struct API to set it ***
            variable_struct_set(data.ds, key, json_str);

        } else {
            show_debug_message("[Save] WARNING: DS Map '" + nm + "' missing or invalid. Saving as empty string.");
            variable_struct_set(data.ds, key, "");
        }
    }
    show_debug_message("[Save] data.ds keys = " + string(variable_struct_get_names(data.ds)));


    // 1.d) NPCs
    data.npcs = {};
    with (obj_npc_parent) {
        if (variable_instance_exists(id, "unique_npc_id") && unique_npc_id != "") {
            data.npcs[$ unique_npc_id] = {
                x             : x,
                y             : y,
                visible       : visible,
                has_spoken_to : variable_instance_exists(id, "has_spoken_to") ? has_spoken_to : false
            };
        }
    }

    // 1.e) Party arrays & stats
    data.party_members   = variable_global_get("party_members");
    data.party_inventory = variable_global_get("party_inventory");
    data.party_stats     = ds_map_write(variable_global_get("party_current_stats"));

    // 2) JSON + write
    var json_out = json_stringify(data);
    var fh       = file_text_open_write(filename);
    file_text_write_string(fh, json_out);
    file_text_close(fh);

    show_debug_message("[Save] Wrote " + string(string_length(json_out)) + " bytes");
    return true;
}
/// @function scr_save_game(filename)
/// @description Serializes and writes game state to JSON file, saving the room by name.
/// @param filename {string}
/// @returns {bool}
function scr_save_game(filename) {
    show_debug_message("[Save] Starting save to: " + filename);

    //
    // 0) Ensure the three party globals exist and are valid types
    //
    if (!variable_global_exists("party_members") || !is_array(variable_global_get("party_members"))) {
        variable_global_set("party_members", []);
    }
    if (!variable_global_exists("party_inventory") || !is_array(variable_global_get("party_inventory"))) {
        variable_global_set("party_inventory", []);
    }
    if (!variable_global_exists("party_current_stats")
     || !is_real(variable_global_get("party_current_stats"))
     || !ds_exists(variable_global_get("party_current_stats"), ds_type_map)) {
        variable_global_set("party_current_stats", ds_map_create());
    }

    //
    // 1) Build the save_data struct
    //
    var data = {};

    // 1.a) Player position & room *name*
    if (instance_exists(obj_player)) {
        data.player = {
            x    : obj_player.x,
            y    : obj_player.y,
            room : room_get_name(room)
            // ADD VARIABLES CRITICAL FOR PLAYER STATE AND MOVEMENT
            // For example:
            // , player_state : obj_player.state // If you have a state machine like variable 'state'
            // , can_input    : obj_player.can_input // If you have an input flag
            // , current_hp   : obj_player.hp
        };
        show_debug_message("[Save] Player data to save: " + string(data.player));
    } else {
        show_debug_message("[Save] obj_player does not exist at save time. No player data saved.");
    }

    // 1.b) Simple globals
    data.globals = {};
    if (variable_global_exists("quest_stage")) {
        data.globals.quest_stage = variable_global_get("quest_stage");
    }
    if (variable_global_exists("party_currency")) {
        data.globals.party_currency = variable_global_get("party_currency");
    }
    // …add any other simple globals here…

    // 1.c) DS-map globals → JSON strings
    data.ds = {};
    var dsNames = [
        "gate_states_map",
        "recruited_npcs_map",
        "broken_blocks_map",
        "loot_drops_map"
    ];
    for (var i = 0; i < array_length(dsNames); i++) {
        var mn  = dsNames[i];
        var key = mn + "_string";
        if (variable_global_exists(mn)) {
            var mid = variable_global_get(mn);
            if (is_real(mid) && ds_exists(mid, ds_type_map)) {
                variable_struct_set(data.ds, key, ds_map_write(mid));
            } else {
                variable_struct_set(data.ds, key, "");
            }
        } else {
            variable_struct_set(data.ds, key, "");
        }
    }

    // 1.d) NPC states
    data.npcs = {};
    if (instance_exists(obj_npc_parent)) {
        with (obj_npc_parent) {
            if (variable_instance_exists(id, "unique_npc_id") && unique_npc_id != "") {
                data.npcs[$ unique_npc_id] = {
                    x             : x,
                    y             : y,
                    visible       : visible,
                    has_spoken_to : (variable_instance_exists(id, "has_spoken_to") ? has_spoken_to : false)
                };
            }
        }
    }

    // 1.e) Party arrays & stats
    data.party_members   = variable_global_get("party_members");
    data.party_inventory = variable_global_get("party_inventory");
    data.party_stats     = ds_map_write(variable_global_get("party_current_stats"));

    //
    // 2) JSON stringify
    //
    var json_out;
    try {
        json_out = json_stringify(data);
    } catch (e) {
        show_debug_message("[Save] JSON stringify failed: " + string(e));
        return false;
    }
    if (json_out == "") {
        show_debug_message("[Save] JSON stringify returned empty string!");
        return false;
    }

    //
    // 3) Write to disk
    //
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

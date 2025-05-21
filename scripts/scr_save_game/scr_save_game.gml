/// @function scr_save_game(filename)
/// @description Serializes and writes game state to JSON file
/// @param filename {string}
/// @returns {bool}
function scr_save_game(filename) {
    show_debug_message("[Save] Starting save to: " + filename);

    // 0) Guarantee party globals
    if (!variable_global_exists("party_members") 
     || !is_array(variable_global_get("party_members")))
    {
        variable_global_set("party_members", []);
    }
    if (!variable_global_exists("party_inventory") 
     || !is_array(variable_global_get("party_inventory")))
    {
        variable_global_set("party_inventory", []);
    }
    if (!variable_global_exists("party_current_stats")
     || !is_real(variable_global_get("party_current_stats"))
     || !ds_exists(variable_global_get("party_current_stats"), ds_type_map))
    {
        variable_global_set("party_current_stats", ds_map_create());
    }

    // 1) Build `data` struct
    var data = {};

    // 1.a) Player position/room
    if (instance_exists(obj_player)) {
        data.player = {
            x    : obj_player.x,
            y    : obj_player.y,
            room : room
        };
    }

    // 1.b) Simple globals
    data.globals = {};
    if (variable_global_exists("quest_stage")) {
        data.globals.quest_stage = variable_global_get("quest_stage");
    }
    if (variable_global_exists("party_currency")) {
        data.globals.party_currency = variable_global_get("party_currency");
    }
    // …add any additional simple globals…

// 1.c) DS-map globals → JSON strings
data.ds = {};  // a struct!

var dsNames = ["gate_states_map","recruited_npcs_map","broken_blocks_map","loot_drops_map"];
for (var i = 0; i < array_length(dsNames); i++) {
    var mn  = dsNames[i];
    var key = mn + "_string";

    if (variable_global_exists(mn)) {
        var mid = variable_global_get(mn);
        if (is_real(mid) && ds_exists(mid, ds_type_map)) {
            // Use variable_struct_set to write into data.ds dynamically
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
    data.party_members   = variable_global_get("party_members");   // guaranteed array
    data.party_inventory = variable_global_get("party_inventory"); // guaranteed array
    data.party_stats     = ds_map_write(variable_global_get("party_current_stats"));

    // 2) Stringify
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

    // 3) Write out
    var fh = file_text_open_write(filename);
    if (fh < 0) {
        show_debug_message("[Save] Could not open file: " + filename);
        return false;
    }
    file_text_write_string(fh, json_out);
    file_text_close(fh);

    return true;
}

/// @function scr_save_game(filename)
/// @description Serializes and writes game state to JSON file, saving the room by name.
/// @param filename {string}
function scr_save_game(filename) {
    show_debug_message("[Save] Starting save to: " + filename);

    // 1) Build the save struct
    var data = {}; // Use GML struct for the root save data

    // 1.a) Player
    if (instance_exists(obj_player)) {
        data.player = {
            x       : obj_player.x,
            y       : obj_player.y,
            room    : room_get_name(room),
            p_state : obj_player.player_state,
            f_dir   : obj_player.face_dir
        };
    } else {
        data.player = {}; 
        show_debug_message("[Save] Warning: obj_player instance not found. Saving empty player data.");
    }

    // 1.b) Simple globals
    data.globals = {}; 
    data.globals.quest_stage                 = variable_global_exists("quest_stage") ? global.quest_stage : 0;
    data.globals.party_currency              = variable_global_exists("party_currency") ? global.party_currency : 0;
    data.globals.has_collected_main_echo_gem      = variable_global_exists("has_collected_main_echo_gem") ? global.has_collected_main_echo_gem : false;
    data.globals.has_collected_main_flurry_flower = variable_global_exists("has_collected_main_flurry_flower") ? global.has_collected_main_flurry_flower : false;
    data.globals.has_collected_main_meteor_shard  = variable_global_exists("has_collected_main_meteor_shard") ? global.has_collected_main_meteor_shard : false;
    show_debug_message("[Save] Simple globals to save: " + json_stringify(data.globals));

    // 1.c) DS-map globals → JSON strings
    data.ds = {}; 
    var dsNames = [
        "gate_states_map",
        "recruited_npcs_map",
        "broken_blocks_map",
        "loot_drops_map"
    ];
    for (var i = 0; i < array_length(dsNames); i++) {
        var nm  = dsNames[i];
        var key_for_json = nm + "_string"; 

        if (variable_global_exists(nm) && ds_exists(variable_global_get(nm), ds_type_map)) {
            var map_id = variable_global_get(nm);
            var json_str = ds_map_write(map_id); // Still using ds_map_write for these
            show_debug_message("[Save] DS Map '" + nm + "' (" + string(ds_map_size(map_id)) + " entries) → string length: " + string(string_length(json_str)));
            variable_struct_set(data.ds, key_for_json, json_str);
        } else {
            show_debug_message("[Save] WARNING: Global DS Map '" + nm + "' missing or invalid. Saving as empty string.");
            variable_struct_set(data.ds, key_for_json, ""); 
        }
    }
    show_debug_message("[Save] data.ds keys saved = " + string(variable_struct_get_names(data.ds)));

    // 1.d) NPCs
    data.npcs = {}; 
    with (obj_npc_parent) { 
        if (variable_instance_exists(id, "unique_npc_id") && unique_npc_id != "") {
            var npc_save_data = {
                x             : x,
                y             : y,
                visible       : visible,
                has_spoken_to : (variable_instance_exists(id, "has_spoken_to") ? has_spoken_to : false)
            };
            data.npcs[$ unique_npc_id] = npc_save_data; 
        }
    }
    //show_debug_message("[Save] NPC data to save: " + string(instance_number(obj_npc_parent)) + " found, " + string(struct_count(data.npcs)) + " saved.");

    // ----------------------------------------------------------------------------------
    // SECTION 1.e) Party arrays & stats - MODIFIED FOR PARTY_STATS
    // ----------------------------------------------------------------------------------
    data.party_members   = (variable_global_exists("party_members") && is_array(global.party_members)) ? global.party_members : [];
    data.party_inventory = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];

    show_debug_message("[SaveGame] Preparing to save party_stats. Original global.party_current_stats ID: " 
        + string(global.party_current_stats) 
        + ", IsMap: " + string(ds_exists(global.party_current_stats, ds_type_map))
        + (ds_exists(global.party_current_stats, ds_type_map) ? (", Size: " + string(ds_map_size(global.party_current_stats))) : "")
    );
    
    // This stats_struct_for_json will hold sanitized character stat structs
    var stats_struct_for_json = {}; 

    if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
        show_debug_message("[SaveGame] CRITICAL: global.party_current_stats is not a valid DS map or does not exist! Saving empty party stats object.");
        // data.party_stats will be an empty JSON object string: "{}"
    } else {
        var character_keys_array = ds_map_keys_to_array(global.party_current_stats);
        
        for (var i = 0; i < array_length(character_keys_array); i++) {
            var char_key = character_keys_array[i];
            var original_char_value = global.party_current_stats[? char_key]; // Get the value (should be a struct)
        
            show_debug_message("[SaveGame] Processing stats for char_key: '" + char_key + "'. Original value type: " + typeof(original_char_value));
            
            if (is_undefined(original_char_value)) {
                show_debug_message("[SaveGame] WARNING: Value for char_key '" + char_key + "' in global.party_current_stats is UNDEFINED *before* sanitization.");
            }

            // Sanitize the character's stat data (which is expected to be a struct)
            var sanitized_value = scr_sanitize_data_for_ds_write(original_char_value);
            
            // Add the sanitized value (now a sanitized struct, or null) to our GML struct
            stats_struct_for_json[$ char_key] = sanitized_value; 
            
            show_debug_message("[SaveGame] Added sanitized value to GML struct for: '" + char_key + "'. Sanitized value type: " + typeof(sanitized_value));
        }
    }
    
    // Convert the GML struct (stats_struct_for_json) to a JSON string for data.party_stats
    // This replaces using ds_map_write for party_stats.
    data.party_stats = json_stringify(stats_struct_for_json); 
    show_debug_message("[SaveGame] Final party_stats string (from json_stringify): |" + data.party_stats + "|"); 
    // ----------------------------------------------------------------------------------
    // END OF MODIFIED SECTION 1.e
    // ----------------------------------------------------------------------------------

    // 2) JSON + write
    var json_out_string = json_stringify(data); 
    if (json_out_string == undefined || json_out_string == "") {
        show_debug_message("[Save] CRITICAL ERROR: json_stringify (for main data) produced empty or undefined output. Save aborted.");
        return false; 
    }

    var file_handle = file_text_open_write(filename);
    if (file_handle < 0) {
        show_debug_message("[Save] CRITICAL ERROR: Could not open file for writing: " + filename);
        return false;
    }
    file_text_write_string(file_handle, json_out_string);
    file_text_close(file_handle);

    show_debug_message("[Save] Successfully wrote " + string(string_length(json_out_string)) + " bytes to " + filename);
    return true;
}
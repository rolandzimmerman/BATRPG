/// obj_npc_recruitable_gabby :: User Event 0 (Interaction)
/// Handles recruiting Gabby: adds to party list, initializes persistent stats, and self-destructs.

var _char_key = variable_instance_exists(id, "character_key") ? character_key : "gabby";
var _can_still_recruit_locally = variable_instance_exists(id, "can_recruit") ? can_recruit : true;
// var _unique_id_for_debug = variable_instance_exists(id, "unique_npc_id") ? unique_npc_id : "N/A"; // If you keep unique_npc_id

show_debug_message("Interaction triggered for NPC: " + _char_key + " | Local can_recruit: " + string(_can_still_recruit_locally));

// Safeguard: Check if already in party (Create event should primarily handle this for persistence)
var _already_in_party_check_ue0 = false;
if (variable_global_exists("party_members") && is_array(global.party_members)) {
    for (var i = 0; i < array_length(global.party_members); i++) {
        if (global.party_members[i] == _char_key) { _already_in_party_check_ue0 = true; break; }
    }
}

if (_already_in_party_check_ue0) {
    show_debug_message(_char_key + " is already in global.party_members (checked in User Event 0). Showing post-recruit dialogue and ensuring instance is gone.");
    // Define or use existing post-recruit dialogue for Gabby
    if (variable_instance_exists(id,"dialogue_data_post_recruit")) { 
        dialogue_data = dialogue_data_post_recruit; 
    } else { 
        dialogue_data = [ { name: _char_key, msg: "Ready for action!" } ]; // Example Gabby post-recruit
    }
    if(script_exists(create_dialog)) create_dialog(dialogue_data);
    instance_destroy(); 
    exit;
}

// If can_recruit is true locally and not caught by the above party check
if (_can_still_recruit_locally) {
    // --- Not in party, proceed with recruitment ---
    show_debug_message("Recruiting " + _char_key + "!");
    
    // Add character to party list (ensure global.party_members exists)
    if (variable_global_exists("party_members") && is_array(global.party_members)) {
        array_push(global.party_members, _char_key);
        show_debug_message("Party is now: " + string(global.party_members));
    } else {
        show_debug_message("CRITICAL ERROR: global.party_members missing or not an array! Cannot add " + _char_key);
        exit; 
    }

    // --- Initialize persistent stats for this character ---
    if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
        if (!ds_map_exists(global.party_current_stats, _char_key)) { 
            show_debug_message(" -> Adding initial persistent stats for recruited character: " + _char_key);
            var _base_data = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_char_key) : undefined;
            if (is_struct(_base_data)) {
                var _xp_req = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
                var _skills_arr = variable_struct_exists(_base_data, "skills") && is_array(_base_data.skills) ? variable_clone(_base_data.skills, true) : [];
                var _equip_struct = variable_struct_exists(_base_data, "equipment") && is_struct(_base_data.equipment) ? variable_clone(_base_data.equipment, true) : { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
                var _resists_struct = variable_struct_exists(_base_data, "resistances") && is_struct(_base_data.resistances) ? variable_clone(_base_data.resistances, true) : { physical: 0 };
                var _initial_maxhp = variable_struct_get(_base_data, "hp_total") ?? 30; // Adjust Gabby's defaults if different
                var _initial_maxmp = variable_struct_get(_base_data, "mp_total") ?? 20; // Adjust Gabby's defaults
                
                var _initial_stats = {
                    hp:          _initial_maxhp, maxhp:       _initial_maxhp, 
                    mp:          _initial_maxmp, maxmp:       _initial_maxmp,
                    atk:         variable_struct_get(_base_data, "atk") ?? 7,   // Adjust Gabby's defaults
                    def:         variable_struct_get(_base_data, "def") ?? 5,   // Adjust Gabby's defaults
                    matk:        variable_struct_get(_base_data, "matk") ?? 10,  // Adjust Gabby's defaults
                    mdef:        variable_struct_get(_base_data, "mdef") ?? 8,   // Adjust Gabby's defaults
                    spd:         variable_struct_get(_base_data, "spd") ?? 7,    // Adjust Gabby's defaults
                    luk:         variable_struct_get(_base_data, "luk") ?? 6,   // Adjust Gabby's defaults
                    level:       1, xp: 0, xp_require: _xp_req,
                    skills:      _skills_arr, 
                    equipment:   _equip_struct,
                    resistances: _resists_struct, 
                    overdrive:   0, overdrive_max: 100,
                    name:        variable_struct_get(_base_data, "name") ?? _char_key, // Should be "Gabby" from _base_data
                    class:       variable_struct_get(_base_data, "class") ?? "Scout", // Example class for Gabby
                    character_key: _char_key
                };
                ds_map_add(global.party_current_stats, _char_key, _initial_stats);
                show_debug_message("     -> Added '" + _char_key + "' to global.party_current_stats map.");
            } else { show_debug_message("ERROR: Could not fetch base data for recruited character '" + _char_key + "'! Cannot add to stats map."); }
        } else { show_debug_message(" -> '" + _char_key + "' already exists in persistent stats map. Stats not re-initialized."); }
    } else { show_debug_message("ERROR: global.party_current_stats map missing during recruitment!"); }
    
    // Change local NPC state
    can_recruit = false; 
    
    // Set dialogue for successful recruitment
    if (variable_instance_exists(id,"dialogue_data_recruit")) { 
        dialogue_data = dialogue_data_recruit; 
    } else { 
        var char_display_name_success_gabby = (is_struct(_base_data) && variable_struct_exists(_base_data, "name")) ? _base_data.name : _char_key;
        dialogue_data = [ { name: "System", msg: string(char_display_name_success_gabby) + " joined your adventure!" } ]; // Example Gabby join message
    }
    if(script_exists(create_dialog)) create_dialog(dialogue_data); 
    
    // NPC disappears after recruitment
    instance_destroy(); 
    show_debug_message("NPC " + _char_key + " instance destroyed after recruitment.");
    
} else { 
    show_debug_message("NPC " + _char_key + " interaction, but _can_still_recruit_locally is false. Showing default/post dialogue.");
    if (variable_instance_exists(id,"dialogue_data_post_recruit")) { 
        dialogue_data = dialogue_data_post_recruit; 
    } else if (!variable_instance_exists(id,"dialogue_data")) { 
        dialogue_data = [ { name: _char_key, msg: "Good to see you!" } ]; // Example Gabby post-already-recruited talk
    }
    if(script_exists(create_dialog)) create_dialog(dialogue_data);
    // Consider if the instance should be destroyed here too if it's not supposed to be interactable post-initial recruitment
    // instance_destroy(); 
}
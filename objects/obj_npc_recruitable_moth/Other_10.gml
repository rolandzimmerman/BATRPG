/// obj_npc_recruitable_izzy :: User Event 0 (Interaction)
/// Handles recruiting Izzy: adds to party list, initializes persistent stats, and self-destructs.

var _char_key = variable_instance_exists(id, "character_key") ? character_key : "izzy";
var _can_still_recruit_locally = variable_instance_exists(id, "can_recruit") ? can_recruit : true;

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
    if (variable_instance_exists(id,"dialogue_data_post_recruit")) { 
        dialogue_data = dialogue_data_post_recruit; 
    } else { 
        dialogue_data = [ { name: _char_key, msg: "Adventure calls!" } ]; // Example Izzy post-recruit
    }
    if(script_exists(create_dialog)) create_dialog(dialogue_data);
    instance_destroy(); 
    exit;
}

// If can_recruit is true locally and not caught by the above party check
if (_can_still_recruit_locally) {
    // --- Not in party, proceed with recruitment ---
    show_debug_message("Recruiting " + _char_key + "!");
    
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
                var _initial_maxhp = variable_struct_get(_base_data, "hp_total") ?? 32;  // Example stats for Izzy
                var _initial_maxmp = variable_struct_get(_base_data, "mp_total") ?? 10;  // Example stats for Izzy
                
                var _initial_stats = {
                    hp:          _initial_maxhp, maxhp:       _initial_maxhp, 
                    mp:          _initial_maxmp, maxmp:       _initial_maxmp,
                    atk:         variable_struct_get(_base_data, "atk") ?? 10,  // Example stats for Izzy
                    def:         variable_struct_get(_base_data, "def") ?? 3,   // Example stats for Izzy
                    matk:        variable_struct_get(_base_data, "matk") ?? 5,   // Example stats for Izzy
                    mdef:        variable_struct_get(_base_data, "mdef") ?? 4,   // Example stats for Izzy
                    spd:         variable_struct_get(_base_data, "spd") ?? 8,    // Example stats for Izzy (e.g., a faster character)
                    luk:         variable_struct_get(_base_data, "luk") ?? 8,    // Example stats for Izzy
                    level:       1, xp: 0, xp_require: _xp_req,
                    skills:      _skills_arr, 
                    equipment:   _equip_struct,
                    resistances: _resists_struct, 
                    overdrive:   0, overdrive_max: 100,
                    name:        variable_struct_get(_base_data, "name") ?? _char_key, // Should be "Izzy" or "Moth" from base_data
                    class:       variable_struct_get(_base_data, "class") ?? "Thief", // Example class for Izzy
                    character_key: _char_key
                };
                ds_map_add(global.party_current_stats, _char_key, _initial_stats);
                show_debug_message("     -> Added '" + _char_key + "' to global.party_current_stats map.");
            } else { show_debug_message("ERROR: Could not fetch base data for recruited character '" + _char_key + "'! Cannot add to stats map."); }
        } else { show_debug_message(" -> '" + _char_key + "' already exists in persistent stats map. Stats not re-initialized."); }
    } else { show_debug_message("ERROR: global.party_current_stats map missing during recruitment!"); }
    
    can_recruit = false; 
    
    if (variable_instance_exists(id,"dialogue_data_recruit")) { 
        dialogue_data = dialogue_data_recruit; 
    } else { 
        // Your log for Claude used "Moth joined the party!" after it found Izzy's stats (Moth).
        // Let's use the actual character name if available.
        var char_display_name_success_izzy = (is_struct(_base_data) && variable_struct_exists(_base_data, "name")) ? _base_data.name : _char_key;
        dialogue_data = [ { name: "System", msg: string(char_display_name_success_izzy) + " has joined the team!" } ]; 
    }
    if(script_exists(create_dialog)) create_dialog(dialogue_data); 
    
    instance_destroy(); 
    show_debug_message("NPC " + _char_key + " instance destroyed after recruitment.");
    
} else { 
    show_debug_message("NPC " + _char_key + " interaction, but _can_still_recruit_locally is false. Showing default/post dialogue.");
    if (variable_instance_exists(id,"dialogue_data_post_recruit")) { 
        dialogue_data = dialogue_data_post_recruit; 
    } else if (!variable_instance_exists(id,"dialogue_data")) { 
        dialogue_data = [ { name: _char_key, msg: "What's up?" } ]; 
    }
    if(script_exists(create_dialog)) create_dialog(dialogue_data);
}
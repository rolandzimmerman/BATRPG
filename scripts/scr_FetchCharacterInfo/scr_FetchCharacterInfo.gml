/// @function scr_FetchCharacterInfo(_char_key)
/// @description Safely retrieves a DEEP COPY of the base data struct for a given character key.
///              It now attempts to ensure the .skills array contains only string keys.
/// @param {string} _char_key The unique key of the character (e.g., "hero", "claude").
/// @returns {Struct} A *deep copy* of the character data struct, or undefined if not found or invalid.
function scr_FetchCharacterInfo(_char_key) {
    // 1) Verify the global map exists
    if (!variable_global_exists("character_data")
     || !ds_exists(global.character_data, ds_type_map)) { // Assuming character_data is a ds_map
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: global.character_data (ds_map) not initialized!");
        return undefined;
    }

    // 2) Retrieve the base struct
    var _orig = ds_map_find_value(global.character_data, _char_key);
    if (!is_struct(_orig)) {
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: Invalid or missing data for key '"
                         + string(_char_key) + "'");
        return undefined;
    }

    // 3) Deep clone
    show_debug_message("🔍 Cloning character_info for key: " + string(_char_key));
    var _copy = variable_clone(_orig, true);
    if (!is_struct(_copy)) {
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: Clone failed for key '"
                         + string(_char_key) + "'");
        return undefined;
    }

// 4) NEW: Ensure _copy.skills contains only string keys
if (variable_struct_exists(_copy, "skills") && is_array(_copy.skills)) {
    show_debug_message("DEBUG [scr_FetchCharacterInfo]: BEFORE transformation, _copy.skills (" + string(array_length(_copy.skills)) + " entries) = " + string(_copy.skills));
    var _transformed_skills = [];

    for (var i = 0; i < array_length(_copy.skills); i++) {
        var _skill_entry = _copy.skills[i];
        show_debug_message("DEBUG [scr_FetchCharacterInfo]: --- Processing skill entry #" + string(i) + " ---");
        show_debug_message("DEBUG [scr_FetchCharacterInfo]: Original entry: " + string(_skill_entry));

        if (is_string(_skill_entry)) {
            show_debug_message("DEBUG [scr_FetchCharacterInfo]: Entry is a STRING. Adding '" + _skill_entry + "' to _transformed_skills.");
            array_push(_transformed_skills, _skill_entry);
        } else if (is_struct(_skill_entry)) {
            show_debug_message("DEBUG [scr_FetchCharacterInfo]: Entry is a STRUCT.");
            var _derived_key = undefined;
            var _struct_name_field = "N/A"; // For logging

            if (variable_struct_exists(_skill_entry, "name") && is_string(_skill_entry.name)) {
                _struct_name_field = _skill_entry.name;
            }
            show_debug_message("DEBUG [scr_FetchCharacterInfo]: Struct's 'name' field (if any): '" + _struct_name_field + "'");


            // Attempt 1: Check for 'id' field
            if (variable_struct_exists(_skill_entry, "id") && is_string(_skill_entry.id)) {
                _derived_key = _skill_entry.id;
                show_debug_message("DEBUG [scr_FetchCharacterInfo]: Attempt 1: Found 'id' field. _derived_key = '" + _derived_key + "'");
            }

            // Attempt 2: Check for 'key' field (if 'id' not found or not string)
            if (is_undefined(_derived_key) && variable_struct_exists(_skill_entry, "key") && is_string(_skill_entry.key)) {
                _derived_key = _skill_entry.key;
                show_debug_message("DEBUG [scr_FetchCharacterInfo]: Attempt 2: Found 'key' field. _derived_key = '" + _derived_key + "'");
            }

            // Attempt 3: Derive key from 'name' field (if 'id' and 'key' not found/valid)
            if (is_undefined(_derived_key) && variable_struct_exists(_skill_entry, "name") && is_string(_skill_entry.name)) {
                show_debug_message("DEBUG [scr_FetchCharacterInfo]: Attempt 3: Deriving key from 'name' field ('" + _skill_entry.name + "').");
                var _potential_key_from_name = string_lower(string_replace_all(_skill_entry.name, " ", "_"));
                show_debug_message("DEBUG [scr_FetchCharacterInfo]: Potential key from name: '" + _potential_key_from_name + "'");

                if (variable_global_exists("spell_db") && is_struct(global.spell_db)) {
                    if (variable_struct_exists(global.spell_db, _potential_key_from_name)) {
                        _derived_key = _potential_key_from_name;
                        show_debug_message("DEBUG [scr_FetchCharacterInfo]: Key '" + _derived_key + "' derived from name EXISTS in global.spell_db.");
                    } else {
                        show_debug_message("DEBUG [scr_FetchCharacterInfo]: Key '" + _potential_key_from_name + "' derived from name NOT found in global.spell_db.");
                    }
                } else {
                    show_debug_message("DEBUG [scr_FetchCharacterInfo]: global.spell_db not available for name-based key check.");
                }
            }

            if (!is_undefined(_derived_key)) {
                show_debug_message("DEBUG [scr_FetchCharacterInfo]: Successfully derived/found key: '" + _derived_key + "'. Adding to _transformed_skills.");
                array_push(_transformed_skills, _derived_key);
            } else {
                show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: For struct (name: '" + _struct_name_field + "'), string key could NOT be determined. Adding original struct to _transformed_skills as fallback.");
                array_push(_transformed_skills, _skill_entry); // Fallback: add the original struct
            }
        } else {
            show_debug_message("⚠️ WARNING [scr_FetchCharacterInfo]: Skill entry is neither a STRING nor a STRUCT: " + string(_skill_entry) + ". Adding original entry to _transformed_skills.");
            array_push(_transformed_skills, _skill_entry); // Fallback: add whatever it was
        }
        show_debug_message("DEBUG [scr_FetchCharacterInfo]: --- End processing entry #" + string(i) + ". Current _transformed_skills: " + string(_transformed_skills) + " ---");
    }
    _copy.skills = _transformed_skills;
    show_debug_message("DEBUG [scr_FetchCharacterInfo]: AFTER transformation, _copy.skills (" + string(array_length(_copy.skills)) + " entries) = " + string(_copy.skills));

} else {
    if (variable_struct_exists(_copy, "skills")) {
        show_debug_message("DEBUG [scr_FetchCharacterInfo]: _copy.skills exists but is not an array. Value: " + string(_copy.skills));
    } else {
        show_debug_message("DEBUG [scr_FetchCharacterInfo]: _copy.skills field does not exist.");
    }
}

    // 5) Return the deep copy (which includes cast_fx_sprite and now hopefully string-only skills)
    show_debug_message("✅ Character info cloned for: " + string(_char_key)
                     + " | cast_fx_sprite = " + string(_copy.cast_fx_sprite ?? "N/A") // Added ?? "N/A" for safety
                     + " | skills = " + string(_copy.skills ?? "N/A")); // Log the skills
    return _copy;
}
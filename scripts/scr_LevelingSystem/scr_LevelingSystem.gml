/// @function scr_GetXPForLevel(_level)
/// @description Returns the total XP required to reach the given level (i.e., the XP threshold for leveling up to `_level`).
/// @param {Real} _level  The target level (integer ≥ 1).
/// @returns {Real}       XP required to reach that level.
function scr_GetXPForLevel(_level) {
    // Level 1 always starts at 0 XP
    if (_level <= 1) {
        return 0;
    }

    // Example tiered table for levels 2–10; extend or adjust as needed
    switch (_level) {
        case 2:  return 100;
        case 3:  return 250;
        case 4:  return 450;
        case 5:  return 700;
        case 6:  return 1000;
        case 7:  return 1350;
        case 8:  return 1750;
        case 9:  return 2200;
        case 10: return 2700;
        default:
            // Past level 10, use a quadratic formula: base * level^2
            // You can tweak the multiplier (here 30) for pacing
            return floor(30 * _level * _level);
    }
}


/// @function scr_AddXPToCharacter(_char_key, _xp_gain)
/// @description Adds XP, handles level ups, updates stats, and teaches spells.
/// @param {String} _char_key Character key (“hero”, “claude”, “gabby”, “izzy”).
/// @param {Real}   _xp_gain  XP to add.
/// @returns {Struct} Struct with { leveled_up: Bool, new_spells: Array of Strings (spell names) }
function scr_AddXPToCharacter(_char_key, _xp_gain) {
    // — Early validation —
    if (!variable_global_exists("party_current_stats")
     || !ds_exists(global.party_current_stats, ds_type_map)) {
        show_debug_message("scr_AddXPToCharacter: Missing party_current_stats map");
        return { leveled_up: false, new_spells: [] }; // MODIFIED RETURN
    }
    var charStats = ds_map_find_value(global.party_current_stats, _char_key);
    if (!is_struct(charStats)) {
        show_debug_message("scr_AddXPToCharacter: No stats for “" + _char_key + "”");
        return { leveled_up: false, new_spells: [] }; // MODIFIED RETURN
    }

    // — Add XP & log —
    charStats.xp += _xp_gain;
    show_debug_message("Added " + string(_xp_gain)
                       + " XP to “" + _char_key + "”: now "
                       + string(charStats.xp) + "/" + string(charStats.xp_require));

    // — Per‐character gain presets —
    var gains;
    switch (_char_key) {
        case "hero":
            gains = {hp_base:6,hp_var:0, mp_base:4,mp_var:0, atk:2,def:2, matk:1,mdef:1, spd:1,luk:1};
            break;
        case "claude":
            gains = {hp_base:4,hp_var:0, mp_base:5,mp_var:0, atk:1,def:2, matk:2,mdef:2, spd:1,luk:1};
            break;
        case "gabby": // Assuming "gabby" might be a character key
            gains = {hp_base:3,hp_var:0, mp_base:6,mp_var:0, atk:1,def:1, matk:3,mdef:2, spd:1,luk:1};
            break;
        case "izzy": // Assuming "izzy" might be a character key
            gains = {hp_base:4,hp_var:0, mp_base:3,mp_var:0, atk:2,def:1, matk:1,mdef:1, spd:2,luk:2};
            break;
        default: // Fallback gains
            gains = {hp_base:5,hp_var:0, mp_base:2,mp_var:0, atk:1,def:1, matk:1,mdef:1, spd:1,luk:1};
            show_debug_message("Warning: scr_AddXPToCharacter using default gains for key: " + _char_key);
    }

    // — Try to build spell database once —
    var spellDB = undefined;
    var spellScriptIndex = asset_get_index("scr_BuildSpellDB");
    if (spellScriptIndex != -1 && script_exists(spellScriptIndex)) { // Check if script exists
        spellDB = scr_BuildSpellDB();
    } else {
        show_debug_message("Warning: scr_BuildSpellDB script not found or invalid.");
    }


    var leveled_up_this_call = false; // Tracks if any level up happened in this specific call
    var spells_learned_this_call = []; // To store names of spells learned in this call

    // Ensure xp_require is valid
    if (!variable_struct_exists(charStats, "xp_require") || charStats.xp_require <= 0) {
        // Attempt to set a sensible default if missing or invalid, e.g., for level 1 to 2
        charStats.xp_require = scr_GetXPForLevel((charStats.level ?? 1) + 1);
        show_debug_message("Warning: Invalid xp_require for " + _char_key + ". Reset to " + string(charStats.xp_require));
    }
    
    // — Level‐up loop —
    while (charStats.xp >= charStats.xp_require) {
        leveled_up_this_call = true; // A level up occurred
        if (!variable_struct_exists(charStats, "level")) charStats.level = 0; // Initialize level if it doesn't exist
        charStats.level++;
        var L = charStats.level;
        show_debug_message(_char_key + " reached level " + string(L));

        // — Apply stat gains —
        charStats.maxhp = (charStats.maxhp ?? 0) + gains.hp_base + irandom(gains.hp_var);
        charStats.maxmp = (charStats.maxmp ?? 0) + gains.mp_base + irandom(gains.mp_var);
        charStats.atk   = (charStats.atk ?? 0)   + gains.atk;
        charStats.def   = (charStats.def ?? 0)   + gains.def;
        charStats.matk  = (charStats.matk ?? 0)  + gains.matk;
        charStats.mdef  = (charStats.mdef ?? 0)  + gains.mdef;
        charStats.spd   = (charStats.spd ?? 0)   + gains.spd;
        charStats.luk   = (charStats.luk ?? 0)   + gains.luk;


        // — Restore HP/MP —
        charStats.hp = charStats.maxhp;
        charStats.mp = charStats.maxmp;

        // ——— Spell‐learning ———
        if (is_struct(spellDB)
         && variable_struct_exists(spellDB, "learning_schedule"))
        {
            var schedMap = spellDB.learning_schedule;
            if (ds_exists(schedMap, ds_type_map) // Ensure it's a map
             && ds_map_exists(schedMap, _char_key))
            {
                var charSched = ds_map_find_value(schedMap, _char_key);
                if (ds_exists(charSched, ds_type_map)) { // Ensure this is also a map
                    var lvlKey = string(L);
                    if (ds_map_exists(charSched, lvlKey)) {
                        var spellKey = ds_map_find_value(charSched, lvlKey);

                        if (variable_struct_exists(spellDB, spellKey)) {
                            var newSkill = variable_struct_get(spellDB, spellKey);
                            
                            // Ensure charStats.skills exists and is an array
                            if (!variable_struct_exists(charStats, "skills") || !is_array(charStats.skills)) {
                                charStats.skills = [];
                            }

                            // Check if skill already known to prevent duplicates
                            var already_known = false;
                            for (var s_idx = 0; s_idx < array_length(charStats.skills); s_idx++) {
                                if (is_struct(charStats.skills[s_idx]) && variable_struct_exists(charStats.skills[s_idx], "name") && charStats.skills[s_idx].name == newSkill.name) {
                                    already_known = true;
                                    break;
                                }
                            }
                            if (!already_known) {
                                array_push(charStats.skills, newSkill);
                                array_push(spells_learned_this_call, newSkill.name); // Store name of learned spell
                                show_debug_message(" Learned spell: " + newSkill.name);
                            }
                        } else {
                            show_debug_message("Warning: Spell key '" + spellKey + "' not found in spellDB for " + _char_key + " at level " + lvlKey);
                        }
                    }
                } else {
                     show_debug_message("Warning: Character schedule for '" + _char_key + "' is not a ds_map.");
                }
            }
        }


        // — Compute next XP threshold —
        charStats.xp_require = scr_GetXPForLevel(L + 1);
        show_debug_message(" Next XP req: " + string(charStats.xp_require));
         // Safety break for misconfigured xp_require, e.g. if scr_GetXPForLevel returns 0 or same value
        if (charStats.xp_require <= scr_GetXPForLevel(L)) {
            show_debug_message("CRITICAL WARNING: XP requirement did not increase for " + _char_key + " at L" + string(L) + ". Next req: " + string(charStats.xp_require) + ". Breaking level loop to prevent freeze.");
            charStats.xp_require = charStats.xp + 1; // Ensure XP is less than requirement to break loop
            break;
        }
    }

    return { leveled_up: leveled_up_this_call, new_spells: spells_learned_this_call }; // MODIFIED RETURN
}
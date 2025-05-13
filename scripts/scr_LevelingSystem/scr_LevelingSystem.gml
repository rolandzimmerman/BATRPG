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
/// @returns {Bool} True if a level up occurred.
function scr_AddXPToCharacter(_char_key, _xp_gain) {
    // — Early validation —
    if (!variable_global_exists("party_current_stats") 
     || !ds_exists(global.party_current_stats, ds_type_map)) {
        show_debug_message("scr_AddXPToCharacter: Missing party_current_stats map");
        return false;
    }
    var charStats = ds_map_find_value(global.party_current_stats, _char_key);
    if (!is_struct(charStats)) {
        show_debug_message("scr_AddXPToCharacter: No stats for “" + _char_key + "”");
        return false;
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
        case "gabby":
            gains = {hp_base:3,hp_var:0, mp_base:6,mp_var:0, atk:1,def:1, matk:3,mdef:2, spd:1,luk:1};
            break;
        case "izzy":
            gains = {hp_base:4,hp_var:0, mp_base:3,mp_var:0, atk:2,def:1, matk:1,mdef:1, spd:2,luk:2};
            break;
        default:
            gains = {hp_base:5,hp_var:0, mp_base:2,mp_var:0, atk:1,def:1, matk:1,mdef:1, spd:1,luk:1};
    }

    // — Try to build spell database once —
    var spellScriptIndex = asset_get_index("scr_BuildSpellDB");
    var spellDB = (spellScriptIndex != -1) 
                ? scr_BuildSpellDB() 
                : undefined;

    var leveled_up = false;
    // — Level‐up loop —
    while (charStats.xp >= charStats.xp_require) {
        leveled_up = true;
        charStats.level++;
        var L = charStats.level;
        show_debug_message(_char_key + " reached level " + string(L));

        // — Apply stat gains —
        charStats.maxhp += gains.hp_base + irandom(gains.hp_var);
        charStats.maxmp += gains.mp_base + irandom(gains.mp_var);
        charStats.atk   += gains.atk;
        charStats.def   += gains.def;
        charStats.matk  += gains.matk;
        charStats.mdef  += gains.mdef;
        charStats.spd   += gains.spd;
        charStats.luk   += gains.luk;

        // — Restore HP/MP —
        charStats.hp = charStats.maxhp;
        charStats.mp = charStats.maxmp;

// ——— Spell‐learning ———
if (is_struct(spellDB)
 && variable_struct_exists(spellDB, "learning_schedule"))
{
    var schedMap = spellDB.learning_schedule;
    if (ds_exists(schedMap, ds_type_map)
     && ds_map_exists(schedMap, _char_key))
    {
        var charSched = ds_map_find_value(schedMap, _char_key);
        if (ds_exists(charSched, ds_type_map)) {
            var lvlKey = string(L);
            if (ds_map_exists(charSched, lvlKey)) {
                var spellKey = ds_map_find_value(charSched, lvlKey);

                // Fetch the spell struct without using brackets
                if (variable_struct_exists(spellDB, spellKey)) {
                    var newSkill = variable_struct_get(spellDB, spellKey);
                    array_push(charStats.skills, newSkill);
                    show_debug_message(" Learned spell: " + newSkill.name);
                }
            }
        }
    }
}


        // — Compute next XP threshold —
        charStats.xp_require = scr_GetXPForLevel(L + 1);
        show_debug_message(" Next XP req: " + string(charStats.xp_require));
    }

    return leveled_up;
}

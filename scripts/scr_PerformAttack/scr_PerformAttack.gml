/// @function scr_PerformAttack(_attacker_inst, _target_inst)
/// @description Calculates and applies damage for a basic attack (enemy or player),
/// handles element/resistance, popups, overdrive gain, death, and battle-log.
/// Guards against missing struct fields (e.g. is_defending).
function scr_PerformAttack(_attacker_inst, _target_inst) {
    // --- Validate ---
    if (!instance_exists(_attacker_inst) || !variable_instance_exists(_attacker_inst, "data") || !is_struct(_attacker_inst.data)) {
        scr_AddBattleLog("Attack failed: invalid attacker");
        return false;
    }
    if (!instance_exists(_target_inst)     || !variable_instance_exists(_target_inst,     "data") || !is_struct(_target_inst.data)) {
        scr_AddBattleLog("Attack failed: invalid target");
        return false;
    }

    // --- Names & FX info ---
    var nameA = _attacker_inst.data.name ?? "Unknown";
    var nameT = _target_inst.data.name ?? "Unknown";
    var fx = script_exists(scr_GetWeaponAttackFX)
           ? scr_GetWeaponAttackFX(_attacker_inst)
           : { sprite: spr_pow, sound: snd_punch, element: (_attacker_inst.data.attack_element ?? "physical") };
    var element = fx.element ?? "physical";

    scr_AddBattleLog(nameA + " attacks " + nameT + " (" + element + ").");

    // --- Blind miss (attacker status) ---
    var st = script_exists(scr_GetStatus) ? scr_GetStatus(_attacker_inst) : undefined;
    if (is_struct(st) && st.effect == "blind") {
        scr_AddBattleLog(nameA + " is blinded, rolling miss chance…");
        if (irandom(99) < 50) {
            scr_AddBattleLog(nameA + " missed " + nameT + " due to blind.");
            // Optional Miss popup
            if (object_exists(obj_popup_damage)) {
                var layM = layer_get_id("Instances");
                if (layM != -1) {
                    var popM = instance_create_layer(_target_inst.x, _target_inst.y - 64, layM, obj_popup_damage);
                    if (popM != noone) popM.damage_amount = "Miss!";
                }
            }
            return true;
        }
        scr_AddBattleLog(nameA + " hit despite blind.");
    }

    // --- Base damage ---
    var atk = _attacker_inst.data.atk ?? 0;
    var def = _target_inst.data.def ?? 0;
    var base = max(1, atk - def);

    // --- Defend halving, only if the field exists ---
    if (variable_struct_exists(_target_inst.data, "is_defending")
     && _target_inst.data.is_defending) {
        base = max(1, floor(base / 2));
    }

    // --- Resistance multiplier ---
    var rm = 1.0;
    if (script_exists(GetResistanceMultiplier)
     && variable_struct_exists(_target_inst.data, "resistances")) {
        rm = GetResistanceMultiplier(_target_inst.data.resistances, element);
    }

    // --- Final damage & minimum rule ---
    var dmg = floor(base * rm);
    if (base >= 1 && rm > 0 && dmg < 1) {
        dmg = 1;
    }

    // --- Apply HP change ---
    var oldHP = _target_inst.data.hp;
    _target_inst.data.hp = max(0, oldHP - dmg);
    var dealt = oldHP - _target_inst.data.hp;
    scr_AddBattleLog(nameA + " did " + string(dealt) + " damage to " + nameT + ".");

    // --- Popup damage with color/suffix logic ---
    if (object_exists(obj_popup_damage)) {
        var lay = layer_get_id("Instances");
        if (lay != -1) {
            var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, lay, obj_popup_damage);
            if (pop != noone) {
                var suffix;
                var col;
                if (rm <= 0) {
                    suffix = "Immune";
                    col    = c_gray;
                }
                else if (rm < 0.9) {
                    suffix = string(dmg) + " (Resist)";
                    col    = c_aqua;
                }
                else if (rm > 1.1) {
                    suffix = string(dmg) + " (Weak!)";
                    col    = c_yellow;
                }
                else {
                    suffix = string(dmg);
                    col    = c_white;
                }
                pop.damage_amount = suffix;
                pop.text_color    = col;
            }
        }
    }

    // --- Clear defend flag if it existed ---
    if (variable_struct_exists(_target_inst.data, "is_defending")) {
        _target_inst.data.is_defending = false;
    }

    // --- Overdrive gain (only if both fields exist) ---
    if (variable_struct_exists(_target_inst.data, "overdrive")
     && variable_struct_exists(_target_inst.data, "overdrive_max")) {
        _target_inst.data.overdrive = min(_target_inst.data.overdrive + 3, _target_inst.data.overdrive_max);
    }

    // --- Death handling ---
    if (_target_inst.data.hp <= 0 && script_exists(scr_ProcessDeathIfNecessary)) {
        scr_ProcessDeathIfNecessary(_target_inst);
    }

    return true;
}

/// @function scr_PerformAttack(_attacker_inst, _target_inst)
/// @description Calculates and applies damage for a basic attack (enemy or player),
/// with element/resistance, critical hits, popups, overdrive gain, death, and battle-log.
/// Crit chance = 0.25% × attacker's LUK; crit multiplier = 1.5×.
/// Guards against missing struct fields (e.g. is_defending, luck).
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

    // --- Defend halving ---
    if (variable_struct_exists(_target_inst.data, "is_defending") && _target_inst.data.is_defending) {
        base = max(1, floor(base / 2));
    }

    // --- Resistance multiplier ---
    var rm = 1.0;
    if (script_exists(GetResistanceMultiplier) && variable_struct_exists(_target_inst.data, "resistances")) {
        rm = GetResistanceMultiplier(_target_inst.data.resistances, element);
    }

    // --- Preliminary damage (before crit) & minimum rule ---
    var dmg = floor(base * rm);
    if (base >= 1 && rm > 0 && dmg < 1) {
        dmg = 1;
    }

    // --- Critical hit roll ---
    var luck = _attacker_inst.data.luk ?? 0;
    var critChance = luck * 0.005; // 0.25% = 0.0025
    var isCrit = (random(1) < critChance);
    if (isCrit) {
        dmg = floor(dmg * 1.5);
        scr_AddBattleLog(nameA + " lands a CRITICAL HIT!");
    }

    // --- Apply HP change ---
    var oldHP = _target_inst.data.hp;
    _target_inst.data.hp = max(0, oldHP - dmg);
    var dealt = oldHP - _target_inst.data.hp;
    scr_AddBattleLog(nameA + " did " + string(dealt) + " damage to " + nameT + ".");

    // --- Popup damage & color/suffix logic ---
    if (object_exists(obj_popup_damage)) {
        var lay = layer_get_id("Instances");
        if (lay != -1) {
            var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, lay, obj_popup_damage);
            if (pop != noone) {
                var label, col;
                if (rm <= 0) {
                    label = "Immune"; col = c_gray;
                }
                else if (isCrit) {
                    label = string(dmg) + " (Crit!)"; col = c_red;
                }
                else if (rm < 0.9) {
                    label = string(dmg) + " (Resist)"; col = c_aqua;
                }
                else if (rm > 1.1) {
                    label = string(dmg) + " (Weak!)"; col = c_yellow;
                }
                else {
                    label = string(dmg); col = c_white;
                }
                pop.damage_amount = label;
                pop.text_color    = col;
            }
        }
    }

    // --- Clear defend flag ---
    if (variable_struct_exists(_target_inst.data, "is_defending")) {
        _target_inst.data.is_defending = false;
    }

    // --- Overdrive gain ---
    if (variable_struct_exists(_target_inst.data, "overdrive") && variable_struct_exists(_target_inst.data, "overdrive_max")) {
        _target_inst.data.overdrive = min(_target_inst.data.overdrive + 3, _target_inst.data.overdrive_max);
    }

    // --- Death handling ---
    if (_target_inst.data.hp <= 0 && script_exists(scr_ProcessDeathIfNecessary)) {
        scr_ProcessDeathIfNecessary(_target_inst);
    }

    return true;
}

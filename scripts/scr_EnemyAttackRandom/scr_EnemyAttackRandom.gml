/// @function scr_EnemyAttackRandom(_enemy_inst)
/// @description Enemy selects a random living player, handles bind/blind/shame, then delegates the actual hit to scr_PerformAttack.
/// @param {Id.Instance} _enemy_inst
/// @returns {Bool} true if the turn is consumed (even on a blind miss or status skip)
function scr_EnemyAttackRandom(_enemy_inst) {
    // 1. Validate Attacker
    if (!instance_exists(_enemy_inst) || !variable_instance_exists(_enemy_inst, "data") || !is_struct(_enemy_inst.data)) {
        show_debug_message("Warning [EnemyAI]: Invalid enemy instance.");
        return true;
    }
    var e_data = _enemy_inst.data;

    // 2. Status check
    var status = script_exists(scr_GetStatus) ? scr_GetStatus(_enemy_inst) : undefined;
    if (is_struct(status)) {
        if (status.effect == "shame") {
            show_debug_message(" -> Enemy shamed, skip.");
            return true;
        }
        if (status.effect == "bind" && irandom(99) < 50) {
            show_debug_message(" -> Enemy bound, skip.");
            return true;
        }
    }

    // 3. Choose random living player
    var living = [];
    if (ds_exists(global.battle_party, ds_type_list)) {
        for (var i = 0; i < ds_list_size(global.battle_party); i++) {
            var p = global.battle_party[| i];
            if (instance_exists(p) && is_struct(p.data) && p.data.hp > 0) {
                array_push(living, p);
            }
        }
    }
    if (array_length(living) == 0) {
        show_debug_message(" -> Enemy AI: No living targets.");
        return true;
    }
    var target = living[irandom(array_length(living) - 1)];

    // 4. Blind check → direct miss
    if (is_struct(status) && status.effect == "blind" && irandom(99) < 50) {
        show_debug_message(" -> Enemy attack missed due to Blind!");
        // optional: spawn a “Miss!” popup here if you want, or let scr_PerformAttack handle it
        return true;
    }

    // 5. Delegate to the unified attack routine
    //    scr_PerformAttack will handle element, damage, resistances, popups, overdrive, death, etc.
    var ok = scr_PerformAttack(_enemy_inst, target);
    return true; // turn consumed whether or not damage actually applied
}

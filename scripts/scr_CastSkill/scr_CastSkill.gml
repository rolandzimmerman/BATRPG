/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: checks/deducts cost, applies effects, logs hits/misses.
function scr_CastSkill(user, skill, target) {
    // --- Determine Names --- (Existing code)
    var casterName = "Unknown";
    if (instance_exists(user) && variable_instance_exists(user, "data") && is_struct(user.data)) {
        casterName = user.data.name ?? "Unknown";
    }
    var skillName = is_struct(skill) && variable_struct_exists(skill, "name") ? skill.name : "Unknown Skill";
    var targetName = casterName; // Default for self/party wide
    // For single target skills, get specific target name
    if (instance_exists(target) && variable_instance_exists(target, "data") && is_struct(target.data)) {
         // This will be updated if target_type is "enemy" or "ally" and target is provided
        if (skill.target_type == "enemy" || skill.target_type == "ally") {
             targetName = target.data.name ?? "Unknown";
        }
    }


    scr_AddBattleLog(casterName + " uses " + skillName + ".");

    // 1) Basic validation (Existing code)
    if (!instance_exists(user) || !variable_instance_exists(user, "data")) { return false; }
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) { return false; }

    // 2) Silence check (Existing code)
    var statusUser = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined;
    if (is_struct(statusUser) && statusUser.effect == "silence" && skill.effect != "heal_hp" && skill.effect != "heal_party") { // Allow healing party if silenced
        scr_AddBattleLog(casterName + " is silenced and cannot use " + skillName + ".");
        return false;
    }

    // 3) Determine final target for single-target skills (Existing code, slightly adjusted for clarity)
    var ttype = skill.target_type ?? "enemy";
    // A single target is needed if not self, all_allies, or all_enemies
    var needsSingleTarget = (ttype != "self" && ttype != "all_allies" && ttype != "all_enemies");
    var finalSingleTarget = needsSingleTarget ? target : user; // For single target skills

    // 4) Shame redirect (Existing code - applies to skills needing a single target)
    if (is_struct(statusUser) && statusUser.effect == "shame" && needsSingleTarget && irandom(99) < 50) {
        finalSingleTarget = user; // Shame redirects single target to self
        targetName = casterName; // Update target name for log
        scr_AddBattleLog("Shame redirects " + skillName + " to target themselves!");
    }

    // 5) Cost check (Existing code)
    var ud = user.data;
    var cost = skill.cost ?? 0;
    var isOD = variable_struct_exists(skill, "overdrive") && skill.overdrive;
    if (isOD) {
        if (!(variable_struct_exists(ud, "overdrive") && variable_struct_exists(ud, "overdrive_max") && ud.overdrive >= ud.overdrive_max)) {
            scr_AddBattleLog(casterName + " does not have enough Overdrive.");
            return false;
        }
        ud.overdrive = 0;
    } else {
        if (!(variable_struct_exists(ud, "mp") && ud.mp >= cost)) {
            scr_AddBattleLog(casterName + " does not have enough MP.");
            return false;
        }
        ud.mp -= cost;
    }

    // 6) Blind miss check for damage/status/steal skills (MODIFIED)
    // Skills that can "miss" a specific target due to blind.
    // Heal Party / Heal Self / Damage Enemies (AoE) typically don't "miss" in this way,
    // though individual enemies in an AoE might evade based on their own stats (handled elsewhere if needed).
    var missableSingleTargetSkills = ["damage_enemy", "blind", "bind", "shame", "webbed", "silence", "disgust", "steal_item"];
    if (needsSingleTarget && array_contains(missableSingleTargetSkills, skill.effect) &&
        is_struct(statusUser) && statusUser.effect == "blind" && irandom(99) < 50) { // 50% miss chance if blind
        scr_AddBattleLog(casterName + " missed " + targetName + " with " + skillName + " due to Blind.");
        return true; // Cost is paid, but effect missed
    }

    // 7) Apply effect and log
    var applied = false;
    switch (skill.effect) {
        case "heal_hp": { // Single target heal
            if (instance_exists(finalSingleTarget) && variable_instance_exists(finalSingleTarget, "data")) {
                var td = finalSingleTarget.data;
                var base = skill.heal_amount ?? 0;
                var ps = skill.power_stat ?? "matk";
                var val = variable_struct_get(ud, ps) ?? 0;
                var amt = floor(base + val * 0.5); // Example healing formula
                var old_hp = td.hp;
                td.hp = min(td.maxhp, td.hp + amt);
                var healed_amount = td.hp - old_hp;

                if (healed_amount > 0) {
                    scr_AddBattleLog(casterName + " heals " + string(healed_amount) + " HP on " + targetName + ".");
                    applied = true;
                } else {
                     scr_AddBattleLog(targetName + " is already at full HP or no healing was applied.");
                     applied = true; // Skill was used, even if no HP changed
                }
            }
        } break;

        case "heal_party": {
            scr_AddBattleLog(casterName + " casts " + skillName + " on the party!");
            var totalHealedThisCast = 0;
            // Assuming global.party_members is an array of player character instances
            if (is_array(global.party_members)) {
                for (var i = 0; i < array_length(global.party_members); i++) {
                    var party_member = global.party_members[i];
                    if (instance_exists(party_member) && variable_instance_exists(party_member, "data") && party_member.data.hp > 0) { // Check if alive
                        var member_data = party_member.data;
                        var member_name = member_data.name ?? "Ally";
                        var base = skill.heal_amount ?? 0;
                        var ps = skill.power_stat ?? "matk";
                        var val = variable_struct_get(ud, ps) ?? 0; // Caster's power
                        var amt = floor(base + val * 0.5);
                        var old_hp = member_data.hp;
                        member_data.hp = min(member_data.maxhp, member_data.hp + amt);
                        var healed_amount = member_data.hp - old_hp;

                        if (healed_amount > 0) {
                            scr_AddBattleLog(member_name + " recovers " + string(healed_amount) + " HP.");
                            totalHealedThisCast += healed_amount;
                        }
                    }
                }
            }
            applied = true; // Applied even if no one was healed (e.g., party full HP)
        } break;

        case "damage_enemy": { // Single target damage
             if (instance_exists(finalSingleTarget) && variable_instance_exists(finalSingleTarget, "data")) {
                var td = finalSingleTarget.data;
                // ... (rest of your existing single-target damage logic is good) ...
                // Ensure targetName is correctly set for the log based on finalSingleTarget
                var currentTargetName = variable_struct_get(td, "name") ?? "Enemy";

                var base = skill.damage ?? 0;
                var ps = skill.power_stat ?? "matk";
                var atkVal = variable_struct_get(ud, ps) ?? 0;
                var defKey = (ps == "matk") ? "mdef" : "def";
                var defVal = variable_struct_get(td, defKey) ?? 0;
                var calc = max(1, base + atkVal - defVal);

                if (is_struct(statusUser) && statusUser.effect == "disgust") { // Caster disgust
                    calc = floor(calc * 0.5);
                }
                // Target specific status like "vulnerable" could be checked here on 'td'

                var mult = 1.0;
                if (script_exists(GetResistanceMultiplier) && variable_struct_exists(td, "resistances")) {
                    mult = GetResistanceMultiplier(td.resistances, skill.element ?? "physical");
                }
                var finalD = floor(calc * mult);
                if (calc >= 1 && mult > 0 && finalD < 1) finalD = 1; // Ensure at least 1 damage if calc was >=1 and mult positive

                var oldHP = td.hp;
                td.hp = max(0, td.hp - finalD);
                var dealt = oldHP - td.hp;

                scr_AddBattleLog(casterName + " deals " + string(dealt) + " damage to " + currentTargetName + ".");
                
                if (mult > 1.5) scr_AddBattleLog("It's super effective!");
                if (mult < 0.75 && mult > 0) scr_AddBattleLog("It's not very effective...");
                if (mult == 0) scr_AddBattleLog(currentTargetName + " is immune!");


                if (script_exists(scr_ProcessDeathIfNecessary)) {
                    scr_ProcessDeathIfNecessary(finalSingleTarget);
                }
                applied = true;
            }
        } break;

        case "damage_enemies": {
            scr_AddBattleLog(casterName + " attacks all enemies with " + skillName + "!");
            var anyDamageDone = false;
            // Assuming global.enemy_troop is an array of enemy instances
            if (is_array(global.enemy_troop)) {
                for (var i = 0; i < array_length(global.enemy_troop); i++) {
                    var current_enemy = global.enemy_troop[i];
                    if (instance_exists(current_enemy) && variable_instance_exists(current_enemy, "data") && current_enemy.data.hp > 0) { // Check if alive
                        var td = current_enemy.data;
                        var currentTargetName = td.name ?? "Enemy";

                        var base = skill.damage ?? 0;
                        var ps = skill.power_stat ?? "matk"; // Caster's stat
                        var atkVal = variable_struct_get(ud, ps) ?? 0;
                        var defKey = (ps == "matk") ? "mdef" : "def"; // Target's defense
                        var defVal = variable_struct_get(td, defKey) ?? 0;
                        var calc = max(1, base + atkVal - defVal);
                        
                        if (is_struct(statusUser) && statusUser.effect == "disgust") { // Caster disgust
                             calc = floor(calc * 0.5);
                        }
                        // Target specific status like "vulnerable" could be checked here on 'td'

                        var mult = 1.0;
                        if (script_exists(GetResistanceMultiplier) && variable_struct_exists(td, "resistances")) {
                            mult = GetResistanceMultiplier(td.resistances, skill.element ?? "physical");
                        }
                        var finalD = floor(calc * mult);
                        if (calc >= 1 && mult > 0 && finalD < 1) finalD = 1;

                        var oldHP = td.hp;
                        td.hp = max(0, td.hp - finalD);
                        var dealt = oldHP - td.hp;

                        if (dealt > 0) {
                            scr_AddBattleLog(currentTargetName + " takes " + string(dealt) + " damage!");
                            if (mult > 1.5) scr_AddBattleLog("Super effective on " + currentTargetName + "!");
                            if (mult < 0.75 && mult > 0) scr_AddBattleLog("Not very effective on " + currentTargetName + "...");
                            if (mult == 0) scr_AddBattleLog(currentTargetName + " is immune!");
                            anyDamageDone = true;
                        } else if (mult == 0) {
                             scr_AddBattleLog(currentTargetName + " is immune!");
                        }


                        if (script_exists(scr_ProcessDeathIfNecessary)) {
                            scr_ProcessDeathIfNecessary(current_enemy);
                        }
                    }
                }
            }
            applied = true; // Applied even if no damage was dealt (e.g., all immune or 0 damage)
        } break;

        case "steal_item": {
            if (instance_exists(finalSingleTarget) && variable_instance_exists(finalSingleTarget, "data")) {
                var td = finalSingleTarget.data; // Target's data
                var currentTargetName = td.name ?? "Enemy";

                // Check if item already stolen from this specific enemy instance in this battle
                if (td.item_stolen_flag ?? false) {
                    scr_AddBattleLog(currentTargetName + " has nothing left to steal.");
                    applied = true;
                    break; 
                }

                var base_c = skill.base_chance ?? 25;
                var spd_f = skill.speed_factor ?? 0.5;
                var luk_f = skill.luck_factor ?? 1.0;
                
                var user_spd = ud.spd ?? 10; // Default if undefined
                var user_luk = ud.luk ?? 10; // Default if undefined
                
                var target_resist = td.steal_chance_resistance ?? 0; // Enemy specific resistance

                var steal_chance = base_c + (user_spd * spd_f) + (user_luk * luk_f) - target_resist;
                steal_chance = clamp(steal_chance, 5, 95); // Ensure chance is within reasonable bounds (e.g., 5% to 95%)

                scr_AddBattleLog(casterName + " attempts to steal from " + currentTargetName + "... (Chance: " + string(floor(steal_chance)) + "%)");

                if (random(100) < steal_chance) {
                    var item_id = td.stealable_item_id ?? "nothing"; // What item does the enemy have?
                    
                    if (item_id != "nothing" && script_exists(scr_PlayerAddItem)) {
                        scr_PlayerAddItem(item_id, 1); // Assumes scr_PlayerAddItem handles item name lookup if ID is like "potion_id"
                        scr_AddBattleLog("Success! Stole " + item_id + " from " + currentTargetName + "!");
                        td.item_stolen_flag = true; // Mark item as stolen from this instance
                    } else if (item_id == "nothing") {
                         scr_AddBattleLog(currentTargetName + " had nothing to steal.");
                    }
                     else {
                        scr_AddBattleLog("Success! ...but failed to register item (system error).");
                    }
                } else {
                    scr_AddBattleLog("Failed to steal from " + currentTargetName + ".");
                }
                applied = true;
            } else {
                scr_AddBattleLog("Invalid target for steal.");
            }
        } break;

        // Existing status effect cases (blind, bind, shame, etc.)
        case "blind": case "bind": case "shame":
        case "webbed": case "silence": case "disgust": {
            if (instance_exists(finalSingleTarget)) {
                var statusTargetName = (variable_instance_exists(finalSingleTarget,"data") && finalSingleTarget.data.name != undefined) ? finalSingleTarget.data.name : "Target";
                applied = scr_ApplyStatus(finalSingleTarget, skill.effect, skill.duration ?? 3);
                if (applied) {
                    scr_AddBattleLog(statusTargetName + " is afflicted with " + skill.effect + "!");
                } else {
                    scr_AddBattleLog(casterName + " failed to apply " + skill.effect + " to " + statusTargetName + ".");
                }
            }
        } break;
        
        // Default case for unknown effects
        default: {
            scr_AddBattleLog("Skill " + skillName + " has an unknown effect: " + string(skill.effect));
        } break;
    }

    // After applying effect, you might want to play sound/visual FX
    // This part would need access to the fx_sprite and fx_sound from the skill struct
    // and a way to instantiate visual effects at the target's or user's position.
    // Example:
    // if (applied && variable_struct_exists(skill, "fx_sprite")) {
    //     // Create FX object or particle system at finalSingleTarget.x, finalSingleTarget.y
    // }
    // if (variable_struct_exists(skill, "fx_sound")) {
    //     audio_play_sound(skill.fx_sound, 10, false);
    // }


    return applied;
}
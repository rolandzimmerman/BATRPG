/// obj_pickup_meteor_shard :: Step

// 1) Only run logic if not yet picked_up in this instance's lifetime
if (picked_up) {
    return;
}

// 2) Overlap check with the player
var p = instance_place(x, y, obj_player);
if (p == noone) {
    return; // No player, do nothing
}

// 3) Mark as picked_up for this instance to prevent re-triggering
picked_up = true;
show_debug_message("obj_pickup_meteor_shard: Player collision detected. Setting picked_up = true.");

// 4) Attempt to add the Meteor Shard to inventory
var added = scr_AddInventoryItem("meteor_shard", 1); // Item key for the shard
show_debug_message("obj_pickup_meteor_shard: scr_AddInventoryItem('meteor_shard', 1) returned: " + string(added));

// 5) If the item was successfully added to inventory
if (added) {
    show_debug_message("obj_pickup_meteor_shard: Meteor Shard successfully added to inventory.");

    // --- Play sound effect directly ---
    if (audio_exists(snd_item_get)) { // Use the direct asset name/ID
        audio_play_sound(snd_item_get, 10, false); 
        show_debug_message("obj_pickup_meteor_shard: Played snd_item_get (direct reference).");
    } else {
        show_debug_message("WARNING [obj_pickup_meteor_shard]: audio_exists(snd_item_get) returned FALSE. Sound asset not found or not loaded.");
    }
    // --- End Play sound effect ---

    // Set the global flag for non-respawn.
    if (variable_global_exists("has_collected_main_meteor_shard")) {
        global.has_collected_main_meteor_shard = true;
        show_debug_message("obj_pickup_meteor_shard: Set global.has_collected_main_meteor_shard = true.");
    } else {
        show_debug_message("WARNING [obj_pickup_meteor_shard]: global.has_collected_main_meteor_shard was not initialized prior to setting! Pickup might respawn if this was the first pickup ever.");
    }
    
    // 5a) Unlock "meteor_dive" skill in Persistent RPG stats (e.g., for Hero)
    // IMPORTANT: Ensure "meteor_dive" is a defined skill struct key in your global.spell_db
    // And that party_current_stats.hero.skills expects skill STRUCTS.
    var character_to_give_skill = "hero"; // Or configure as needed
    var skill_key_to_unlock = "meteor_dive";

    if (variable_global_exists("party_current_stats") &&
        ds_exists(global.party_current_stats, ds_type_map) &&
        ds_map_exists(global.party_current_stats, character_to_give_skill)) {
        var char_stats = ds_map_find_value(global.party_current_stats, character_to_give_skill);
        if (is_struct(char_stats) && variable_struct_exists(char_stats, "skills") && is_array(char_stats.skills)) {
            
            var skill_already_known = false;
            for (var i = 0; i < array_length(char_stats.skills); i++) {
                var skill_entry = char_stats.skills[i];
                if (is_struct(skill_entry) && 
                    ((variable_struct_exists(skill_entry, "id") && skill_entry.id == skill_key_to_unlock) ||
                     (variable_struct_exists(skill_entry, "name") && string_lower(skill_entry.name) == string_lower(skill_key_to_unlock)))) {
                    skill_already_known = true;
                    break;
                } else if (is_string(skill_entry) && skill_entry == skill_key_to_unlock) {
                    skill_already_known = true;
                    break;
                }
            }

            if (!skill_already_known) {
                var spell_db_ref = variable_global_exists("spell_db") ? global.spell_db : undefined;
                if (is_struct(spell_db_ref) && variable_struct_exists(spell_db_ref, skill_key_to_unlock)) {
                    var skill_struct_to_add = variable_struct_get(spell_db_ref, skill_key_to_unlock);
                    array_push(char_stats.skills, skill_struct_to_add);
                    show_debug_message("DEBUG: Added '" + skill_key_to_unlock + "' STRUCT to persistent " + character_to_give_skill + "_stats.skills");
                } else {
                    show_debug_message("DEBUG: Could not add '" + skill_key_to_unlock + "' STRUCT to " + character_to_give_skill + "_stats.skills (spell_db or skill missing).");
                }
            }
        }
    }

    // 5b) Unlock "meteor_dive" skill for any currently‐active battle instance of that character
    with (obj_battle_player) {
        if (character_key == character_to_give_skill &&
            is_struct(data) && variable_struct_exists(data, "skills") && is_array(data.skills)) {
            
            var battle_skill_already_known = false;
            for (var i = 0; i < array_length(data.skills); i++) {
                var b_skill_entry = data.skills[i];
                 if (is_struct(b_skill_entry) && 
                    ((variable_struct_exists(b_skill_entry, "id") && b_skill_entry.id == skill_key_to_unlock) ||
                     (variable_struct_exists(b_skill_entry, "name") && string_lower(b_skill_entry.name) == string_lower(skill_key_to_unlock)))) {
                    battle_skill_already_known = true;
                    break;
                }
            }

            if (!battle_skill_already_known) {
                 var spell_db_ref_battle = variable_global_exists("spell_db") ? global.spell_db : undefined;
                if (is_struct(spell_db_ref_battle) && variable_struct_exists(spell_db_ref_battle, skill_key_to_unlock)) {
                    array_push(data.skills, variable_struct_get(spell_db_ref_battle, skill_key_to_unlock));
                    show_debug_message("DEBUG: Added '" + skill_key_to_unlock + "' STRUCT to live battler " + character_key + " instance: " + string(id));
                } else {
                     show_debug_message("DEBUG: Could not add '" + skill_key_to_unlock + "' STRUCT to live battler (spell_db or skill missing). ID: " + string(id));
                }
            }
        }
    }
}

// 6) Notify the player
if (script_exists(create_dialog)) {
    create_dialog([
        { 
            name: "", 
            msg: added ? "You got the Meteor Shard! Press Y to use Meteor Dive." : "You already have a Meteor Shard." 
        }
    ]);
} else {
    show_debug_message("WARNING: create_dialog script not found. Cannot show pickup message for Meteor Shard.");
}

// 7) Clean up the pickup object from the room
instance_destroy();
show_debug_message("obj_pickup_meteor_shard: Instance destroyed after interaction.");
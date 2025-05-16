/// obj_pickup_echo_gem :: Step

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
show_debug_message("obj_pickup_echo_gem: Player collision detected. Setting picked_up = true.");

// 4) Attempt to add the Echo Gem to inventory
var added = scr_AddInventoryItem("echo_gem", 1);
show_debug_message("obj_pickup_echo_gem: scr_AddInventoryItem('echo_gem', 1) returned: " + string(added));

// 5) If the item was successfully added to inventory
if (added) {
    show_debug_message("obj_pickup_echo_gem: Echo Gem successfully added to inventory.");

    // --- MODIFICATION START: Directly play sound effect ---
    // Make sure 'snd_item_get' is the exact name of your sound asset in the Asset Browser.
    if (audio_exists(snd_item_get)) { // Use the asset name directly (it's its ID)
        audio_play_sound(snd_item_get, 10, false); // Play at priority 10, not looping
        show_debug_message("obj_pickup_echo_gem: Played snd_item_get (direct reference).");
    } else {
        // This means the sound asset 'snd_item_get' (by its direct ID) is not available.
        // Reasons could be:
        // 1. The asset name 'snd_item_get' is misspelled or doesn't exist in your Asset Browser.
        // 2. The sound is in an Audio Group that isn't loaded.
        // 3. The sound file is not included in the build for your target platform.
        // 4. The sound file itself might be corrupted.
        show_debug_message("WARNING [obj_pickup_echo_gem]: audio_exists(snd_item_get) returned FALSE. Sound asset not found or not loaded. Please verify asset name, audio groups, and included files.");
    }
    // --- MODIFICATION END ---

    // Set the global flag indicating this specific Echo Gem has been collected for non-respawn.
    // Ensure global.has_collected_main_echo_gem is initialized to false at game start.
    if (variable_global_exists("has_collected_main_echo_gem")) { // Check if it was initialized
        global.has_collected_main_echo_gem = true;
        show_debug_message("obj_pickup_echo_gem: Set global.has_collected_main_echo_gem = true.");
    } else {
        show_debug_message("WARNING [obj_pickup_echo_gem]: global.has_collected_main_echo_gem was not initialized. Pickup will likely respawn.");
    }


    // 5a) Persistent RPG stats
    if (variable_global_exists("party_current_stats") &&
        ds_exists(global.party_current_stats, ds_type_map) &&
        ds_map_exists(global.party_current_stats, "hero")) {
        var hero_stats = ds_map_find_value(global.party_current_stats, "hero");
        if (is_struct(hero_stats) && variable_struct_exists(hero_stats, "skills") && is_array(hero_stats.skills)) {
            var skill_key_present = false;
            for (var k=0; k < array_length(hero_stats.skills); k++){
                // Assuming hero_stats.skills stores skill structs or identifiable skill keys
                var current_skill_entry = hero_stats.skills[k];
                if (is_string(current_skill_entry) && current_skill_entry == "echo_wave") {
                    skill_key_present = true; break;
                } else if (is_struct(current_skill_entry) && ( (variable_struct_exists(current_skill_entry, "id") && current_skill_entry.id == "echo_wave") || (variable_struct_exists(current_skill_entry, "name") && string_lower(current_skill_entry.name) == "echo wave") ) ) {
                    skill_key_present = true; break;
                }
            }
            if (!skill_key_present) {
                var spell_db_ref = variable_global_exists("spell_db") ? global.spell_db : undefined;
                if (is_struct(spell_db_ref) && variable_struct_exists(spell_db_ref, "echo_wave")) {
                    array_push(hero_stats.skills, variable_struct_get(spell_db_ref, "echo_wave"));
                    show_debug_message("DEBUG: Added echo_wave STRUCT to persistent hero_stats.skills");
                } else {
                    // Fallback or error: adding key if struct not found
                    array_push(hero_stats.skills, "echo_wave"); 
                    show_debug_message("DEBUG: Added echo_wave KEY to persistent hero_stats.skills (spell_db or 'echo_wave' skill struct missing).");
                }
            }
        }
    }

    // 5b) Any currently‐active battle instance
    with (obj_battle_player) {
        if (character_key == "hero" &&
            is_struct(data) && variable_struct_exists(data, "skills") && is_array(data.skills)) {
            var battle_skill_present = false;
            for (var k=0; k < array_length(data.skills); k++){
                var current_battle_skill_entry = data.skills[k];
                 if (is_struct(current_battle_skill_entry) && ( (variable_struct_exists(current_battle_skill_entry, "id") && current_battle_skill_entry.id == "echo_wave") || (variable_struct_exists(current_battle_skill_entry, "name") && string_lower(current_battle_skill_entry.name) == "echo wave") ) ) { 
                    battle_skill_present = true; break;
                }
            }
            if (!battle_skill_present) {
                 var spell_db_ref_battle = variable_global_exists("spell_db") ? global.spell_db : undefined;
                if (is_struct(spell_db_ref_battle) && variable_struct_exists(spell_db_ref_battle, "echo_wave")) {
                    array_push(data.skills, variable_struct_get(spell_db_ref_battle, "echo_wave"));
                    show_debug_message("DEBUG: Added echo_wave STRUCT to live hero battler instance: " + string(id));
                } else {
                     show_debug_message("DEBUG: Could not add echo_wave STRUCT to live hero (spell_db or 'echo_wave' skill struct missing). ID: " + string(id));
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
            msg: added ? "You got the Echo Gem! Press X to fire the Echo Wave. Select it in combat by pressing X to bring up the skills menu!" : "You already have an Echo Gem." 
        }
    ]);
} else {
    show_debug_message("WARNING: create_dialog script not found. Cannot show pickup message.");
}

// 7) Clean up the pickup object from the room
instance_destroy();
show_debug_message("obj_pickup_echo_gem: Instance destroyed after interaction.");
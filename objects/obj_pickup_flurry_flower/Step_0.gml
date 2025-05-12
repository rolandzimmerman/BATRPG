/// obj_pickup_flurry_flower :: Step

// 1) Only run once
if (picked_up) return;

// 2) Overlap check
var p = instance_place(x, y, obj_player);
if (p == noone) return;

// 3) Mark so we don’t run again
picked_up = true;

// 4) Add the Flurry Flower to inventory
var added = scr_AddInventoryItem("flurry_flower", 1);

// 5) If we actually added one, unlock the spell in all relevant data
if (added) {
    // 5a) Persistent RPG stats (used to seed battler.data.skills)
    if (variable_global_exists("party_current_stats")
     && ds_exists(global.party_current_stats, ds_type_map)
     && ds_map_exists(global.party_current_stats, "hero"))
    {
        var hero_stats = ds_map_find_value(global.party_current_stats, "hero");
        if (is_struct(hero_stats)
         && is_array(hero_stats.skills)
         && array_index_of(hero_stats.skills, "flower_flurry") == -1)
        {
            array_push(hero_stats.skills, "flower_flurry");
            show_debug_message("DEBUG: Added flower_flurry to persistent hero_stats.skills -> "
                + string(hero_stats.skills));
        }
    }

    // 5b) Any currently‐active battle instance
    with (obj_battle_player) {
        if (character_key == "hero"
         && is_struct(data)
         && is_array(data.skills)
         && array_index_of(data.skills, "flower_flurry") == -1)
        {
            array_push(data.skills, "flower_flurry");
            show_debug_message("DEBUG: Added flower_flurry to live battler.data.skills -> "
                + string(data.skills));
        }
    }
}

// 6) Notify the player (regardless of added or not, but you can guard it if you prefer)
create_dialog([
    { name: "", 
      msg: added
        ? "You got the Flurry Flower! Press the left and right bumpers to dash with Flower Flurry."
        : "You already have an Flurry Flower."
    }
]);

// 7) Clean up the pickup so it can’t be used again
instance_destroy();

/// @description Applies loaded_data when load_pending is true
if (global.load_pending) {
    var d = global.loaded_data;

    // A) Restore simple globals
    if (variable_struct_exists(d, "globals")) {
        var g = d.globals;
        if (variable_struct_exists(g, "quest_stage"))    global.quest_stage    = g.quest_stage;
        if (variable_struct_exists(g, "party_currency")) global.party_currency = g.party_currency;
        // …restore any other simple globals here…
    }

    // B) Restore DS-map globals
    if (variable_struct_exists(d, "ds")) {
        var ds = d.ds;

        // Gate States
        if (variable_struct_exists(ds, "gate_states_map_string")) {
            var s = ds.gate_states_map_string;
            var m = ds_map_create();
            ds_map_read(m, s);
            global.gate_states_map = m;
        }
        // Recruited NPCs
        if (variable_struct_exists(ds, "recruited_npcs_map_string")) {
            var s2 = ds.recruited_npcs_map_string;
            var m2 = ds_map_create();
            ds_map_read(m2, s2);
            global.recruited_npcs_map = m2;
        }
        // Broken Blocks
        if (variable_struct_exists(ds, "broken_blocks_map_string")) {
            var s3 = ds.broken_blocks_map_string;
            var m3 = ds_map_create();
            ds_map_read(m3, s3);
            global.broken_blocks_map = m3;
        }
        // Loot Drops
        if (variable_struct_exists(ds, "loot_drops_map_string")) {
            var s4 = ds.loot_drops_map_string;
            var m4 = ds_map_create();
            ds_map_read(m4, s4);
            global.loot_drops_map = m4;
        }
    }

    // C) Restore NPC states (optional, if you handle them)
    // d.npcs[? id] holds each NPC's {x,y,visible,has_spoken_to}

    // D) Restore party data
    if (variable_struct_exists(d, "party_members")) {
        global.party_members = d.party_members;
    }
    if (variable_struct_exists(d, "party_inventory")) {
        global.party_inventory = d.party_inventory;
    }
    if (variable_struct_exists(d, "party_stats")) {
        var sm = ds_map_create();
        ds_map_read(sm, d.party_stats);
        global.party_current_stats = sm;
    }

    // E) Restore player position
    if (variable_struct_exists(d, "player")) {
        var p = d.player;
        if (instance_exists(obj_player)) {
            obj_player.x = p.x;
            obj_player.y = p.y;
        }
    }

    // Cleanup flags and schedule one-frame reset
    global.load_pending = false;
    global.loaded_data  = undefined;
    alarm[0]            = 1;
}

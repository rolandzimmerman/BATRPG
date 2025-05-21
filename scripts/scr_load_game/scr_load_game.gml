/// @function scr_load_game(filename)
/// @description Deserializes and reads game state from JSON file, loading the room by name.
/// @param filename {string}
/// @returns {bool}
function scr_load_game(filename) {
    show_debug_message("[Load] Starting load from: " + filename);

    //
    // 1) Read from disk
    //
    if (!file_exists(filename)) {
        show_debug_message("[Load] File not found: " + filename);
        return false;
    }

    var fh = file_text_open_read(filename);
    if (fh < 0) {
        show_debug_message("[Load] Could not open file: " + filename);
        return false;
    }
    var json_in = "";
    while (!file_text_eof(fh)) {
        json_in += file_text_read_string(fh);
        file_text_readln(fh); // Read the newline character
    }
    file_text_close(fh);

    if (json_in == "") {
        show_debug_message("[Load] File was empty: " + filename);
        return false;
    }

    //
    // 2) JSON parse
    //
    var data;
    try {
        data = json_parse(json_in);
    } catch (e) {
        show_debug_message("[Load] JSON parse failed: " + string(e));
        return false;
    }

    if (!is_struct(data)) {
        show_debug_message("[Load] Parsed JSON is not a struct.");
        return false;
    }
    show_debug_message("[Load] JSON parsed successfully.");

    //
    // 3) Restore game state
    //

    // 3.a) Ensure party globals are initialized (as in save script, in case they weren't already)
    //      This is crucial if loading from a state where these weren't saved or are corrupt.
    if (!variable_global_exists("party_members") || !is_array(variable_global_get("party_members"))) {
        variable_global_set("party_members", []);
    }
    if (!variable_global_exists("party_inventory") || !is_array(variable_global_get("party_inventory"))) {
        variable_global_set("party_inventory", []);
    }
    if (!variable_global_exists("party_current_stats")
     || !is_real(variable_global_get("party_current_stats"))
     || !ds_exists(variable_global_get("party_current_stats"), ds_type_map)) {
        // If a map already exists, destroy it before creating a new one to prevent memory leaks
        if (variable_global_exists("party_current_stats") && is_real(variable_global_get("party_current_stats")) && ds_exists(variable_global_get("party_current_stats"), ds_type_map)) {
            ds_map_destroy(variable_global_get("party_current_stats"));
        }
        variable_global_set("party_current_stats", ds_map_create());
    } else {
        // Clear existing map if it's valid, to ensure fresh data is loaded
        ds_map_clear(variable_global_get("party_current_stats"));
    }


    // 3.b) Simple globals
    if (variable_struct_exists(data, "globals")) {
        var _globals = data.globals;
        if (variable_struct_exists(_globals, "quest_stage")) {
            variable_global_set("quest_stage", _globals.quest_stage);
        }
        if (variable_struct_exists(_globals, "party_currency")) {
            variable_global_set("party_currency", _globals.party_currency);
        }
        // …add any other simple globals here…
    }

    // 3.c) DS-map globals ← JSON strings
    if (variable_struct_exists(data, "ds")) {
        var _ds_data = data.ds;
        var dsNames = [
            "gate_states_map",
            "recruited_npcs_map",
            "broken_blocks_map",
            "loot_drops_map"
        ];
        for (var i = 0; i < array_length(dsNames); i++) {
            var mn = dsNames[i];
            var key = mn + "_string";
            if (variable_struct_exists(_ds_data, key)) {
                var map_string = _ds_data[$ key];
                if (map_string != "") {
                    // Destroy existing map if it exists, to prevent memory leaks
                    if (variable_global_exists(mn)) {
                        var old_map_id = variable_global_get(mn);
                        if (is_real(old_map_id) && ds_exists(old_map_id, ds_type_map)) {
                            ds_map_destroy(old_map_id);
                        }
                    }
                    var new_map_id = ds_map_create();
                    ds_map_read(new_map_id, map_string);
                    variable_global_set(mn, new_map_id);
                } else {
                    // If the string is empty, ensure the global map is also empty or a new empty map
                    if (variable_global_exists(mn)) {
                         var old_map_id = variable_global_get(mn);
                        if (is_real(old_map_id) && ds_exists(old_map_id, ds_type_map)) {
                            ds_map_clear(old_map_id); // Clear it
                        } else { // Or it wasn't a valid map, so create a new empty one
                            variable_global_set(mn, ds_map_create());
                        }
                    } else {
                        variable_global_set(mn, ds_map_create());
                    }
                }
            }
        }
    }

    // 3.d) Party arrays & stats
    if (variable_struct_exists(data, "party_members")) {
        variable_global_set("party_members", data.party_members);
    }
    if (variable_struct_exists(data, "party_inventory")) {
        variable_global_set("party_inventory", data.party_inventory);
    }
    if (variable_struct_exists(data, "party_stats")) {
        var party_stats_string = data.party_stats;
        if (party_stats_string != "") {
            // The party_current_stats map should have been initialized/cleared in step 3.a
            ds_map_read(variable_global_get("party_current_stats"), party_stats_string);
        }
    }

    //
    // 4) Room transition and Player/NPC state (MUST be done after other globals are loaded)
    //
    var target_room_asset = -1;
    if (variable_struct_exists(data, "player") && variable_struct_exists(data.player, "room")) {
        target_room_asset = asset_get_index(data.player.room);
    }

    if (target_room_asset != -1 && room_exists(target_room_asset)) {
        // Set up a persistent controller object or use a global struct to pass load data to the next room
        // This is because instance variables are reset on room_goto
        // We'll use a temporary global struct for this example
        global.pending_load_data = {
            player_data : variable_struct_exists(data, "player") ? data.player : undefined,
            npc_data    : variable_struct_exists(data, "npcs") ? data.npcs : undefined
        };
        
        // Add a marker to indicate a load is in progress
        global.isLoadingGame = true; 

        room_goto(target_room_asset);
        // The actual restoration of player/NPC positions will happen in the Room Start event
        // or a persistent controller's Room Start event, after the new room is loaded.
    } else {
        show_debug_message("[Load] Target room '" + (variable_struct_exists(data, "player") ? data.player.room : "undefined") + "' not found or invalid. Game state partially loaded.");
        // If no room change, attempt to apply NPC states to current room if applicable
        // This scenario might be undesirable, consider if this is the correct fallback.
        if (variable_struct_exists(data, "npcs")) {
            apply_npc_states(data.npcs); // You'll need to implement this helper function
        }
         // And player position if player exists in current room
        if (instance_exists(obj_player) && variable_struct_exists(data, "player")) {
            obj_player.x = data.player.x;
            obj_player.y = data.player.y;
        }
        global.isLoadingGame = false; // No room change, loading considered complete for current context
        return true; // Or false, depending on how critical the room change is
    }

    show_debug_message("[Load] Success: Game state loaded. Room transition initiated if applicable.");
    return true;
}

/// @function scr_apply_post_load_state()
/// @description Applies loaded player and NPC states after a room transition.
///              Handles instance activation and game unpausing.
///              Should be called from a persistent controller's Room Start event.
function scr_apply_post_load_state() {
    show_debug_message("[Load_Apply] scr_apply_post_load_state called in room: " + room_get_name(room));

    // This flag will be checked by obj_player's Room Start event.
    // It's set to true only if player data is successfully found and applied by this script.
    global.player_state_loaded_this_frame = false;

    if (!variable_global_exists("isLoadingGame") || !global.isLoadingGame) {
        show_debug_message("[Load_Apply] Not currently loading a game (isLoadingGame is false). Aborting.");
        return;
    }
    if (!variable_global_exists("pending_load_data") || !is_struct(global.pending_load_data)) {
        show_debug_message("[Load_Apply] pending_load_data is missing or not a struct. Cleaning up and aborting.");
        global.isLoadingGame = false; // Critical: Reset flag if data is bad
        variable_global_set("pending_load_data", undefined);
        return;
    }

    var _load_data = global.pending_load_data;
    show_debug_message("[Load_Apply] Pending load data found: " + string(_load_data));

    // --- 1) Reactivate Instances ---
    // Matching the logic from your original player load sequence.
    // Activate player specifically if it exists, then all other instances.
    if (instance_exists(obj_player)) {
        instance_activate_object(obj_player);
        show_debug_message("[Load_Apply] obj_player activated (if it was inactive).");
    }
    instance_activate_all();
    show_debug_message("[Load_Apply] instance_activate_all() called.");

    // --- 2) Restore Player State ---
    if (variable_struct_exists(_load_data, "player_data") && is_struct(_load_data.player_data)) {
        var _player_save_data = _load_data.player_data;
        show_debug_message("[Load_Apply] Attempting to restore player data: " + string(_player_save_data));

        if (instance_exists(obj_player)) {
            show_debug_message("[Load_Apply] obj_player instance (ID: " + string(obj_player.id) + ") found. Current pos: " + string(obj_player.x) + "," + string(obj_player.y));
            obj_player.x = _player_save_data.x;
            obj_player.y = _player_save_data.y;
            show_debug_message("[Load_Apply] Player position RESTORED to: " + string(obj_player.x) + ", " + string(obj_player.y));

            // --- Restore Core States ---
            if (variable_struct_exists(_player_save_data, "p_state")) {
                obj_player.player_state = _player_save_data.p_state;
                show_debug_message("[Load_Apply] Restored obj_player.player_state to: " + string(obj_player.player_state) + " (" + get_player_state_name(obj_player.player_state) + ")");
            } else {
                obj_player.player_state = PLAYER_STATE.FLYING; // Default if not found in save
                show_debug_message("[Load_Apply] 'p_state' not in save. Defaulted obj_player.player_state to FLYING.");
            }
            if (variable_struct_exists(_player_save_data, "f_dir")) {
                obj_player.face_dir = _player_save_data.f_dir;
                show_debug_message("[Load_Apply] Restored obj_player.face_dir to: " + string(obj_player.face_dir));
            } else {
                obj_player.face_dir = 1; // Default if not found
            }
            // if (variable_struct_exists(_player_save_data, "hp")) { obj_player.hp = _player_save_data.hp; }
            // if (variable_struct_exists(_player_save_data, "mp")) { obj_player.mp = _player_save_data.mp; }


            // --- CRITICAL: Reset Transient/Action States ---
            show_debug_message("[Load_Apply] Resetting transient player states (dash, dive, knockback, physics)...");
            obj_player.isDashing = false;
            obj_player.dash_timer = 0;
            obj_player.isDiving = false;
            obj_player.isSlamming = false;
            obj_player.is_in_knockback = false;
            obj_player.knockback_timer = 0;
            obj_player.knockback_hspeed = 0;
            obj_player.knockback_vspeed = 0;
            obj_player.v_speed = 0; // Reset vertical speed from physics
            // obj_player.h_speed = 0; // If you use a horizontal physics variable directly

            // Ensure input flags are sensible (if you use them directly on player)
            // obj_player.input_locked = false;
            // obj_player.movement_paused = false;

            global.player_state_loaded_this_frame = true;
            show_debug_message("[Load_Apply] player_state_loaded_this_frame SET TO TRUE.");

        } else {
            show_debug_message("[Load_Apply] obj_player NOT found in room " + room_get_name(room) + ". Cannot restore player position. Player might need to be created if not persistent and not in room by default.");
            // Fallback: If obj_player is supposed to be dynamically created on load if not present:
            // var _p = instance_create_layer(_player_save_data.x, _player_save_data.y, "Instances", obj_player); // Ensure "Instances" layer is correct
            // if (instance_exists(_p)) {
            //    show_debug_message("[Load_Apply] CREATED obj_player (ID: " + string(_p.id) + ") at " + string(_p.x) + "," + string(_p.y));
            //    // Apply other saved player states to _p here as above (_p.state = ..., etc.)
            //    global.player_state_loaded_this_frame = true;
            // }
        }
    } else {
        show_debug_message("[Load_Apply] No valid player_data struct found in pending_load_data.");
    }

    // --- 3) Restore NPC states ---
    if (variable_struct_exists(_load_data, "npc_data") && is_struct(_load_data.npc_data)) {
        show_debug_message("[Load_Apply] Restoring NPC data.");
        apply_npc_states(_load_data.npc_data); // Ensure this helper function exists and works
    } else {
        show_debug_message("[Load_Apply] No npc_data struct found in pending_load_data.");
    }

    // --- 4) Unpause Game & Set Game State ---
    if (variable_global_exists("game_paused")) {
        global.game_paused = false; // This might be a general flag
        show_debug_message("[Load_Apply] Game unpaused (global.game_paused = false).");
    }
    // Also ensure the game manager's state is "playing"
    if (instance_exists(obj_game_manager)) {
        obj_game_manager.game_state = "playing";
        show_debug_message("[Load_Apply] obj_game_manager.game_state SET to 'playing'.");
    } else {
        show_debug_message("[Load_Apply] WARNING: obj_game_manager not found to set game_state to 'playing'.");
    }

    // --- 5) Clean up Load Flags ---
    show_debug_message("[Load_Apply] Post-load state application finished. Cleaning up global load flags.");
    global.isLoadingGame = false; // This is the primary flag for the loading *process*
    variable_global_set("pending_load_data", undefined);
    // global.player_state_loaded_this_frame is used by obj_player this frame and can be reset there or simply ignored next frame.
}
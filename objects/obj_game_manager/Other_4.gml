/// obj_game_manager :: Other Event → Room Start

show_debug_message("Game Manager: Room Start Event for room: " + room_get_name(room));

// Find the player instance
var _player = instance_find(obj_player, 0);

////////////////////////////////////////////////////////////////////////////////
// 1) Load From Save
////////////////////////////////////////////////////////////////////////////////
if (variable_instance_exists(id, "load_pending")
 && load_pending
 && variable_instance_exists(id, "loaded_data")
 && is_struct(loaded_data))
{
    show_debug_message(" > Applying loaded data (Load Pending is TRUE)...");

    if (instance_exists(_player) && variable_struct_exists(loaded_data, "player_data")) {
        var _p_data = loaded_data.player_data;
        if (variable_struct_exists(_p_data, "x"))           _player.x         = _p_data.x;
        if (variable_struct_exists(_p_data, "y"))           _player.y         = _p_data.y;
        if (variable_struct_exists(_p_data, "hp"))          _player.hp        = _p_data.hp;
        if (variable_struct_exists(_p_data, "mp"))          _player.mp        = _p_data.mp;
        if (variable_struct_exists(_p_data, "level"))       _player.level     = _p_data.level;
        if (variable_struct_exists(_p_data, "xp"))          _player.xp        = _p_data.xp;
        if (variable_struct_exists(_p_data, "xp_require"))  _player.xp_require = _p_data.xp_require;
    }

    if (variable_struct_exists(loaded_data, "global_data")) {
        var _g_data = loaded_data.global_data;
        // apply any global_data fields here...
    }

    if (variable_struct_exists(loaded_data, "npc_states")) {
        var _npc_states = loaded_data.npc_states;
        with (obj_npc_parent) {
            if (variable_instance_exists(id, "unique_npc_id")) {
                var _id_string = unique_npc_id;
                if (variable_struct_exists(_npc_states, _id_string)) {
                    var _state = _npc_states[_id_string];
                    if (variable_struct_exists(_state, "has_spoken_to")) {
                        has_spoken_to = _state.has_spoken_to;
                    }
                }
            }
        }
    }

    load_pending = false;
    loaded_data = undefined;

    if (variable_global_exists("entry_direction")) {
        global.entry_direction = "none";
    }
}

////////////////////////////////////////////////////////////////////////////////
// 2) Battle Return Handling
////////////////////////////////////////////////////////////////////////////////
else if (
    variable_global_exists("original_room")
 && room == global.original_room
 && variable_global_exists("return_x")
 && variable_global_exists("return_y")
 && !is_undefined(global.return_x)
 && !is_undefined(global.return_y)
)
{
    var _player = instance_find(obj_player,0);
if (instance_exists(_player)) {
    _player.x = global.return_x;
    _player.y = global.return_y;
    show_debug_message("Game Manager: Player position restored to battle return coordinates (" + string(_player.x) + "," + string(_player.y) + ")");
    global.player_position_handled_by_battle_return = true; // SET THE FLAG HERE
}
// clear global variables
global.original_room = undefined;
global.return_x      = undefined;
global.return_y      = undefined;

return; // Early exit
}

// 3) Standard Entry Spawn (Game Manager's own fallback, mostly for non-transition scenarios or if Player Room Start failed utterly)
else {
    // This block runs if not loading and not returning from battle.
    // obj_player::Room Start should have run before this (or concurrently) and attempted positioning.
    // If global.player_position_handled_by_battle_return was set to true by Player Room Start (if it succeeded),
    // we might even skip this. However, that flag's name is specific.
    // For now, let this logic run. It will likely see entry_direction as "none" for transitions.

    show_debug_message(" > Game Manager: Not load/battle. Checking its own spawn logic (likely fallback to default).");
    var _player = instance_find(obj_player, 0);
    if (instance_exists(_player)) {
        // Check if player was ALREADY handled by its own Room Start for a transition.
        // This requires Player Room Start to set a flag if it successfully positioned the player.
        // Let's assume Player Room Start does NOT set global.player_position_handled_by_battle_return for its own success.
        // So, GM proceeds with its logic.

        var _entry_dir = variable_global_exists("entry_direction") ? global.entry_direction : "none";
        var _target_spawn_id_str; // For spawn_id string on obj_spawn_point

        // This switch translates an abstract direction to a string ID for obj_spawn_point's variable.
        // This is different from Player Room Start which uses the direction to pick an object *type*.
        switch (_entry_dir) {
            case "left":  _target_spawn_id_str = "entry_from_left";  break;
            case "right": _target_spawn_id_str = "entry_from_right"; break;
            case "above": _target_spawn_id_str = "entry_from_above"; break;
            case "below": _target_spawn_id_str = "entry_from_below"; break;
            default:      _target_spawn_id_str = "default";           break;
        }
        // ... (Your existing loop to find obj_spawn_point with matching spawn_id string variable _target_spawn_id_str) ...
        // This part of Game Manager is now mostly for handling "default" spawns if entry_direction was "none",
        // or for other systems that might use entry_direction with these string spawn_id markers.

        // If GM's logic positions the player, it should also consume global.entry_direction.
        // if (spawn found and player positioned by GM) {
        //     global.entry_direction = "none";
        // }
    }
}
show_debug_message("Game Manager: End of Room Start Event.");

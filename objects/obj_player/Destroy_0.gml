/// obj_player :: Destroy Event
var _id_str = string(id);
show_debug_message("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
show_debug_message("!!! PLAYER INSTANCE " + _id_str + " IS BEING DESTROYED !!!");
show_debug_message("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
show_debug_message("Current Room at time of player destruction: " + room_get_name(room));
var _callstack = debug_get_callstack(1);
var _callstack_str = "Callstack for player " + _id_str + " destruction (most recent call first):\n";
if (array_length(_callstack) > 0) {
    for (var i = 0; i < array_length(_callstack); i++) {
        _callstack_str += "  [" + string(i) + "]: " + string(_callstack[i]) + "\n";
    }
} else { _callstack_str += "  (Callstack not available or empty)\n"; }
show_debug_message(_callstack_str);
if (instance_exists(obj_game_manager) && variable_instance_exists(obj_game_manager, "game_state")) {
    show_debug_message("obj_game_manager.game_state at time of player destruction: " + string(obj_game_manager.game_state));
}
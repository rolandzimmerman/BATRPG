/// @function scr_player_spawn_battle_return()
/// @description Handles player positioning if returning from battle.
/// @returns {Bool} True if positioning was handled, false otherwise.

if (variable_global_exists("original_room") && global.original_room == room &&
    variable_global_exists("return_x") && !is_undefined(global.return_x) &&
    variable_global_exists("return_y") && !is_undefined(global.return_y))
{
    show_debug_message("Player Room Start: BATTLE RETURN DETECTED for room " + room_get_name(room));
    self.x = global.return_x; // Use self.x if called from player, or just x
    self.y = global.return_y;
    show_debug_message("  Player position set to: (" + string(self.x) + "," + string(self.y) + ") from battle return globals.");

    global.return_x = undefined;
    global.return_y = undefined;
    global.original_room = undefined;
    
    if (variable_global_exists("next_spawn_object")) global.next_spawn_object = undefined;
    if (variable_global_exists("entry_direction")) global.entry_direction = "none";

    return true; // Player was positioned
}
return false; // Not a battle return handled by this
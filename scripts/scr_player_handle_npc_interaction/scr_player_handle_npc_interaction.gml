/// @function scr_player_handle_npc_interaction()
/// @description Checks for and handles NPC interaction.
/// Assumes self.interact_key_pressed and self.x, self.y are set.

if (self.interact_key_pressed) { // Only check if key is pressed
    var _npc_at_player = instance_place(x, y, obj_npc_parent); // Assuming obj_npc_parent
    var _can_interact = instance_exists(_npc_at_player) && 
                        variable_instance_exists(_npc_at_player, "can_talk") && 
                        _npc_at_player.can_talk;

    if (_can_interact) {
        with (_npc_at_player) {
            event_perform(ev_other, ev_user0); // Perform the NPC's interaction event
        }
        // Depending on your game flow, you might want this to return true
        // and have the player's Step event exit to prevent movement during interaction.
        // For now, it just triggers the event.
    }
}
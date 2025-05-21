/// obj_player :: User Event 0
/// @description Called immediately after a load to reset any input locks or paused movement
//  (Place this in your obj_player’s “User Event 0”)
input_locked     = false;
movement_paused  = false;
dir_x            = 0;
dir_y            = 0;
hspeed           = 0;
vspeed           = 0;
isDashing        = false;
dash_timer       = 0;
isDiving         = false;
knockback_timer  = 0;
knockback_hspeed = 0;
knockback_vspeed = 0;
show_debug_message("Player User Event 0: Cleared locks and speeds after load.");
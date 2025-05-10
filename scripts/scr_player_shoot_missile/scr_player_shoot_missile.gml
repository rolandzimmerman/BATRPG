/// scr_player_shoot_missile(sx, sy, dir, spd, maxd)
/// @param 0 sx       spawn X coordinate
/// @param 1 sy       spawn Y coordinate
/// @param 2 dir      direction (-1 left, +1 right)
/// @param 3 spd      speed (px/frame)
/// @param 4 maxd     max travel distance (px)

///— Argument count check
if (argument_count < 5) {
    show_debug_message(
      "scr_player_shoot_missile: expected 5 args, got " 
      + string(argument_count)
    );
    return;
}

///— Pull args into locals
var sx  = argument0;
var sy  = argument1;
var dir = argument2;
var spd = argument3;
var md  = argument4;

///— Validate coords
if (!is_real(sx) || !is_real(sy)) {
    show_debug_message(
      "scr_player_shoot_missile: invalid spawn position: " 
      + string(sx) + ", " + string(sy)
    );
    return;
}

///— Create the missile at depth 0
var m = instance_create_depth(sx, sy, 0, obj_echo_missile);
if (m == noone) {
    show_debug_message("scr_player_shoot_missile: failed to create instance!");
    return;
}

///— Initialize its properties
with (m) {
    direction    = dir;
    speed        = spd;
    max_distance = md;
    origin_x     = sx;
    origin_y     = sy;
}

/// obj_game_over_controller :: Step Event
// Ramp up alpha, then switch to title room
if (fade_fading) {
    fade_alpha += fade_speed;
    if (fade_alpha >= 1) {
        room_goto(Titlescreen);
    }
}

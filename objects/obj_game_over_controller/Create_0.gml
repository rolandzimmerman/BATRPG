/// obj_game_over_controller :: Create Event
// Start a 5-second timer, initialize fade variables
fade_fading = false;
fade_alpha  = 0;
fade_speed  = 1 / (room_speed * 1); // fades in over 1 second once triggered
alarm[0]    = room_speed * 5;       // wait 5 seconds before starting fade

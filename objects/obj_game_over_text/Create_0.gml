// obj_game_over_text :: Create Event
// Position in the lower third of a 1920×1080 room (y ≈ 720), centered on X.
x = room_width  / 2;   // 1920/2 = 960
y = room_height * 2/3; // 1080*(2/3) ≈ 720

// Store the display string and style info:
display_text = "GAME OVER";
display_font = Font_game_over;  // Your asset named Font1, size 60
display_color = c_red;

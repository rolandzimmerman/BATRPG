//obj_dialog.create
messages = [];
current_message = -1;
current_char = 0;
draw_message = "";

char_speed = 2;
input_key = vk_space | gp_face1;

gui_w = display_get_gui_width();
gui_h = display_get_gui_height();

self.image_speed = .05;         // THIS makes it animate at 1 sprite frame per game frame
/// obj_destructible_torch :: Draw

// Draw your torch sprite (replace spr_torch_frame with your actual resource)
draw_sprite(spr_torch, 0, x, y);
// e.g. a 4-frame torch looping every 8 Steps
image_index = (image_index + 0.125) mod 7;
draw_sprite(spr_torch, floor(image_index), x, y);

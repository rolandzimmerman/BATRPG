/// obj_player :: Draw Event

// never draw the over‑world sprite in the battle room
if (room == rm_battle) return;

draw_self();
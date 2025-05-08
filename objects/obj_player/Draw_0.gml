/// obj_player :: Draw Event

// never draw the over‑world sprite in the battle room
if (room == rm_battle) return;

// default draw (your walking sprite, etc.)
draw_shadow(); // Consider if shadow behavior needs to change for an airborne player

draw_self();
/// obj_npc_shopkeeper :: Step Event

// if the shop UI is already open, skip
if (instance_exists(obj_shop)) exit;

// otherwise let the parent handle proximity/talk
event_inherited();

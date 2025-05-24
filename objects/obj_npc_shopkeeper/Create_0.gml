/// obj_npc_shopkeeper :: Create Event
event_inherited();  // calls obj_npc_parent :: Create
// 2) Remember which player to reactivate when we close
shop_player_id = instance_find(obj_player, 0);
show_debug_message("obj_shop CREATE: Set shop_player_id to " + string(shop_player_id) + ". Player exists: " + string(instance_exists(shop_player_id))); // NEW DEBUG LINE




// Check if player is gone immediately after this Create event is "done"
// This is tricky to do from within the Create event itself for an external effect.
// The next log will be the shopkeeper's "AFTER obj_shop create" or the shop's first Step.
/// obj_npc_shopkeeper :: User Event 0 (Simplified essential parts for opening)
// ... (initial checks: if !can_talk || instance_exists(obj_shop)) exit; ...

var _player_instance = instance_find(obj_player, 0);
if (!instance_exists(_player_instance)) {
    show_debug_message("Shopkeeper UE0: CRITICAL - Player not found. Cannot open shop.");
    exit;
}

// Deactivate player BEFORE creating shop to ensure shop's Create event sees player as inactive if needed,
// OR deactivate AFTER shop sets its shop_player_id. The latter is often safer.
// Your current obj_shop Create sets shop_player_id = instance_find(obj_player,0) assuming player is active.
// So, it's better to let obj_shop get the ID, then deactivate.

var shop_instance = instance_create_layer(0, 0, "Instances", obj_shop);
// obj_shop's Create event runs here and sets shop_instance.shop_player_id to _player_instance's ID.

// Configure shop
shop_instance.buyMultiplier = 1.2;
shop_instance.shop_stock    = ["potion","bomb","antidote"]; 
// shop_instance.shop_player_id is already set by its own Create event.

// Now, deactivate the player that the shop is aware of (or the one we found)
if (instance_exists(shop_instance.shop_player_id)) { // Prefer the ID the shop captured
    instance_deactivate_object(shop_instance.shop_player_id);
    show_debug_message("Shopkeeper UE0: Deactivated player " + string(shop_instance.shop_player_id));
} else if (instance_exists(_player_instance)) { // Fallback to the one found by shopkeeper
     instance_deactivate_object(_player_instance);
     show_debug_message("Shopkeeper UE0: Deactivated player " + string(_player_instance) + " (fallback).");
}

show_debug_message("Shopkeeper UE0: Shop opened.");
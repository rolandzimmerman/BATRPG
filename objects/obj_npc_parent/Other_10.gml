/// (full event code with only the deactivate call changed)
var _player_instance = instance_find(obj_player, 0);
if (!instance_exists(_player_instance)) {
    show_debug_message("Shopkeeper UE0: CRITICAL - Player not found. Cannot open shop.");
    exit;
}

// Create the shop
var shop_instance = instance_create_layer(0, 0, "Instances", obj_shop);
// configure it…
shop_instance.buyMultiplier = 1.2;
shop_instance.shop_stock    = ["potion","bomb","antidote"];

// — DEACTIVATE THE PLAYER INSTANCE (use instance_deactivate_instance, not instance_deactivate_object)
if (instance_exists(shop_instance.shop_player_id)) {
    instance_deactivate_instance(shop_instance.shop_player_id);
    show_debug_message("Shopkeeper UE0: Deactivated player instance " + string(shop_instance.shop_player_id));
} else {
    // fallback if something went wrong
    instance_deactivate_instance(_player_instance);
    show_debug_message("Shopkeeper UE0: (fallback) Deactivated player instance " + string(_player_instance));
}

show_debug_message("Shopkeeper UE0: Shop opened.");

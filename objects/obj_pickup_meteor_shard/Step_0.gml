/// obj_pickup_echo_gem :: Step

if (!picked_up) {
    var p = instance_place(x, y, obj_player);
    if (p != noone) {
        picked_up = true;

        // 1) Add the Echo Gem to inventory
        var added = scr_AddInventoryItem("meteor_shard", 1);

        // ── NEW: rebuild the global spell database so it now includes echo_wave ──
        global.spell_db = scr_BuildSpellDB();

        // 2) Notify the player
        create_dialog([
            { name: "", msg: "You got the Meteor Shard! Press Y to use Meteor Dive." }
        ]);

        // 3) Destroy the pickup
        instance_destroy();
    }
}

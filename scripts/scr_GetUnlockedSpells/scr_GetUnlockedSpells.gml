/// @function scr_GetUnlockedSpells()
/// @returns an array of keys for spells the player can currently use.
function scr_GetUnlockedSpells() {
    var db   = global.spell_db;
    var keys = variable_struct_get_names(db);
    var out  = [];
    
    for (var i = 0; i < array_length(keys); i++) {
        var key  = keys[i];
        var data = db[key];
        
        // If the spell has no unlock_item requirement, or the player has it, include it
        if (!variable_struct_exists(data, "unlock_item")
         || scr_HaveItem(data.unlock_item, 1))
        {
            array_push(out, key);
        }
    }
    return out;
}

/// obj_equipment_menu :: Create Event
/// @description Initialize the equipment menu state and variables.
// Assumes enum 'EEquipMenuState' is defined globally in a script (e.g., scr_game_enums).

// Debug
show_debug_message(">> obj_equipment_menu :: CREATE Event Starting...");

active = true;
// Note: You might want to initialize this to 'false' and have another object
// (e.g., a pause menu) set it to 'true' when this equipment menu is opened.

// --- Menu State ---
// EEquipMenuState.BrowseSlots now refers to the globally defined enum
menu_active = true;

menu_state = EEquipMenuState.BrowseSlots;

// --- Equipment Slots ---
equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ];
selected_slot = 0;

// --- Party Member Selection ---
party_index = 0;
equipment_character_key = "hero"; // Default fallback key

if (variable_global_exists("party_members") && is_array(global.party_members) && array_length(global.party_members) > 0) {
    if (party_index < array_length(global.party_members)) {
        equipment_character_key = global.party_members[party_index];
    } else {
        party_index = 0; // Reset if out of bounds
        equipment_character_key = global.party_members[party_index]; // Use the reset index
        show_debug_message("WARNING: obj_equipment_menu - party_index was out of bounds, reset to 0.");
    }
} else {
    show_debug_message("WARNING: obj_equipment_menu - global.party_members not found or empty. Defaulting to 'hero'.");
    if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
        global.party_members = ["hero"];
    } else if (array_length(global.party_members) == 0) {
        array_push(global.party_members, "hero");
    }
    // equipment_character_key is already "hero"
}

// --- Item Selection Sub-menu Variables ---
item_submenu_choices = [];
item_submenu_selected_index = 0;
item_submenu_scroll_top = 0;
item_submenu_display_count = 5; // How many items to show in list (tune this)
item_submenu_stat_diffs = {};

// --- Main Panel Dimensions and Position (Instance Variables for Draw GUI) ---
var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();

margin = 32; // Instance variable for screen edge margin. Tune as needed.

boxX = self.margin; // Use self.margin for clarity, or just margin
boxY = self.margin;
boxW = _gui_w - (self.margin * 2);
boxH = _gui_h - (self.margin * 2); // Default to large; Draw GUI might use this as a max container

// --- Fetch initial character data ---
if (script_exists(scr_GetPlayerData)) {
    equipment_data = scr_GetPlayerData(equipment_character_key);
} else {
    equipment_data = undefined;
    show_debug_message("ERROR: scr_GetPlayerData script missing in obj_equipment_menu Create!");
}

if (!is_struct(equipment_data)) {
    show_debug_message("ERROR: Create Event - equipment_data invalid for '" + string(equipment_character_key) + "'. Using placeholder.");
    equipment_data = {
        name: equipment_character_key,
        equipment: { weapon: noone, offhand: noone, armor: noone, helm: noone, accessory: noone },
        hp: 1, maxhp: 1, mp: 1, maxmp: 1, atk: 1, def: 1, matk: 1, mdef: 1, spd: 1, luk: 1
    };
}

calling_menu = noone; // Instance ID of the menu that opened this one, if any
self.image_speed = .05;         // THIS makes it animate at 1 sprite frame per game frame
show_debug_message(">> Equipment Menu Created & Initialized. Active: " + string(active) + " for char: " + string(equipment_character_key));
show_debug_message("   Panel geometry: X=" + string(boxX) + " Y=" + string(boxY) + " W=" + string(boxW) + " H=" + string(boxH) + " Margin: " + string(margin));
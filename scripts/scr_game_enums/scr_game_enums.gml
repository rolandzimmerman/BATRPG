// In script: scr_game_enums

enum EEquipMenuState {
    BrowseSlots,      // Selecting which equipment slot (weapon, armor, etc.)
    SelectingItem     // Choosing an item from inventory for the selected slot
    // Add other states like ComparingItems if you plan to implement them
}

// You can define other global enums or constants here as well.
// For example, if your PLAYER_STATE enum isn't defined globally yet:
// enum PLAYER_STATE {
//     FLYING,
//     WALKING_FLOOR,
//     WALKING_CEILING
// }
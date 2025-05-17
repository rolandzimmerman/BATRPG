/// obj_title_menu - Create Event
active = true; // This menu is active when created
menu_index = 0; // Current selected item index

menu_items = [
    "New Game",
    "Load Game",
    "Settings"
    // "Exit Game" // Optional
];
menu_item_count = array_length(menu_items);

input_cooldown_max = 10; // Cooldown in steps to prevent rapid scrolling
input_cooldown = 0;

settings_menu_instance_id = noone; // To store the ID of the settings menu instance when opened

// Define target rooms or actions
room_for_new_game = rm_opening_cutscene_1; // <<<< IMPORTANT: SET THIS TO YOUR FIRST GAMEPLAY ROOM >>>>

// --- ADD THIS FOR LOAD GAME ---
default_save_filename = "mysave.json"; // <<<< SET YOUR DEFAULT SAVE FILENAME >>>>

show_debug_message("obj_title_menu Created and Active.");
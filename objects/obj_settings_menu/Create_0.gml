/// obj_settings_menu :: Create Event

active = true; // Menu is active by default when created.
               // Set to false if you want it initially hidden and opened by another object.

settings_index = 0;
settings_items = ["Display Mode", "Resolution", "SFX Volume", "Music Volume", "Back"];
menu_item_count = array_length(settings_items); // Used by Draw GUI

dropdown_display_open = false;
dropdown_resolution_open = false;
dropdown_hover_index = -1; // For visual feedback on dropdowns (used in Draw GUI)

dropdown_display_options = ["Windowed", "Fullscreen", "Borderless"];
dropdown_display_index = 0; // Default selection

// Attempt to set initial dropdown_display_index based on global.display_mode
if (variable_global_exists("display_mode")) {
    for (var i = 0; i < array_length(dropdown_display_options); i++) {
        if (dropdown_display_options[i] == global.display_mode) {
            dropdown_display_index = i;
            break;
        }
    }
} else {
    // If global.display_mode doesn't exist, initialize it
    global.display_mode = dropdown_display_options[0]; // Default to first option
    show_debug_message("obj_settings_menu: global.display_mode initialized to " + global.display_mode);
}

// Ensure global resolution options exist, or set defaults
if (!variable_global_exists("resolution_options")) {
    global.resolution_options = [[1280, 720], [1920, 1080], [1024, 768]]; // Example defaults
    show_debug_message("obj_settings_menu: global.resolution_options initialized.");
}
if (!variable_global_exists("resolution_index")) {
    global.resolution_index = 0; // Default to first resolution in the list
    // Optionally, could try to match current display resolution here
    show_debug_message("obj_settings_menu: global.resolution_index initialized.");
}

// Ensure global audio volumes exist, or set defaults
if (!variable_global_exists("sfx_volume")) {
    global.sfx_volume = 0.75; // Default SFX volume (0.0 to 1.0)
    show_debug_message("obj_settings_menu: global.sfx_volume initialized.");
}
if (!variable_global_exists("music_volume")) {
    global.music_volume = 0.5; // Default Music volume
    show_debug_message("obj_settings_menu: global.music_volume initialized.");
}

input_cooldown = 0; // For gamepad D-pad navigation delay

show_debug_message("obj_settings_menu Created and Initialized. Active: " + string(active));
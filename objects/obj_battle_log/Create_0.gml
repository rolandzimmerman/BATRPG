/// obj_battle_log :: Create Event

logEntries = [];    // Initialize the array to store log message strings
// currentIndex = -1; // This was in your original Create Event. The Draw Event now dynamically
                    // determines which recent entries to show, so this specific instance
                    // variable might not be directly used by the new Draw logic for rendering,
                    // but you can keep it if other game systems interact with it.

// === Configuration for the Battle Log (values will be used by the Draw Event) ===

// Positioning: For lower-right corner placement
config_log_margin_x = 30;     // Margin from the right edge of the GUI
config_log_margin_y = 30;     // Margin from the bottom edge of the GUI

// Dimensions:
config_box_total_width = 800; // User Request: Total width of the log box
config_max_visible_lines = 8; // User Request: Approximate number of text lines the box should hold

// Padding:
config_box_padding = 8;       // Using your existing padding value. This is the space
                              // between the box border and the text content area.

// --- DEPRECATED / SUPERSEDED instance variables from your original Create Event ---
// These are commented out because the Draw Event now uses the 'config_' variables above
// for positioning (lower-right based on margins) and calculates line height dynamically.
// If you need these exact absolute positions for other reasons, you'll need to adjust the Draw Event.

// lineHeight = 18;             // The Draw Event now calculates line_height dynamically based on Font1
                                // to better fit 24px text.
// logX = display_get_gui_width() - 500; // The Draw Event now calculates the box's X position
                                         // based on gui_width, config_box_total_width, and config_log_margin_x
                                         // for lower-right placement.
// logY = display_get_gui_height() - 300; // Similarly, Draw Event calculates box's Y position.


// IMPORTANT: Ensure Font1 (your 24px font asset) and spr_box1 (your background sprite asset)
// are valid and accessible to this object. If they are global or assigned from elsewhere,
// no action is needed here. If they should be set per-instance, you might assign them here:
// Font1 = f_YourBattleLogFont; // Example: replace with your actual font asset
// spr_box1 = s_YourLogBackground; // Example: replace with your actual sprite asset
self.image_speed = .05;         // THIS makes it animate at 1 sprite frame per game frame
/// obj_pause_menu :: Step Event
/// Handles navigation and actions within the main pause menu.

// — only run if this menu is active —
if (!variable_instance_exists(id, "active") || !active) {
    exit;
}

// --- SAFETY CHECK: Ensure game is actually paused ---
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;
if (_gm == noone || !variable_instance_exists(_gm, "game_state") || _gm.game_state != "paused") {
    show_debug_message("Pause Menu Step: Game not paused or GM missing. Destroying self.");
    instance_activate_all(); // Try to restore game state before destroying
    instance_destroy(); 
    exit;
}

// --- INPUT ---
// Assuming player_index 0 for gamepad inputs by default
var up_pressed = input_check_pressed(INPUT_ACTION.MENU_UP);
var down_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN);
var confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);
// For "back", we want MENU_CANCEL (Esc, Gamepad B) OR the PAUSE button (which includes Gamepad Start)
var back_pressed_menu_cancel = input_check_pressed(INPUT_ACTION.MENU_CANCEL);
var back_pressed_pause_button = input_check_pressed(INPUT_ACTION.PAUSE); // PAUSE includes vk_escape and gp_start
var back_input = back_pressed_menu_cancel || back_pressed_pause_button;


// --- Initialize menu variables (Safety Check) ---
if (!variable_instance_exists(id, "menu_options"))    menu_options = ["Resume"]; 
if (!variable_instance_exists(id, "menu_item_count")) menu_item_count = array_length(menu_options);
if (!variable_instance_exists(id, "menu_index"))      menu_index = 0;
// Ensure index is valid
if (menu_item_count > 0) {
    menu_index = clamp(menu_index, 0, menu_item_count - 1); 
} else {
    menu_index = 0; // Or -1 if no options should mean no valid index
}


// --- NAVIGATION ---
if (menu_item_count > 0) { // Only navigate if there are options
    if (up_pressed) {
        menu_index = (menu_index - 1 + menu_item_count) mod menu_item_count;
        // audio_play_sound(snd_menu_cursor, 1, false); 
    }
    if (down_pressed) {
        menu_index = (menu_index + 1) mod menu_item_count;
        // audio_play_sound(snd_menu_cursor, 1, false); 
    }
}


// --- RESUME / CLOSE PAUSE MENU ---
// This handles "Back" button press OR selecting "Resume" and confirming
var is_resume_option_selected = (menu_item_count > 0 && menu_options[menu_index] == "Resume");
if (back_input || (confirm_pressed && is_resume_option_selected)) {
    // audio_play_sound(snd_menu_cancel, 1, false); 
    if (instance_exists(_gm)) { // Ensure _gm still exists
         _gm.game_state = "playing"; 
    }
    instance_activate_all(); // Reactivate all game instances
    instance_destroy();      // Destroy the pause menu itself
    exit; 
}


// --- CONFIRM ACTIONS (Other Menu Options) ---
// This block only runs if 'confirm_pressed' is true AND 'Resume' was NOT the selected option
// (because the above block would have already handled it and exited).
if (confirm_pressed && !is_resume_option_selected && menu_item_count > 0) { 
    var opt = menu_options[menu_index];
    // audio_play_sound(snd_menu_select, 1, false); 

    switch (opt) {
        case "Items":
            show_debug_message("Pause Menu: Items selected.");
            if (!instance_exists(obj_item_menu_field)) {
                var layer_id = layer_get_id("Instances_GUI") != -1 ? layer_get_id("Instances_GUI") : layer_get_id("Instances");
                if (layer_id != -1) {
                    var item_menu = instance_create_layer(0, 0, layer_id, obj_item_menu_field);
                    if (instance_exists(item_menu)) {
                        item_menu.calling_menu = id; 
                        active = false; 
                        show_debug_message(" -> Created obj_item_menu_field, deactivated pause menu.");
                    } else { show_debug_message(" -> ERROR: Failed to create obj_item_menu_field!"); }
                } else { show_debug_message(" -> ERROR: No suitable layer for item menu!"); }
            } else { show_debug_message(" -> WARNING: Field item menu already exists!"); }
            break;
            
        case "Spells":
            show_debug_message("Pause Menu: Spells selected.");
            if (!instance_exists(obj_spell_menu_field)) {
                var layer_id = layer_get_id("Instances_GUI") != -1 ? layer_get_id("Instances_GUI") : layer_get_id("Instances");
                if (layer_id != -1) {
                    var spell_menu = instance_create_layer(0, 0, layer_id, obj_spell_menu_field);
                    if (instance_exists(spell_menu)) {
                        spell_menu.calling_menu = id; 
                        active = false; 
                        show_debug_message(" -> Created obj_spell_menu_field, deactivated pause menu.");
                    } else { show_debug_message(" -> ERROR: Failed to create obj_spell_menu_field!"); }
                } else { show_debug_message(" -> ERROR: No suitable layer for spell menu!"); }
            } else { show_debug_message(" -> WARNING: Field spell menu already exists!"); }
            break;

        case "Party":
            show_debug_message("Pause Menu: Party selected.");
            if (!instance_exists(obj_party_menu)) {
                var layer_id = layer_get_id("Instances_GUI");
                if (layer_id == -1) layer_id = layer_get_id("Instances");
                var pm = instance_create_layer(0, 0, layer_id, obj_party_menu);
                if (instance_exists(pm)) {
                    pm.calling_menu = id;
                    active = false;
                    show_debug_message(" -> Created obj_party_menu, pause menu deactivated.");
                }
            }
            break;

        case "Load Game":
            show_debug_message("Pause Menu: Load Game selected.");
            instance_activate_all(); 
            if (script_exists(scr_load_game)) {
                scr_load_game("mysave.json"); 
            } else { show_debug_message(" -> ERROR: scr_load_game script not found!"); }
            // If load is successful, current instances (including this menu) might be destroyed by room change.
            break;

        case "Quit":
            show_debug_message("Pause Menu: Quit selected.");
            game_end(); 
            break;

        case "Equipment":
            show_debug_message("Pause Menu: Equipment selected.");
            if (!instance_exists(obj_equipment_menu)) {
                var layer_id = layer_get_id("Instances_GUI") != -1 ? layer_get_id("Instances_GUI") : layer_get_id("Instances");
                if (layer_id != -1) {
                    var em = instance_create_layer(0, 0, layer_id, obj_equipment_menu);
                    if (instance_exists(em)) { 
                        em.calling_menu = id; 
                        active = false; 
                        show_debug_message(" -> Created obj_equipment_menu, deactivated pause menu.");
                    } else { show_debug_message(" -> ERROR: Failed to create obj_equipment_menu instance!"); }
                } else { show_debug_message("ERROR: Cannot find layer for equipment menu!"); break; }
            } else { show_debug_message(" -> WARNING: Equipment menu already exists!"); }
            break; 
            
        case "Settings":
            show_debug_message("Pause Menu: Settings selected.");
            var layer_id_settings = layer_get_id("Instances_GUI"); // Use a different var name
            if (layer_id_settings == -1) layer_id_settings = layer_get_id("Instances");
            var sm = instance_create_layer(0, 0, layer_id_settings, obj_settings_menu);
            if (instance_exists(sm)) {
                sm.opened_by_instance_id = id; 
                active = false;
                show_debug_message(" -> Created obj_settings_menu, deactivated pause menu. caller=" + string(id));
            }
            break;
    } // End Switch
} // End if(confirm_pressed and not resume)
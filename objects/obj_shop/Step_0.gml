/// obj_shop :: Step Event
var cancel_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL);
show_debug_message("obj_shop Step: cancel_pressed=" + string(cancel_pressed));

// 1) Only run while the shop is active
if (!shop_active) exit;

// 2) Gather inputs (using player_index 0 by default for input functions)
var up_pressed = input_check_pressed(INPUT_ACTION.MENU_UP);
var down_pressed = input_check_pressed(INPUT_ACTION.MENU_DOWN);
var left_pressed = input_check_pressed(INPUT_ACTION.MENU_LEFT);
var right_pressed = input_check_pressed(INPUT_ACTION.MENU_RIGHT);
var confirm_pressed = input_check_pressed(INPUT_ACTION.MENU_CONFIRM);
var cancel_pressed = input_check_pressed(INPUT_ACTION.MENU_CANCEL);

// 3) Ensure our variables exist
shop_index = shop_index ?? 0;
shop_state = shop_state ?? "browse";
shop_confirm_choice = shop_confirm_choice ?? 0;
var stock = shop_stock; // Assuming shop_stock is initialized elsewhere

// 4) BROWSE STATE: navigate list, confirm to buy, cancel to close
if (shop_state == "browse") {
    var count = array_length(stock);
    if (count > 0) { // Ensure there are items to navigate
        if (up_pressed) shop_index = (shop_index - 1 + count) mod count;
        if (down_pressed) shop_index = (shop_index + 1) mod count;
    }

    if (confirm_pressed && count > 0) { // Can only confirm if there are items
        shop_state = "confirm_purchase";
        shop_confirm_choice = 0; // Default to "YES"
    }
    // raw test
var gp_idx = global.gamepad_player_map[0];
if (gamepad_button_check_pressed(gp_idx, gp_face2)) {
    show_debug_message("RAW: gp_face2 was pressed!");
}

    if (cancel_pressed) {
        shop_active = false;


            instance_activate_object(obj_player);


        exit;
    }
}

// 5) CONFIRM STATE: choose YES/NO, commit with dialog
else if (shop_state == "confirm_purchase") {
    // Toggle between YES (0) and NO (1)
    // The original (right - left) is clever. If MENU_LEFT/RIGHT map to A/D for keyboard,
    // this could be an issue if both are pressed. However, input_check_pressed only returns true/false.
    // We need to get a direction.
    var horizontal_input_direction = 0;
    if (right_pressed) {
        horizontal_input_direction = 1;
    } else if (left_pressed) {
        horizontal_input_direction = -1;
    }

    if (horizontal_input_direction != 0) {
        // shop_confirm_choice is 0 (YES) or 1 (NO)
        if (horizontal_input_direction == 1 && shop_confirm_choice == 0) { // Moving right from YES to NO
            shop_confirm_choice = 1;
        } else if (horizontal_input_direction == -1 && shop_confirm_choice == 1) { // Moving left from NO to YES
            shop_confirm_choice = 0;
        }
        // audio_play_sound(snd_menu_blip, 0, false); // Example sound for selection change
    }
    
    // Alternative for left/right toggle if only one can be true from input_check_pressed
    // if (left_pressed && shop_confirm_choice == 1) shop_confirm_choice = 0; // From NO to YES
    // if (right_pressed && shop_confirm_choice == 0) shop_confirm_choice = 1; // From YES to NO


    if (confirm_pressed) {
        // Ensure shop_index is valid for the stock array
        if (shop_index < 0 || shop_index >= array_length(stock)) {
            show_debug_message("ERROR: Shop confirm with invalid shop_index: " + string(shop_index));
            shop_state = "browse"; // Go back to safety
            exit;
        }

        var key = stock[shop_index];
        var data = scr_GetItemData(key); // Assuming this function handles undefined keys gracefully
        
        if (!is_struct(data)) {
            show_debug_message("ERROR: Could not get item data for key: " + string(key));
            shop_state = "browse"; // Go back
            exit;
        }

        var base_value = data.value ?? 0; // Default to 0 if 'value' is missing
        var price = ceil(base_value * buyMultiplier);

        if (shop_confirm_choice == 0) { // YES branch - Try to buy
            if (global.party_currency >= price) {
                scr_SpendCurrency(price);
                scr_AddInventoryItem(key, 1);
                audio_play_sound(snd_buy, 1, false); // Assuming snd_buy exists

                create_dialog([
                    { name:"Shop", msg:"Bought 1 " 
                                    + (data.name ?? key) 
                                    + " for " + string(price) + "g." }
                ]);
            } else {
                // Not enough gold sound/feedback
                // audio_play_sound(snd_menu_error, 0, false);
                create_dialog([
                    { name:"Shop", msg:"You don’t have enough gold!" }
                ]);
            }
        } else { // NO branch (shop_confirm_choice == 1)
            // Play cancel sound or no sound, then go back to browse.
            // audio_play_sound(snd_menu_cancel, 0, false);
        }
        
        // Go back to Browse once the dialog is up (or decision made)
        shop_state = "browse";
    }

    if (cancel_pressed) { // "Cancel" in confirm state usually means "No" or back
        // audio_play_sound(snd_menu_cancel, 0, false);
        shop_state = "browse";
    }
}
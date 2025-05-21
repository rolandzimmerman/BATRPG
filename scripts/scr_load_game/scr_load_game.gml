/// @function scr_load_game(filename)
/// @description Reads save data from a file and prepares for loading state.
/// @param filename {string} The name of the file to load from (e.g., "mysave.json")
/// @returns {bool} True if load process started successfully
function scr_load_game(filename) {
    show_debug_message("[Load] Attempting to load from: " + filename);

    // 1) Check file exists
    if (!file_exists(filename)) {
        show_debug_message("[Load] ERROR: File not found: " + filename);
        return false;
    }

    // 2) Read whole JSON string
    var fh = file_text_open_read(filename);
    if (fh < 0) {
        show_debug_message("[Load] ERROR: Could not open file: " + filename);
        return false;
    }
    var json_str = "";
    while (!file_text_eof(fh)) {
        json_str += file_text_readln(fh);
    }
    file_text_close(fh);
    if (json_str == "") {
        show_debug_message("[Load] ERROR: File was empty: " + filename);
        return false;
    }
    show_debug_message("[Load] File read.");

    // 3) Parse JSON
    var data = json_parse(json_str);
    if (!is_struct(data)) {
        show_debug_message("[Load] ERROR: JSON did not parse to struct.");
        return false;
    }
    show_debug_message("[Load] JSON parsed.");

    // 4) Store in manager & flag
    if (!instance_exists(obj_game_manager)) {
        show_debug_message("[Load] CRITICAL: obj_game_manager missing!");
        return false;
    }
    obj_game_manager.loaded_data = data;
    obj_game_manager.load_pending = true;

    // 5) Goto saved room
    if (variable_struct_exists(data, "player") && variable_struct_exists(data.player, "room")) {
        var target = data.player.room;
        if (!room_exists(target)) {
            show_debug_message("[Load] ERROR: Saved room doesn't exist: " + string(target));
            obj_game_manager.load_pending = false;
            obj_game_manager.loaded_data = undefined;
            return false;
        }
        show_debug_message("[Load] Switching to room: " + room_get_name(target));
        room_goto(target);
    } else {
        show_debug_message("[Load] ERROR: No player.room in save.");
        obj_game_manager.load_pending = false;
        obj_game_manager.loaded_data = undefined;
        return false;
    }

    return true;
}

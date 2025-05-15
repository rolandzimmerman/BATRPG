/// @function scr_InitRoomMap()
/// @description Initializes the global room connection map using Room IDs as keys.
function scr_InitRoomMap() {
    // Destroy existing map (and its nested maps) if necessary
    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        var key = ds_map_find_first(global.room_map);
        while (!is_undefined(key)) {
            var nested = ds_map_find_value(global.room_map, key);
            if (ds_exists(nested, ds_type_map)) {
                ds_map_destroy(nested);
            }
            key = ds_map_find_next(global.room_map, key);
        }
        ds_map_destroy(global.room_map);
    }

    // Create fresh map
    global.room_map = ds_map_create();
    show_debug_message("Initializing Room Map...");

    // rm_cave_tutorial connections
    var r1 = rm_cave_tutorial;
    var m1 = ds_map_create();
    ds_map_add(m1, "left",  rm_bat_debug);
    ds_map_add(m1, "right", rm_cave_2);
    ds_map_add(m1, "above", noone);
    ds_map_add(m1, "below", noone);
    ds_map_add(global.room_map, r1, m1);

    // rm_cave_2 connections
    var r2 = rm_cave_2;
    var m2 = ds_map_create();
    ds_map_add(m2, "left",  rm_cave_tutorial);
    ds_map_add(m2, "right", noone);
    ds_map_add(m2, "above", noone);
    ds_map_add(m2, "below", noone);
    ds_map_add(global.room_map, r2, m2);
    
    // rm_cave_2 connections
    var r3 = rm_bat_debug;
    var m3 = ds_map_create();
    ds_map_add(m3, "left",  noone);
    ds_map_add(m3, "right", rm_cave_tutorial);
    ds_map_add(m3, "above", noone);
    ds_map_add(m3, "below", noone);
    ds_map_add(global.room_map, r3, m3);

    // …add more rooms here…

    show_debug_message("Room Map Initialized. Rooms: " + string(ds_map_size(global.room_map)));
}
// Layout coordinates for minimap display (example layout)
global.room_coords = ds_map_create();
ds_map_add(global.room_coords, rm_cave_tutorial, {x: 42, y: 26});
ds_map_add(global.room_coords, rm_cave_2, {x: 43, y: 26});
// Add more as needed

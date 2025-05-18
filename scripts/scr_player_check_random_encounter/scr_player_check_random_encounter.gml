if (self.dir_x != 0 || self.v_speed != 0) {
    if (!variable_global_exists("encounter_timer")) global.encounter_timer = 0;
    global.encounter_timer++;
}

// Make these instance variables or pass them if they vary
var _encounter_threshold = 300; 
var _encounter_chance = 10;

if (variable_global_exists("encounter_timer") && global.encounter_timer >= _encounter_threshold) {
    global.encounter_timer = 0;
    if (random(100) < _encounter_chance) {
        if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
            var _list = ds_map_find_value(global.encounter_table, room);
            if (ds_exists(_list, ds_type_list) && !ds_list_empty(_list)) {
                // audio_play_sound(snd_sfx_encounter, 1, 0); // Ensure snd_sfx_encounter exists
                var _index = irandom(ds_list_size(_list) - 1);
                var _formation = ds_list_find_value(_list, _index);
                if (is_array(_formation)) {
                    global.battle_formation = _formation;
                    global.original_room = room;
                    global.return_x = x; 
                    global.return_y = y; 
                    if (room_exists(rm_battle)) room_goto(rm_battle); // Ensure rm_battle exists
                    return true; // Encounter started
                }
            }
        }
    }
}
return false; // No encounter
/// obj_battle_manager :: Create Event
// ... (initial setup: spawn_offset, BASE_TICK_VALUE, combatants_all, etc. as before) ...

show_debug_message("--- Battle Manager Create START --- Received Formation: " + string(global.battle_formation ?? "UNDEFINED"));

var spawn_offset_x = 0;
var spawn_offset_y = 0;

// Speed Queue Configuration
BASE_TICK_VALUE = 10000;
TURN_ORDER_DISPLAY_COUNT = 6;

// Combatant Management & Turn Order
combatants_all = ds_list_create();
currentActor = noone;
turnOrderDisplay = [];
current_attack_animation_complete = false;

// Initialize/Clear Global DS Lists
if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) { ds_list_clear(global.battle_enemies); } else { global.battle_enemies = ds_list_create(); }
if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { ds_list_clear(global.battle_party); } else { global.battle_party = ds_list_create(); }
// ... (debug messages for lists) ...

// Initialize Global Status Effect Map
if (variable_global_exists("battle_status_effects") && ds_exists(global.battle_status_effects, ds_type_map)) { ds_map_destroy(global.battle_status_effects); }
global.battle_status_effects = ds_map_create();
// ... (debug message for status map) ...

// Initial battle variables
global.battle_state = "initializing";
global.battle_target = 0;
global.enemy_turn_index = 0;
total_xp_from_battle = 0;
stored_action_data = undefined;
selected_target_id = noone;
global.active_party_member_index = -1;

// Screen Flash Variables
screen_flash_alpha = 0; screen_flash_timer = 0; screen_flash_duration = 0;
screen_flash_peak_alpha = 0.8; screen_flash_fade_speed = 0.1;


// --- Layer Setup ---
var instance_layer_name = "Instances"; 
var instance_layer_id = layer_get_id(instance_layer_name);
if (instance_layer_id == -1) {
     show_debug_message("FATAL ERROR: Layer '" + instance_layer_name + "' does not exist in room '" + room_get_name(room) + "'!");
     game_end(); exit;
}
show_debug_message(" -> Using layer '" + instance_layer_name + "' (ID: " + string(instance_layer_id) + ") for actors/effects.");
// --- Sprite Handling ---
sprite_assigned = false;    
idle_sprite = sprite_index; 
attack_sprite_asset = -1;   
casting_sprite_asset = -1; // <<< ADDED: To store casting sprite
sprite_before_attack = sprite_index; 
original_scale = 1.0; 

// --- Spawn Party Members ---
show_debug_message("--- Spawning Party Members ---");
var party_positions = [ [576, 672, 1.00], [768, 416, 0.80], [352, 480, 0.90], [544, 256, 0.75] ];
var _fallback_player_data = { hp:1, maxhp:1, mp:0, maxmp:0, atk:1, def:1, matk:1, mdef:1, spd:1, luk:1, level:1, xp:0, xp_require:100, skills:[], skill_index:0, item_index:0, equipment:{weapon:noone,offhand:noone,armor:noone,helm:noone,accessory:noone}, is_defending:false, overdrive:0, overdrive_max:100, name: "Fallback", character_key: "fallback", resistances: { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 } };

if (variable_global_exists("party_members") && is_array(global.party_members)) {
    var _party_size = array_length(global.party_members);
    show_debug_message("  Found " + string(_party_size) + " members");
    
    for (var i = 0; i < _party_size; i++) {
        if (i >= array_length(party_positions)) break;
        var px = party_positions[i][0] + spawn_offset_x; var py = party_positions[i][1] + spawn_offset_y; var sc = party_positions[i][2];
        var char_key = global.party_members[i];
        
        show_debug_message("  Spawning party slot " + string(i) + " key: " + char_key + " at (" + string(px) + "," + string(py) + ") on layer '" + instance_layer_name + "'");
        var p_inst = instance_create_layer(px, py, instance_layer_id, obj_battle_player); 
        if (p_inst != noone) {
            p_inst.image_xscale  = sc; p_inst.image_yscale  = sc;
            p_inst.character_key = char_key; 
            var _base_stats = scr_GetPlayerData(char_key);
            var _calculated_stats = is_struct(_base_stats) ? scr_CalculateEquippedStats(_base_stats) : {};
            p_inst.data = (is_struct(_calculated_stats) && variable_struct_exists(_calculated_stats, "name")) ? _calculated_stats : variable_clone(_fallback_player_data, true);
            
            // NOTE FOR PARTY IDLE ANIMATION:
            // obj_battle_player instances should set their own initial sprite_index
            // to their idle sprite and set image_speed appropriately in their Create Event
            // or when their combat_state becomes "idle".
            // Example within obj_battle_player Create or Idle state logic:
            //   this.sprite_index = this.data.sprite_idle; // Assuming data contains sprite_idle
            //   if (sprite_exists(this.sprite_index) && sprite_get_number(this.sprite_index) > 1) {
            //       this.image_speed = 0.2; // Or desired idle animation speed
            //   } else {
            //       this.image_speed = 0; this.image_index = 0;
            //   }

            // ... (rest of party member data assignment as before, including HP/MaxHP logging and ensuring core fields) ...
            if (!variable_struct_exists(p_inst.data,"resistances")) p_inst.data.resistances = { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 };
            // ... (other ensures) ...
            p_inst.data.party_slot_index = i; 
            ds_list_add(global.battle_party, p_inst);
            ds_list_add(combatants_all, p_inst);
            p_inst.turnCounter = BASE_TICK_VALUE / max(1, p_inst.data.spd ?? 1); 
            // ... (debug for turnCounter) ...
        }
    }
} else { /* ... error handling ... */ }
show_debug_message("--- Finished Party spawn, count: " + string(ds_list_size(global.battle_party)) + " ---");

// --- Spawn Enemies ---
show_debug_message("--- Spawning Enemies ---");
// MODIFIED enemy_positions: Swapped original first and fifth elements
var enemy_positions = [
    [1504, 544, 0.90], // Original 2nd
    [1344, 288, 0.75], // Original 3rd
    [1792, 576, 1.00], // Original 4th
    [1664, 320, 0.80], // Original 5th position, now 4th
    [1632, 800, 1.10]  // Original 1st position, now 5th
];

if (variable_global_exists("battle_formation") && is_array(global.battle_formation)) {
    var form = global.battle_formation;
    var _num = array_length(form);
    show_debug_message("  Expecting to spawn " + string(_num) + " enemies.");
    
    for (var i = 0; i < _num; ++i) {
        var type = form[i];
        if (!object_exists(type)) {
            show_debug_message("    -> ERROR: Enemy object type " + string(type) + " does not exist. Skipping.");
            continue;
        }
        var ex, ey, esc; 
        if (i < array_length(enemy_positions)) {
            ex = enemy_positions[i][0] + spawn_offset_x;
            ey = enemy_positions[i][1] + spawn_offset_y;
            esc = enemy_positions[i][2];
        } else { // Fallback for more enemies than defined positions
            ex = 980 + spawn_offset_x + irandom_range(-30, 30);
            ey = 120 + i * 100 + spawn_offset_y + irandom_range(-20, 20); // Ensure 'i' is used for distinct Y
            esc = 1.0 + random(0.1);
        }
        
        show_debug_message("    -> Attempting to spawn " + object_get_name(type) + " at (" + string(ex) + "," + string(ey) + ") on layer '" + instance_layer_name + "'");
        var e = instance_create_layer(ex, ey, instance_layer_id, type); 
        
        if (instance_exists(e)) {
            var enemy_data = script_exists(scr_GetEnemyDataFromName) ? scr_GetEnemyDataFromName(type) : {};
            // Ensure essential fields if enemy_data is incomplete or scr_GetEnemyDataFromName doesn't exist
            if (!is_struct(enemy_data) || !variable_struct_exists(enemy_data, "name")) {
                enemy_data = { name: object_get_name(type), hp: 10, maxhp: 10, spd: 5, xp: 5, sprite_index: type.sprite_index ?? -1, attack_sprite: spr_pow, attack_sound: snd_punch, /* other defaults */ resistances: {physical:0} };
                show_debug_message("      -> Using fallback/default data for enemy " + object_get_name(type));
            }
            e.data = enemy_data; 
            show_debug_message("      -> Assigned data struct. HP: " + string(e.data.hp ?? "N/A") + " Spd: " + string(e.data.spd ?? "N/A"));

            // Initialize instance variables based on the assigned data
            e.image_xscale = esc; e.image_yscale = esc; 
            e.sprite_index = e.data.sprite_index ?? e.sprite_index ?? -1; // Use data's sprite, fallback to instance's default if any
            
            // THIS LINE HANDLES INITIAL IDLE ANIMATION FOR ENEMIES:
            e.image_speed = (sprite_exists(e.sprite_index) && sprite_get_number(e.sprite_index) > 1) ? 0.2 : 0; 
            if (e.image_speed == 0 && sprite_exists(e.sprite_index)) e.image_index = 0; // Reset to first frame if not animating

            e.attack_fx_sprite = e.data.attack_sprite ?? spr_pow; 
            e.attack_fx_sound = e.data.attack_sound ?? snd_punch; 
            if (!sprite_exists(e.sprite_index)) e.sprite_index = -1; 
            if (!sprite_exists(e.attack_fx_sprite)) e.attack_fx_sprite = spr_pow;
            if (!audio_exists(e.attack_fx_sound)) e.attack_fx_sound = snd_punch;
            show_debug_message("      -> Set sprite index: " + sprite_get_name(e.sprite_index) + " (Image Speed: " + string(e.image_speed) + ")");
            
            ds_list_add(global.battle_enemies, e);
            ds_list_add(combatants_all, e);
            if (!variable_struct_exists(e.data,"spd")) e.data.spd = 1; 
            e.turnCounter = BASE_TICK_VALUE / max(1, e.data.spd); 
            show_debug_message("      -> Initial turnCounter: " + string(e.turnCounter) + " (Spd: " + string(e.data.spd) + ")");
        } else { show_debug_message("    -> FAILED to create enemy instance!"); }
    }
} else { global.battle_formation = []; }
// --- RECORD INITIAL ENEMY XP FOR LATER ---
if (ds_exists(global.battle_enemies, ds_type_list)) {
    // Create a list to hold each enemy's XP
    if (variable_instance_exists(id, "initial_enemy_xp")) {
        ds_list_destroy(initial_enemy_xp);
    }
    initial_enemy_xp = ds_list_create();
    // For each enemy instance, grab its data.xp
    for (var i = 0; i < ds_list_size(global.battle_enemies); i++) {
        var e = global.battle_enemies[| i];
        if (instance_exists(e)
         && variable_instance_exists(e, "data")
         && is_struct(e.data)
         && variable_struct_exists(e.data, "xp")) {
            ds_list_add(initial_enemy_xp, e.data.xp);
        } else {
            ds_list_add(initial_enemy_xp, 0);
        }
    }
    show_debug_message(" -> Recorded XP for " 
        + string(ds_list_size(initial_enemy_xp))
        + " enemies.");
}

// --- Create Battle Menu ---
show_debug_message("--- Creating battle menu ---");
var gui_layer_name = "Instances"; 
var gui_layer_id = layer_get_id(gui_layer_name);
if (gui_layer_id == -1) { 
     show_debug_message("Warning: Layer '" + gui_layer_name + "' not found. Creating menu on '" + instance_layer_name + "'.");
     gui_layer_id = instance_layer_id; 
}
if (!instance_exists(obj_battle_menu)) { 
     if (gui_layer_id != -1) { 
         instance_create_layer(0, 0, gui_layer_id, obj_battle_menu); 
         show_debug_message(" -> obj_battle_menu instance created on layer ID: " + string(gui_layer_id));
     } else { show_debug_message(" -> ERROR: Could not find a valid layer for obj_battle_menu!"); }
} else { show_debug_message(" -> obj_battle_menu instance already exists."); }

// --- Final Initialization ---
if (script_exists(scr_CalculateTurnOrderDisplay)) {
     turnOrderDisplay = scr_CalculateTurnOrderDisplay(combatants_all, BASE_TICK_VALUE, TURN_ORDER_DISPLAY_COUNT);
     show_debug_message(" -> Calculated initial turn order display.");
}
global.battle_state = "calculate_turn"; 
show_debug_message("Battle Manager Create DONE. Initial State: " + global.battle_state);
battle_fx_surface = -1;

// <<< NEW: Initialize flag to ignore B for one frame when cancelling target select >>>
global.battle_ignore_b = false;

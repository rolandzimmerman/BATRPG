/// obj_player :: Create Event
persistent = true;

// Define Player States
enum PLAYER_STATE {
    FLYING,
    WALKING_FLOOR,
    WALKING_CEILING
}
player_state = PLAYER_STATE.FLYING;

TILE_SIZE = 12; // IMPORTANT: Set this to your game's actual tile size (e.g., 16, 32, etc.)

/// obj_player :: Create Event (add near the top)

prev_x         = x;
prev_y         = y;
stuck_counter  = 0;  // for Guard #4


// === Restore Position if returning from battle ===
// This should be checked early.
if (variable_global_exists("return_x") && variable_global_exists("return_y")) {
    show_debug_message("✅ Restoring player position from global.return_x/y...");
    x = global.return_x;
    y = global.return_y;

    // Prevent reuse after respawn
    global.return_x = undefined;
    global.return_y = undefined;
    global.original_room = undefined; // Also clear the original room reference
}

show_debug_message("--- obj_player Create Event RUNNING (Instance ID: " + string(id) + ") ---");

// === Movement Physics & State Variables ===
v_speed = 0;
gravity_force = 0.4;
flap_strength = -8;
max_v_speed_fall = 8;
horizontal_move_speed = 5;
face_dir = 1;
walk_animation_speed = 1; // Adjust as needed for your walking animations
// dive settings
dive_strength    = 96;
dive_max_speed   = 96;  // new: how fast you can fall when diving
isDiving         = false;  // true while in the dive
isSlamming       = false;  // true while playing slam animation
// === World Interaction & Collision ===
// — Dash settings —
dash_speed     = 48;    // pixels per frame during dash
dash_duration  = 10 ;    // how many frames the dash lasts
isDashing      = false; // true while in a dash
dash_timer     = 0;     // frames remaining in current dash
dash_dir       = 0;     // -1 for left, +1 for right

tilemap = layer_tilemap_get_id(layer_get_id("Tiles_Col")); // Your main collision tilemap
if (tilemap == -1) {
    show_debug_message("Warning [obj_player Create]: Main collision layer 'Tiles_Col' or its tilemap not found!");
} else {
    show_debug_message("obj_player Create: Main collision tilemap ID successfully found: " + string(tilemap));
}

tilemap_phase_id = layer_tilemap_get_id(layer_get_id("Tiles_Phase")); // The new phasable tilemap
if (tilemap_phase_id == -1) {
    show_debug_message("Warning [obj_player Create]: Phasing layer 'Tiles_Phase' or its tilemap not found! Phasing will not work.");
} else {
    show_debug_message("obj_player Create: Phasing tilemap ID successfully found: " + string(tilemap_phase_id));
}

// === Persistent RPG Data Setup ===
// This ensures player stats and party info are initialized or loaded.
if (!variable_instance_exists(id, "persistent_data_initialized")) {
    persistent_data_initialized = true; // Flag to run this block only once per instance lifetime if not persistent globally

    var _hero_key = "hero"; // Define the key for the main character

    // Initialize party members array if it doesn't exist or isn't an array
    if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
        global.party_members = [_hero_key]; // Start with the hero
    } else if (array_get_index(global.party_members, _hero_key) == -1) { // Add hero if not already in party
        array_push(global.party_members, _hero_key);
    }

    // Initialize party stats data structure (DS Map) if it doesn't exist
    if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
        global.party_current_stats = ds_map_create();
    }

    // Check if this is a new game start to initialize hero stats
    var _is_new_game = (variable_global_exists("start_as_new_game")) ? global.start_as_new_game : true;

    if (_is_new_game && !ds_map_exists(global.party_current_stats, _hero_key)) {
        // Fetch base character data, or use defaults if script/data is missing
        var _base_data = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_hero_key) : undefined;

        if (!is_struct(_base_data)) { // Default base data if fetching fails
            _base_data = {
                name: "Hero", class: "Hero",
                hp: 40, maxhp: 40, mp: 20, maxmp: 20,
                atk: 10, def: 5, matk: 8, mdef: 4, spd: 7, luk: 5,
                level: 1, xp: 0, xp_require: 100, // xp_require might be dynamic
                overdrive: 0, overdrive_max: 100,
                skills: [], // Array of skill IDs or structs
                equipment: { weapon: noone, offhand: noone, armor: noone, helm: noone, accessory: noone },
                resistances: { physical: 0 /* other resistances */ },
                character_key: _hero_key
            };
        }

        // Deep clone mutable parts like arrays and structs if they come from base_data
        var _skills = (variable_struct_exists(_base_data, "skills") && is_array(_base_data.skills)) ? variable_clone(_base_data.skills, true) : [];
        var _equip = (variable_struct_exists(_base_data, "equipment") && is_struct(_base_data.equipment)) ? variable_clone(_base_data.equipment, true) : {};
        var _resist = (variable_struct_exists(_base_data, "resistances") && is_struct(_base_data.resistances)) ? variable_clone(_base_data.resistances, true) : {};

        // XP requirement for next level (level 2)
        var _xp_req = script_exists(scr_GetXPForLevel) ? scr_GetXPForLevel(2) : (_base_data.xp_require ?? 100);

        // Construct the current stats struct for the hero
        var _hero_stats = {
            maxhp: _base_data.maxhp ?? 40,
            maxmp: _base_data.maxmp ?? 20,
            hp: _base_data.hp ?? _base_data.maxhp ?? 40, // Current HP, defaults to max HP
            mp: _base_data.mp ?? _base_data.maxmp ?? 20, // Current MP, defaults to max MP
            atk: _base_data.atk ?? 10,
            def: _base_data.def ?? 5,
            matk: _base_data.matk ?? 8,
            mdef: _base_data.mdef ?? 4,
            spd: _base_data.spd ?? 7,
            luk: _base_data.luk ?? 5,
            level: _base_data.level ?? 1,
            xp: _base_data.xp ?? 0,
            xp_require: _xp_req,
            skills: _skills,
            equipment: _equip,
            resistances: _resist,
            overdrive: _base_data.overdrive ?? 0,
            overdrive_max: _base_data.overdrive_max ?? 100,
            name: _base_data.name ?? "Hero",
            class: _base_data.class ?? "Adventurer",
            character_key: _hero_key
        };

        ds_map_add(global.party_current_stats, _hero_key, _hero_stats);
        // Potentially mark that new game initialization is done
        // global.start_as_new_game = false; // If this var controls it
    }
}

// === Overworld/Battle Temporary Variables ===
// These are related to combat states and animations, mostly for turn-based battles.
combat_state = "idle";         // Player's state in combat (e.g., "idle", "attacking", "casting")
origin_x = x;                  // Original x position (can be used for returning after an attack animation)
origin_y = y;                  // Original y position
target_for_attack = noone;     // Stores the instance ID of the current attack target
attack_fx_sprite = spr_pow;    // Default sprite for attack visual effect
attack_fx_sound = snd_punch;   // Default sound for attack impact
attack_animation_finished = false; // Flag for attack animation completion
stored_action_for_anim = undefined; // Stores action data if animation needs it later
sprite_assigned = false;       // General purpose flag for sprite assignment logic
turnCounter = 0;               // Generic turn counter, if needed outside battle system
attack_anim_speed = 0.5;       // Default speed for attack animations
idle_sprite = sprite_index;    // Stores the default idle sprite (might change with new movement)
attack_sprite_asset = -1;      // Asset index for attack-specific sprite
casting_sprite_asset = -1;     // Asset index for casting-specific sprite
item_sprite_asset = -1;        // Asset index for item-use-specific sprite
sprite_before_attack = sprite_index; // Stores sprite before an action like attacking
original_scale = image_xscale; // Stores original image scale for temporary changes

// IMPORTANT: No call to scr_player_movement_flappy() here.
// Movement logic is handled in the Step Event.
    
    // — Echo Missile Settings —  
missile_speed        = 10;    // pixels per frame  
missile_max_distance = 500;  // in pixels
    

// Invulnerability and Flashing
invulnerable_timer = 0;
is_flashing_visible = true; // true = fully visible, false = dimmed/invisible phase
flash_cycle_timer = 0;
flash_interval = 20;       // Toggle flash state every 4 frames
    
// === Knockback State Variables ===
is_in_knockback = false;     // True if player is currently being knocked back
knockback_timer = 0;         // Duration of the current knockback effect (in frames)
knockback_hspeed = 0;      // Horizontal speed component of the knockback
knockback_vspeed = 0;      // Vertical speed component of the knockback
knockback_friction = 0.85; // How quickly knockback speed reduces (e.g., 0.85 = 15% friction per step)
                           // Lower value = more friction, faster stop. Higher (closer to 1) = less friction.

show_debug_message("--- obj_player Create Event FINISHED ---");
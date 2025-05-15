/// @function scr_StartFixedEncounter(battle_formation_array)
/// @description Initiates a battle with a specific enemy formation.
///              Automatically uses obj_player's current context (x, y, current room)
///              for setting return coordinates. Sets up global variables for the battle,
///              transitions to rm_battle, and then EXITS the calling event if successful.
/// @param {Array<Asset.GMObject>} battle_formation_array  An array defining the enemy formation 
///                                                       (e.g., [obj_boss_example, obj_minion_a]).
/// @returns {Bool} Returns false if encounter setup fails BEFORE room_goto and exit are called.
///                 Does not return a value on success because 'exit' terminates the event.

var _formation_to_start = argument[0];

// 1. Validate the provided formation
if (!is_array(_formation_to_start) || array_length(_formation_to_start) == 0) {
    show_debug_message("scr_StartFixedEncounter: ERROR - Invalid or empty battle_formation_array provided. Cannot start encounter.");
    return false;
}

// Optional: Validate that all entries in the formation are actual object assets
for (var i = 0; i < array_length(_formation_to_start); i++) {
    if (!object_exists(_formation_to_start[i])) {
        show_debug_message("scr_StartFixedEncounter: ERROR - Invalid object index (" + string(_formation_to_start[i]) + ") found in battle_formation_array at position " + string(i) + ". Cannot start encounter.");
        return false;
    }
}

// 2. Find the player instance to get their context for return coordinates
//    Assumes there's an obj_player in the room.
var _player_instance = instance_find(obj_player, 0); 
if (!instance_exists(_player_instance)) {
    show_debug_message("scr_StartFixedEncounter: ERROR - obj_player instance not found. Cannot set return coordinates or start encounter.");
    return false;
}

// 3. Play encounter sound (optional, but good for fixed encounters too)
var _sfx_to_play = asset_get_index("snd_sfx_encounter"); // Or use a specific boss encounter sound if you have one
if (audio_exists(_sfx_to_play)) {
    audio_play_sound(_sfx_to_play, 10, false); // Priority 10, not looping
} else {
    show_debug_message("scr_StartFixedEncounter: Warning - Sound for encounter (e.g., snd_sfx_encounter) not found.");
}

// 4. Set global variables for the battle system using the player's current context
global.battle_formation = _formation_to_start; // The specific formation passed to the script
global.original_room = room;                   // The room where this script is being called from
global.return_x = _player_instance.x;          // Player's current x position
global.return_y = _player_instance.y;          // Player's current y position

// Note: Player state (like PLAYER_STATE.FLYING) upon returning from battle would typically be handled
// in obj_player's Create Event or a Room Start event when it processes global.return_x/y.

// 5. Transition to the battle room
var _battle_room_asset_id = asset_get_index("rm_battle"); // Ensure "rm_battle" is your actual battle room name
if (room_exists(_battle_room_asset_id)) {
    show_debug_message("scr_StartFixedEncounter: Initiating fixed battle! Formation: " + string(global.battle_formation) + 
                       ". Player will return to: " + room_get_name(global.original_room) + 
                       " @ (" + string(global.return_x) + "," + string(global.return_y) + ")");
    
    room_goto(_battle_room_asset_id);
    
    // IMPORTANT: 'exit' will terminate the execution of this script 
    // AND the event that called this script (e.g., the User Event 0 of your boss object).
    // This is usually desired to prevent further actions in the same step after a battle starts.
    exit; 
} else {
    show_debug_message("scr_StartFixedEncounter: CRITICAL ERROR - Battle room (rm_battle) does not exist! Cannot start encounter.");
    // Clean up globals if battle can't start to avoid inconsistent state
    global.battle_formation = undefined;
    global.original_room = undefined;
    global.return_x = undefined;
    global.return_y = undefined;
    return false;
}

// Fallback return, though 'exit' should prevent this from being reached on success.
return false;
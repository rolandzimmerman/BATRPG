/// obj_npc_recruitable_claude :: Create Event

// --- Inherit Parent Variables & Logic FIRST ---
event_inherited(); // Runs obj_npc_parent's Create Event

// --- Define Child-Specific Variables AFTER inheriting ---
// unique_npc_id = "claude_recruit_location_1"; // Kept if used for other things, not strictly for this persistence anymore
character_key = "claude";                    // Key matching the entry in global.party_members

show_debug_message("Claude Create (ID: " + string(id) + "): Character_key is '" + string(character_key) + "'");

// --- MODIFICATION FOR PERSISTENCE: Check if already in party ---
var _is_already_in_party = false;
if (variable_global_exists("party_members") && is_array(global.party_members)) {
    for (var i = 0; i < array_length(global.party_members); i++) {
        if (global.party_members[i] == character_key) {
            _is_already_in_party = true;
            break;
        }
    }
} else {
    show_debug_message("Claude Create (ID: " + string(id) + "): ERROR! global.party_members does not exist or is not an array! Cannot check recruitment status.");
    // Decide how to handle this error - maybe allow NPC to exist to prevent game stall? Or destroy?
    // For now, assume not in party if party_members is missing, but log an error.
}

if (_is_already_in_party) {
    show_debug_message("Claude Create (ID: " + string(id) + "): Character '" + character_key + "' IS already in global.party_members. Destroying this NPC instance.");
    instance_destroy(); 
    exit; // Stop further execution of this Create event
}
// --- END MODIFICATION ---

// If not destroyed, proceed with normal setup
can_recruit = true; // This flag now controls if this specific instance can be interacted with for recruitment

dialogue_data = [
    { name: "Claude", msg: "Looking for adventure? Maybe we should team up!" }
];

show_debug_message("Claude Create (ID: " + string(id) + ", CharacterKey: " + character_key + "): Instance created successfully. Not in party. Ready for interaction.");
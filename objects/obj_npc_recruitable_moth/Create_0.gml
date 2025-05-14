/// obj_npc_recruitable_izzy :: Create Event

// --- Inherit Parent Variables & Logic FIRST ---
event_inherited(); // Runs obj_npc_parent's Create Event

// --- Define Child-Specific Variables AFTER inheriting ---
// unique_npc_id = "izzy_recruit_location_1"; // Keep if used for other systems, not for this specific persistence
character_key = "izzy";                      // This is the key to check against global.party_members

show_debug_message("Izzy Create (ID: " + string(id) + "): Character_key is '" + string(character_key) + "'");

// --- PERSISTENCE CHECK: Check if already in party ---
var _is_already_in_party = false;
if (variable_global_exists("party_members") && is_array(global.party_members)) {
    for (var i = 0; i < array_length(global.party_members); i++) {
        if (global.party_members[i] == character_key) {
            _is_already_in_party = true;
            break;
        }
    }
} else {
    show_debug_message("Izzy Create (ID: " + string(id) + "): ERROR! global.party_members does not exist or is not an array! Cannot check recruitment status.");
    // Fallback: assume not in party if party_members is missing, but this indicates a larger issue.
}

if (_is_already_in_party) {
    show_debug_message("Izzy Create (ID: " + string(id) + "): Character '" + character_key + "' IS already in global.party_members. Destroying this NPC instance.");
    instance_destroy(); 
    exit; // Stop further execution of this Create event
}
// --- END PERSISTENCE CHECK ---

// If not destroyed, proceed with normal setup
can_recruit = true; 

// Initial dialogue before recruitment (can be overridden by User Event 1 or specific dialogue logic)
dialogue_data = [
    { name: "Izzy", msg: "Hey! You look like you could use someone with quick fingers. That's me!" } // Example Izzy dialogue
];

show_debug_message("Created recruitable NPC: Izzy (ID: " + string(id) + ", CharacterKey: " + character_key + "). Instance created successfully. Not in party. Ready for interaction.");
/// obj_npc_recruitable_gabby :: Create Event
/// Handles initialization for Gob's recruitment sequence.
enum GOB_RECRUIT_SEQ {
    PRE_SEQUENCE_CHECK,       // Initial check if already recruited
    START_CUTSCENE,           // Pause the game, prepare
    WALK_PATH_1,
    DIALOGUE_1_SETUP,
    DIALOGUE_1_WAIT,
    WALK_PATH_2_FAST,
    WALK_PATH_2_REVERSE_SETUP,
    WALK_PATH_2_REVERSE,
    DIALOGUE_2_SETUP,
    DIALOGUE_2_WAIT,
    PERFORM_RECRUIT,
    UNPAUSE_AND_FINISH,       // Unpause and clean up
    DONE                      // Final state before destruction
}
// --- Inherit Parent Variables & Logic FIRST ---
event_inherited(); // Runs obj_npc_parent's Create Event

// --- Define Child-Specific Variables AFTER inheriting ---
character_key = "gabby"; // This is the key for party systems, stats, etc.
var _display_name = "Gob"; // Name to use in dialogue for this scene

show_debug_message(_display_name + " Create (ID: " + string(id) + "): Character_key is '" + string(character_key) + "'");

// --- Sequence State & Properties ---
// Make sure GOB_RECRUIT_SEQ is defined in a script like scr_game_enums
sequence_state = GOB_RECRUIT_SEQ.PRE_SEQUENCE_CHECK; // Initial state
is_busy = true; // Gob will be busy, preventing standard player interaction via parent logic

// Path Assets (Make sure these Path assets exist in your project)
path1_asset = gub_recruitment_scene_1;
path2_asset = gub_recruitment_scene_2;

// Speeds
path1_walk_speed = 4;
path2_super_fast_speed = 35;
path2_reverse_slow_speed = -3;

// Dialogue Data Sets (Using _display_name)
dialogue_set_1 = [
    { name: _display_name, msg: "Hey! You're the one who broke through the cave-in and handled that ogre!" },
    { name: _display_name, msg: "Wow! So cool... I've got some skills, too. Maybe I can help you." },
    { name: _display_name, msg: "I can't cast a fire spell yet, but I can fly on this broomstick. Watch." }
];

dialogue_set_2 = [
    { name: _display_name, msg: "Ouch! Well, I'm gonna get better." },
    { name: _display_name, msg: "If we team up, we'll be unstoppable!" }
];

dialogue_data = []; // Clear parent's default dialogue
can_recruit = false;

// Animation Sprites (Ensure these sprite assets exist)
sprite_idle = gob; // Replace with your actual sprite names
sprite_walk = gob; // Replace with your actual sprite names
sprite_smashed = gob_smashed; // <<< ADD THIS LINE (Your new smashed sprite)
sprite_index = sprite_idle;
image_speed = 0;
image_xscale = 1;

show_debug_message(_display_name + " (ID: " + string(id) + ") initialized for recruitment sequence. State: PRE_SEQUENCE_CHECK");
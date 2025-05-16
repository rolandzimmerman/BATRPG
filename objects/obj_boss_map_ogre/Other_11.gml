/// obj_npc_dom :: User Event 1
// Dialog Definition Event for Dom - Overrides Parent's User Event 1

show_debug_message("Dom User Event 1: Defining dialog for instance ID " + string(id));

// --- Dom's Specific Dialog Data ---
dialog_initial = [
    { name: "System", msg: "On your travels, you will encounter enemies at random." },
    { name: "System", msg: "You will choose your actions in battle with each of the buttons on the controller." },
    { name: "System", msg: "Pay attention to the turn order in the top right. Sometimes you or your enemies will get two turns in a row." },
    { name: "System", msg: "Earn experience through battling to become stronger." },
    {
        name: "System",
        msg: "Uh-oh! Here comes an enemy now! Get ready!",
        script_to_run: scr_StartFixedEncounter, // <-- Directly reference the inventory script
        script_args: [[obj_enemy_goblin]]          // <-- Define arguments as an array
    }// Optional reaction
];

dialog_repeat = [
    { name: "System", msg: "Remember to keep a close eye on the turn order in the top right of the battle screen." }
];

// DO NOT CALL event_inherited() HERE!

// Note: The intermediate 'scr_give_potion' script is no longer needed for this specific action.
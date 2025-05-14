/// obj_npc_izzy :: User Event 1
// Dialog Definition Event for izzy - Overrides Parent's User Event 1

show_debug_message("izzy User Event 1: Defining dialog for instance ID " + string(id));

// --- izzy's Specific Dialog Data ---
// Define the dialog arrays here. These become instance variables.
dialog_initial = [
    { name: "System", msg: "Bats can hang from the ceiling. Fly into the ceiling to walk on it. Press A again to flap your wings off the ceiling." }
];

dialog_repeat = [
    { name: "System", msg: "Bats can hang from the ceiling. Fly into the ceiling to walk on it. Press A again to flap your wings off the ceiling." }
];

// DO NOT CALL event_inherited() HERE!
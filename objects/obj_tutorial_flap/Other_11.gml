/// obj_npc_izzy :: User Event 1
// Dialog Definition Event for izzy - Overrides Parent's User Event 1

show_debug_message("izzy User Event 1: Defining dialog for instance ID " + string(id));

// --- izzy's Specific Dialog Data ---
// Define the dialog arrays here. These become instance variables.
dialog_initial = [
    { name: "System", msg: "Tap the A button to flap your wings. Tap continuously to control your flight." }
];

dialog_repeat = [
    { name: "System", msg: "Tap the A button to flap your wings. Tap continuously to control your flight." }
];

// DO NOT CALL event_inherited() HERE!
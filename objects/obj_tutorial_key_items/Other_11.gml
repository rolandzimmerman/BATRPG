/// obj_npc_izzy :: User Event 1
// Dialog Definition Event for izzy - Overrides Parent's User Event 1

show_debug_message("izzy User Event 1: Defining dialog for instance ID " + string(id));

// --- izzy's Specific Dialog Data ---
// Define the dialog arrays here. These become instance variables.
dialog_initial = [
    { name: "System", msg: "Through your adventures, you will find magical items. Some will grant you new abilities and make difficult or impossible obstacles passable. Try getting the magical item below!" }
];

dialog_repeat = [
    { name: "System", msg: "Through your adventures, you will find magical items. Some will grant you new abilities and make difficult or impossible obstacles passable." }
];

// DO NOT CALL event_inherited() HERE!
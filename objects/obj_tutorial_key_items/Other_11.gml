/// obj_npc_izzy :: User Event 1
// Dialog Definition Event for izzy - Overrides Parent's User Event 1

show_debug_message("izzy User Event 1: Defining dialog for instance ID " + string(id));

// --- izzy's Specific Dialog Data ---
// Define the dialog arrays here. These become instance variables.
dialog_initial = [
    { name: "System", msg: "Through your adventures, you will find magical items, like this gem. Some will grant you new abilities and make difficult or impossible obstacles passable. Try using the skill unlocked by the gem in battle, too!" },
    { name: "System", msg: "Other Items, like the one to the left, are equipment. Open your menu with the START button and equip your new item." },
    { name: "System", msg: "Don't forget to save often at bat statues through your adventures!" }
];

dialog_repeat = [
    { name: "System", msg: "Through your adventures, you will find magical items. Some will grant you new abilities and make difficult or impossible obstacles passable." }
];

// DO NOT CALL event_inherited() HERE!
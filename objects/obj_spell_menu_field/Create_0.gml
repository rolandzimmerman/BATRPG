/// @description Initialize Field Spell Menu state

active = true;          
calling_menu = noone;   // Set by obj_pause_menu

character_index = 0;    // Index for selecting which character casts
spell_index = 0;        // Index for the selected character's spell list (populated later)
target_party_index = 0; // Index for the party target list (used later)
menu_state = "character_select"; // <<< Start by selecting the caster

usable_spells = [];     // Array to hold the selected character's usable field spells
selected_caster_key = ""; // Store the key of the character chosen
self.image_speed = .05;         // THIS makes it animate at 1 sprite frame per game frame
show_debug_message("obj_spell_menu_field Created. Initial State: " + menu_state);
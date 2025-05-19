/// obj_npc_recruitable_gabby :: User Event 0 (Interaction)

// If Gob is busy with her recruitment sequence, or if the sequence is intended to be the only interaction:
if (is_busy || sequence_state != GOB_RECRUIT_SEQ.DONE) { // Or simply `is_busy` if that's always true during sequence
    show_debug_message(character_key + " User Event 0: Gob is busy with sequence or sequence incomplete. Interaction ignored.");
    exit;
}

// Fallback or post-recruitment interaction if needed (though this instance is usually destroyed)
show_debug_message(character_key + " User Event 0: Fallback interaction. Instance should ideally be gone if recruited.");
// (Your existing User Event 0 logic for post-recruit dialogue if the instance somehow persists and is not busy)
// For example:
var _char_key = character_key;
var _dialogue = (variable_instance_exists(id,"dialogue_data_post_recruit")) 
               ? dialogue_data_post_recruit 
               : [ { name: (variable_struct_exists(self.data,"name") ? self.data.name : _char_key), msg: "Good to see you around!" } ]; // Assuming self.data.name exists
if(script_exists(create_dialog)) create_dialog(_dialogue);
/// obj_dive_switch :: Step Event

if (!activated) {
    // (1) Look for a diving player overlapping this switch
    var p = instance_place(x, y, obj_player);
    if (p != noone && p.isDiving) {
        // (2) Activate
        activated    = true;
        sprite_index = spr_switch_on;
        audio_play_sound(snd_sfx_switch, 1, 0);

        // (3) Optionally, stop the player's dive here
        with (p) {
            isDiving     = false;
            player_state = PLAYER_STATE.WALKING_FLOOR;
            v_speed      = 0;
        }

        // (4) Any other trigger logic (doors, etc.)…
    }
}

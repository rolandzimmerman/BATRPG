/// obj_dive_switch :: Step Event

if (!activated) {
    var p = instance_place(x, y, obj_player);
    if (p != noone && p.isDiving) {
// inside obj_dive_switch :: Step Event, when you detect a diving player:
activated    = true;
sprite_index = spr_switch_on;
audio_play_sound(snd_sfx_switch, 1, 0);

// stop the player’s dive
with (p) {
    isDiving     = false;
    player_state = PLAYER_STATE.WALKING_FLOOR;
    v_speed      = 0;
}

// only open gates with the same group_id
with (obj_gate) {
    if (group_id == other.group_id) {
        event_perform(ev_other, ev_user0);
    }
}
}
}
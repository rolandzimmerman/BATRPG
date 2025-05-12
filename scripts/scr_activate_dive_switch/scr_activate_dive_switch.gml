/// @function scr_activate_dive_switch()
/// @description Activates the switch object, swaps its sprite, and plays SFX.
function scr_activate_dive_switch() {
    // fire the switch’s User 0 event
    event_perform_object(self, ev_other, ev_user0);
}

if ((self.tilemap != -1 && place_meeting(x, y, self.tilemap)) || 
    (self.tilemap_phase_id != -1 && place_meeting(x, y, self.tilemap_phase_id))) {
    y -= 1;
    // show_debug_message("Player: Soft push out of solid applied.");
}
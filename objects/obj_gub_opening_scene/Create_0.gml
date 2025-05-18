// In the Creation Code of a specific instance in the Room Editor
// or in the object's Create Event if this applies to all instances by default

var current_path_speed = 2; // Store the initial speed
path_start(opening_cutscene_rm_1, current_path_speed, path_action_reverse, true);

// Set initial sprite direction based on current_path_speed
// Assuming sprite faces right by default (+1 for image_xscale means facing right)
if (current_path_speed > 0) {
    image_xscale = 1;
} else if (current_path_speed < 0) {
    image_xscale = -1;
}
// If current_path_speed is 0, image_xscale will remain its default (usually 1)
// You could also initialize a variable to store the intended facing if speed is 0.
// For example:
// intended_facing = 1; // 1 for right, -1 for left
// image_xscale = intended_facing;
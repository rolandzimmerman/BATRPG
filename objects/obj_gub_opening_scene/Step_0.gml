// In the Object's Step Event

// Check if the instance is actually moving on a path (path_speed is not 0)
// and if its horizontal direction on the path has changed relative to its current facing.

// This variable will store the previous path_speed if you need more complex logic,
// but for simple flipping based on current speed sign, it's not strictly needed here.
// static last_path_speed = path_speed; // 'static' keeps its value between calls in GMS2.3+

if (path_speed != 0) {
    // If path_speed is positive, sprite should face its normal direction (e.g., right)
    if (path_speed > 0) {
        image_xscale = 1;
    }
    // If path_speed is negative, sprite should face the opposite direction (e.g., left)
    else { // path_speed < 0
        image_xscale = -1;
    }
}

// If you had more complex conditions or wanted to only flip on change:
// if (path_speed > 0 && image_xscale != 1) {
// image_xscale = 1;
// } else if (path_speed < 0 && image_xscale != -1) {
// image_xscale = -1;
// }
// last_path_speed = path_speed;
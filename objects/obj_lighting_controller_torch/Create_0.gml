// The surface where we'll draw our lighting effects
global.lighting_surface = -1 ; // Initialize to -1 (invalid surface ID)

// The overall darkness/ambient shadow level (0 = no darkness, 1 = full black)
global.ambient_darkness_alpha = .5; // e.g., 75% dark

// Get the initial view size (can also use room_width/room_height if not using views or surface should cover whole room)
var _view_w = camera_get_view_width(view_camera[0]);
var _view_h = camera_get_view_height(view_camera[0]);

// Create the lighting surface
// It's crucial to check if it exists first, especially if the object is persistent or rooms restart
if (!surface_exists(global.lighting_surface)) {
    global.lighting_surface = surface_create(_view_w, _view_h);
} else {
    // If it does exist but is the wrong size (e.g., view changed), recreate it
    var _surf_w_current = surface_get_width(global.lighting_surface);
    var _surf_h_current = surface_get_height(global.lighting_surface);
    if (_surf_w_current != _view_w || _surf_h_current != _view_h) {
        surface_free(global.lighting_surface);
        global.lighting_surface = surface_create(_view_w, _view_h);
    }
}
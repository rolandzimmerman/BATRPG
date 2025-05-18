// Always free surfaces when they are no longer needed to prevent memory leaks
if (surface_exists(global.lighting_surface)) {
    surface_free(global.lighting_surface);
    global.lighting_surface = -1; // Mark as freed
}
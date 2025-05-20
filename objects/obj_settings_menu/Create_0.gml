/// ===================================================================
/// obj_settings_menu :: Create Event
/// ===================================================================
active                   = true;
opened_by_instance_id    = noone;      // default, overwritten by caller
settings_index           = 0;
settings_items           = ["Display Mode","Resolution","SFX Volume","Music Volume","Back"];
menu_item_count          = array_length(settings_items);

dropdown_display_open    = false;
dropdown_resolution_open = false;
dropdown_hover_index     = -1;

dropdown_display_options = ["Windowed","Fullscreen","Borderless"];
dropdown_display_index   = 0;

// sync or initialize globals…
if variable_global_exists("display_mode") {
    for (var i = 0; i < array_length(dropdown_display_options); i++)
        if (dropdown_display_options[i] == global.display_mode) {
            dropdown_display_index = i;
            break;
        }
} else {
    global.display_mode = dropdown_display_options[0];
}

if !variable_global_exists("resolution_options") {
    global.resolution_options = [[1280,720],[1920,1080],[1024,768]];
}
if !variable_global_exists("resolution_index") {
    global.resolution_index = 0;
}

if !variable_global_exists("sfx_volume")   global.sfx_volume   = 0.75;
if !variable_global_exists("music_volume") global.music_volume = 0.50;

input_cooldown = 0;
image_speed    = 0.05;

show_debug_message("obj_settings_menu created; opened_by=" + string(opened_by_instance_id));

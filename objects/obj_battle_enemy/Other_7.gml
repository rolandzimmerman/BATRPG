// obj_battle_enemy :: Animation End Event
show_debug_message("ENEMY " + string(id) + ": Animation End. Sprite: " + sprite_get_name(sprite_index) + ", State: " + combat_state);

var current_attack_anim_sprite = variable_struct_get(data, "attack_sprite") ?? spr_invalid;
var current_idle_sprite = variable_struct_get(data, "sprite_index") ?? spr_invalid;
var current_death_anim_sprite = variable_struct_get(data, "death_anim_sprite") ?? spr_death;
var current_corpse_sprite = variable_struct_get(data, "corpse_sprite") ?? spr_dead;

if (combat_state == "attack_start" && sprite_index == current_attack_anim_sprite) {
    show_debug_message(" -> Attack animation finished for " + string(id));
    x = origin_x;
    y = origin_y;
    image_xscale = original_scale;
    image_yscale = original_scale;
    
    combat_state = "idle";
    sprite_index = current_idle_sprite;
    image_index = 0;
    if (sprite_exists(sprite_index)) {
        image_speed = (sprite_get_number(sprite_index) > 1) ? (variable_struct_get(data, "idle_anim_speed") ?? 0.2) : 0; 
    } else {
        image_speed = 0;
    }
    if(image_speed == 0) image_index = 0;

    if (instance_exists(obj_battle_manager)) {
        obj_battle_manager.current_attack_animation_complete = true;
        show_debug_message(" -> Signaled obj_battle_manager.current_attack_animation_complete = true");
    }
}
else if (combat_state == "dying" && sprite_index == current_death_anim_sprite) {
    show_debug_message(" -> Death animation finished for " + string(id));
    sprite_index = current_corpse_sprite;
    image_index  = 0;
    image_speed  = 0; 
    combat_state = "corpse"; 
    show_debug_message(" -> Changed to corpse state. Sprite: " + sprite_get_name(sprite_index));
}
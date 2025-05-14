/// obj_hp_percent_trap :: Step Event

// Handle trap cooldown
if (current_cooldown > 0) {
    current_cooldown -= 1;
    exit; // Trap is cooling down, do nothing else
}

// Check for collision with the player
var player_instance = instance_place(x, y, obj_player);

if (instance_exists(player_instance)) {
    // Check if the specific player instance is currently invulnerable
    // This assumes obj_player has an 'invulnerable_timer' variable
    if (variable_instance_exists(player_instance, "invulnerable_timer") && player_instance.invulnerable_timer > 0) {
        // Player is invulnerable, trap does nothing to this player right now
        exit;
    }

    // --- Player collided and is NOT invulnerable ---
    show_debug_message("Trap collision with player ID: " + string(player_instance.id));

    // 1. Activate trap cooldown
    current_cooldown = trap_cooldown_frames;

    // 2. Play trap activation sound (optional)
    if (audio_exists(snd_trap_activate)) {
        audio_play_sound(snd_trap_activate, 10, false);
    }

    // 3. Damage all party members
    var hero_damage_taken = 0; // To store damage taken by the main player for popup
    var main_player_character_key = "hero"; // Default assumption, or get from player_instance.data.character_key if available
    
    // Get the character key of the colliding player instance to ensure popup is for them
    if (variable_instance_exists(player_instance, "data") && is_struct(player_instance.data) && variable_struct_exists(player_instance.data, "character_key")) {
        main_player_character_key = player_instance.data.character_key;
    }


    if (variable_global_exists("party_members") && is_array(global.party_members) &&
        variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
        
        for (var i = 0; i < array_length(global.party_members); i++) {
            var char_key = global.party_members[i];
            if (ds_map_exists(global.party_current_stats, char_key)) {
                var char_stats = global.party_current_stats[? char_key];
                
                if (is_struct(char_stats) && variable_struct_exists(char_stats, "hp") && variable_struct_exists(char_stats, "maxhp")) {
                    var damage_to_deal = floor(char_stats.maxhp * damage_percent);
                    if (damage_to_deal < 1 && (char_stats.maxhp * damage_percent) > 0) { // Ensure at least 1 damage if % > 0
                        damage_to_deal = 1;
                    }
                    
                    var old_hp = char_stats.hp;
                    char_stats.hp = max(0, char_stats.hp - damage_to_deal); // Prevent HP < 0
                    
                    show_debug_message("Damaged " + char_key + ": " + string(damage_to_deal) + " (HP: " + string(old_hp) + " -> " + string(char_stats.hp) + ")");

                    if (char_key == main_player_character_key) {
                        hero_damage_taken = damage_to_deal;
                    }
                }
            }
        }
    }

    // 4. Apply invulnerability to the collided player instance
    player_instance.invulnerable_timer = player_invulnerability_duration_frames;
    player_instance.is_flashing_visible = true; // Start the flash cycle by being visible
    player_instance.flash_cycle_timer = player_instance.flash_interval; // Initialize the flash sub-timer
    
    show_debug_message("Trap Hit: Player ID " + string(player_instance.id) + 
                       " invulnerability set for " + string(player_invulnerability_duration_frames) + " frames. " +
                       "Flashing initiated (is_flashing_visible=true, flash_cycle_timer=" + string(player_instance.flash_cycle_timer) + ")");

    // --- APPLY KNOCKBACK ---
    var knockback_force_amount = 15; // << ADJUST THIS FOR STRENGTH (e.g., 5 to 15)
    var knockback_effect_duration = 25; // << ADJUST FOR DURATION in frames (e.g., 15-30 frames)
    
    // Calculate direction from trap to player (player gets pushed away from trap center)
    var kb_dir = point_direction(self.x, self.y, player_instance.x, player_instance.y);
    
    player_instance.is_in_knockback = true;
    player_instance.knockback_timer = knockback_effect_duration;
    player_instance.knockback_hspeed = lengthdir_x(knockback_force_amount, kb_dir);
    player_instance.knockback_vspeed = lengthdir_y(knockback_force_amount, kb_dir);
    
    // Optionally, you can add a small upward component to v_speed to make it feel more like a hit
    // player_instance.v_speed = -2; // Or player_instance.knockback_vspeed -= 2; if you want it part of the decaying speed

    show_debug_message("Applied knockback to Player ID " + string(player_instance.id) + 
                       ": HSpeed=" + string(player_instance.knockback_hspeed) + 
                       ", VSpeed=" + string(player_instance.knockback_vspeed) + 
                       ", Duration=" + string(player_instance.knockback_timer));
    // --- END KNOCKBACK ---
    
    // 5. Play player hurt sound (optional)
    if (audio_exists(snd_player_hit_by_trap)) {
        audio_play_sound(snd_player_hit_by_trap, 10, false);
    }

    // 6. Show damage popup over the collided player's head (for their damage)
    if (hero_damage_taken > 0 && object_exists(obj_popup_damage)) {
        var popup = instance_create_layer(player_instance.x, player_instance.bbox_top, "Instances", obj_popup_damage); // Or your effects layer
        if (instance_exists(popup)) {
            popup.damage_amount = hero_damage_taken;
            show_debug_message("Created damage popup for " + string(hero_damage_taken) + " damage over player " + string(player_instance.id));
        }
    }
}
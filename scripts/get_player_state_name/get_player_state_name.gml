// Script: get_player_state_name
function get_player_state_name(player_state_enum) {
    switch (player_state_enum) {
        case PLAYER_STATE.FLYING: return "FLYING"; // Now refers to global PLAYER_STATE.FLYING
        case PLAYER_STATE.WALKING_FLOOR: return "WALKING_FLOOR";
        case PLAYER_STATE.WALKING_CEILING: return "WALKING_CEILING";
        default: return "UNKNOWN_STATE (" + string(player_state_enum) + ")";
    }
}
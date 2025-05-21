/// @function ds_type_to_string(ds_type_constant_or_false)
/// @param {real/bool} ds_type_constant_or_false Value from ds_exists(..., type)
function ds_type_to_string(type_val) {
    if (type_val == false) return "false (not a ds or invalid type)";
    switch(type_val) {
        case ds_type_map: return "ds_type_map";
        case ds_type_list: return "ds_type_list";
        case ds_type_grid: return "ds_type_grid";
        case ds_type_priority: return "ds_type_priority";
        case ds_type_stack: return "ds_type_stack";
        case ds_type_queue: return "ds_type_queue";
        default: return "unknown_ds_type_constant (" + string(type_val) + ")";
    }
}
/// @function scr_sanitize_data_for_ds_write(data_value)
/// @description Recursively sanitizes a value. Converts 'undefined' to 'null'.
/// @param {*} data_value The data to sanitize.
/// @returns {*} The sanitized data, guaranteed not to be 'undefined'.
function scr_sanitize_data_for_ds_write(data_value) {
    if (is_undefined(data_value)) {
        return null; 
    }
    if (is_array(data_value)) {
        var _arr = data_value;
        if (array_length(_arr) == 0) return []; // Return new empty array
        var _new_arr = array_create(array_length(_arr));
        for (var i = 0; i < array_length(_arr); i++) {
            _new_arr[i] = scr_sanitize_data_for_ds_write(_arr[i]); // Recurse for each element
        }
        return _new_arr;
    } else if (is_struct(data_value)) {
        var _struct = data_value;
        var _new_struct = {}; // Always create a new struct
        var _keys = variable_struct_get_names(_struct);
        
        try {
            if (array_length(_keys) == 0 && string(_struct) != "{ }" && string(_struct) != "{}") {
                show_debug_message("[SanitizeSave] Warning: Encountered an unusual or empty struct: " + string(_struct) + ". Returning empty new GML struct.");
                return {};
            }
        } catch(e_struct_check) {
            show_debug_message("[SanitizeSave] Warning: Error inspecting struct: " + string(_struct) + ". Error: " + string(e_struct_check) + ". Returning empty new GML struct.");
            return {};
        }

        for (var i = 0; i < array_length(_keys); i++) {
            var _key = _keys[i];
            var _val;
            try {
                 _val = variable_struct_get(_struct, _key);
            } catch(e_val_get) {
                show_debug_message("[SanitizeSave] Error accessing key '"+_key+"' in struct. Treating value as null. Struct: " + string(_struct) + ". Error: " + string(e_val_get));
                _val = null; 
            }
            _new_struct[$ _key] = scr_sanitize_data_for_ds_write(_val); 
        }
        return _new_struct;
    } else if (is_numeric(data_value)) { 
        return data_value;
    } else if (is_string(data_value)) {
        return data_value;
    } else if (is_method(data_value)) {
        show_debug_message("[SanitizeSave] Warning: Method encountered. Storing as null.");
        return null;
    } else if (is_ptr(data_value)) {
        show_debug_message("[SanitizeSave] Warning: Pointer encountered. Storing as null.");
        return null;
    } else if (is_int64(data_value)) {
        var _num_val_real = real(data_value);
        if (int64(_num_val_real) == data_value) { 
             return _num_val_real;
        }
        show_debug_message("[SanitizeSave] Warning: int64 '" + int64_to_string(data_value) + "' may lose precision or cannot be represented as real. Storing as null.");
        return null; 
    }
    
    show_debug_message("[SanitizeSave] Warning: Value '" + string(data_value) + "' of unhandled type '" + typeof(data_value) + "' encountered. Storing as null.");
    return null; 
}
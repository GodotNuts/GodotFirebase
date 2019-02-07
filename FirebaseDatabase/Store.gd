extends Node

var data_set = {}

const path_separator = "/"

func put(path, data):
    put_recursive(path, data, "", data_set)

func put_recursive(path, data, previous_key, current_data_set):
    if path == path_separator:
        if previous_key.length() == 0:
            data_set = data
        else:
            current_data_set[previous_key] = data
    else:
        var key = get_key(path)
        if !key:
            assert(false)
        var chopped_path = remove_key(path, key)
        if !chopped_path:
            assert(false)
            
        put_recursive(chopped_path, data, key, current_data_set[previous_key])

func get_key(path):
    var first_slash_idx = path.find(path_separator)
    var second_slash_idx = path.find(path_separator, first_slash_idx + path_separator.length())
    if first_slash_idx and second_slash_idx:
        return path.substr(first_slash_idx, second_slash_idx - first_slash_idx)
    
    return null
    
func remove_key(path, key):
    if !path or !key:
        return null
    
    return path.replace(path_separator + key, "")

func patch(path, data):
    patch_recursive(path, data, "", data_set)

func patch_recursive(path, data, previous_key, current_data_set):
    if path == path_separator:
        if previous_key.length() == 0:
            data_set = data
        else:
            for key in data.keys():
                current_data_set[key] = data[key]
    else:
        var key = get_key(path)
        if !key:
            assert(false)
        var chopped_path = remove_key(path, key)
        if !chopped_path:
            assert(false)
            
        patch_recursive(chopped_path, data, key, current_data_set[previous_key])

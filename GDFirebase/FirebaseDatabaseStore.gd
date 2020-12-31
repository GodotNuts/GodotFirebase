tool
extends Node

var data_set = {}

const path_separator = "/"

func put(path, data):
    put_recursive(path, data, "", data_set)

func put_recursive(path, data, previous_key, current_data_set):
    if path == path_separator:
        if previous_key.length() == 0:
            if data:
                data_set = data
        else:
            if data:
                current_data_set[previous_key] = data
    else:
        var key = get_key(path)
        if !key:
            assert(false)
        var chopped_path = remove_key(path, key)
        if !chopped_path:
            chopped_path = path_separator
            
        if previous_key:
            put_recursive(chopped_path, data, key, current_data_set[previous_key])
        else:
            if data:
                data_set[key] = data
            

func get_key(path : String):
    var first_slash_idx = path.find(path_separator)
    var second_slash_idx = path.find(path_separator, first_slash_idx + path_separator.length())
    if first_slash_idx != -1 and second_slash_idx != -1:
        return path.substr(first_slash_idx, second_slash_idx - first_slash_idx)
    elif first_slash_idx != -1:
        var return_key = path.substr(first_slash_idx + path_separator.length(), path.length() - path_separator.length())
        return return_key
    
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
            if data:
                data_set = data
        else:
            if data:
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

template = mp.get_property("screenshot-template")

function remove_text_in_brackets(str)
    return string.gsub(str, "%[.-%]", "")  
end

function get_filename_before_dash(str)
    local dash_pos = string.find(str, "-") 
    if dash_pos then
        return string.sub(str, 1, dash_pos - 1)  
    else
        return str 
    end
end

function folder_screenshot()
    local filename = mp.get_property("filename")
    local folder_filename = string.gsub(string.sub(remove_text_in_brackets(get_filename_before_dash(filename)), 1, 100), "%s+$", "")
    named_dir = folder_filename.."/"..template
    mp.set_property("screenshot-template", named_dir)
end

mp.register_event("file-loaded", folder_screenshot)

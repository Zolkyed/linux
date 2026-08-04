local screenshot_template = mp.get_property("screenshot-template", "%F-%p-%n")

local function screenshot_folder(filename)
    local name = filename:match("^([^-]+)") or filename
    name = name:gsub("%[.-%]", "")
    name = name:sub(1, 100):gsub("^%s+", ""):gsub("%s+$", "")

    name = name:gsub("%c", "_"):gsub('[<>:"/\\|%?%*]', "_")
    name = name:gsub("[%. ]+$", "")

    return name ~= "" and name or "screenshots"
end

local function update_screenshot_template()
    local filename = mp.get_property("filename", "")
    local template = screenshot_folder(filename) .. "/" .. screenshot_template
    mp.set_property("screenshot-template", template)
end

mp.register_event("file-loaded", update_screenshot_template)

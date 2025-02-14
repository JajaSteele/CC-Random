local args = {...}

local file_path = args[1]

local file = io.open(file_path, "r")

if file then
    local size = string.len(file:read("*a"))
    print("Size: "..size.."B")
else
    error("Couldn't open file")
end
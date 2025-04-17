local json = require("json")
local sp = require("serpent")
local fs = require('fs')

local input_list = fs.readdirSync("./input")

print("Found "..#input_list.." input files")
print("Reading..")

local data = {}

for k,file in ipairs(input_list) do
    print("Reading file "..k.."/"..#input_list)
    local file_io = io.open("input/"..file, "r")
    if file_io then
        local file_data = file_io:read("*a")
        file_io:close()
        local file_decoded = json.decode(file_data)
        data[file_decoded.block or file:match("(.+)%..+")] = {
            file_decoded.stats
        }
    end
end

if not fs.existsSync("./output") then
    fs.mkdirSync("./output")
end

print("Enter a name:")
local preset_name = io.read()

if not fs.existsSync("./output/"..preset_name) then
    fs.mkdirSync("./output/"..preset_name)
end

local output_io = io.open("./output/"..preset_name.."/preset.json", "w")
if not output_io then
    error("Unable to open file '".."./output/"..preset_name.."/preset.json".."'")
end
output_io:write(json.encode(data))
output_io:close()
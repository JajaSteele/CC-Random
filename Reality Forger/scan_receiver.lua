local modems = {peripheral.find("modem")}
local forge = peripheral.find("reality_forger")
local completion = require("cc.completion")
local registry = peripheral.find("informative_registry")
local storage = peripheral.find("nbtStorage")
local lua_lzw = require("lualzw")

local cached_anchor_list = forge.detectAnchors()

local forger_bounds = {
    pos_x = -50,
    pos_y = -50,
    pos_z = -50,
    neg_x = 50,
    neg_y = 50,
    neg_z = 50,
}

for k,coords in pairs(cached_anchor_list) do
    if forger_bounds.pos_x < coords.x then
        forger_bounds.pos_x = coords.x
    end
    if forger_bounds.neg_x > coords.x then
        forger_bounds.neg_x = coords.x
    end

    if forger_bounds.pos_y < coords.y then
        forger_bounds.pos_y = coords.y
    end
    if forger_bounds.neg_y > coords.y then
        forger_bounds.neg_y = coords.y
    end

    if forger_bounds.pos_z < coords.z then
        forger_bounds.pos_z = coords.z
    end
    if forger_bounds.neg_z > coords.z then
        forger_bounds.neg_z = coords.z
    end
end

local function prettySize(size)
    if size >= 1000000000000 then
        return string.format("%.2f", size/1000000000000).." TB"
    elseif size >= 1000000000 then
        return string.format("%.2f", size/1000000000).." GB"
    elseif size >= 1000000 then
        return string.format("%.2f", size/1000000).." MB"
    elseif size >= 1000 then
        return string.format("%.1f", size/1000).." kB"
    else
        return string.format("%.0f", size).." B"
    end
end

local function getTableSize(tbl)
    local count = 0
    for k,v in pairs(tbl) do
        count = count+1
    end
    return count
end

local function getBlockCount(data)
    local count = 0
    for k,v in pairs(data) do
        count = count+#v
    end
    return count
end

local function colorPrint(color, ...)
    local old_color = term.getTextColor()
    term.setTextColor(color)
    print(...)
    term.setTextColor(old_color)
end

local function within_bounds(pos)
    if (pos.x >= forger_bounds.neg_x and pos.x <= forger_bounds.pos_x) and (pos.y >= forger_bounds.neg_y and pos.y <= forger_bounds.pos_y) and (pos.z >= forger_bounds.neg_z and pos.z <= forger_bounds.pos_z) then
        return true
    else
        return false
    end
end

local function has_value(table_to_check, value)
    for k,v in pairs(table_to_check) do
        if v == value or v:match(value) then
            return true
        end
    end
end

local blocks_list = registry.list("block")
local allowed_blocks_list = {}
for k,v in pairs(blocks_list) do
    local data = registry.describe("block", v)
    if (not has_value(data.tags, "forger_forbidden") and not v:match("minecraft:.*air")) then
        allowed_blocks_list[#allowed_blocks_list+1] = v
    end
end

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local config = {
    clear_block = "stone"
}

local function loadConfig()
    if fs.exists("scanner_config.txt") then
        local file = io.open("scanner_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open("scanner_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()

local decoded_data = {}

local offset_x = 0
local offset_y = 0
local offset_z = 0

local cmd_list = {
    "receive",
    "clear",
    "draw",
    "offset <x> <y> <z>",
    "fill <block>",
    "random",
    "setclear <block>",
    "bounds",
    "save",
    "load"
}

while true do
    term.clear()
    term.setCursorPos(1,1)
    print("Command:")
    local input = read(nil, nil, function(text) return completion.choice(text, cmd_list) end, "")
    local input_split = split(input, " ")

    if input_split[1] == "receive" then
        print("Receiver ID: "..os.getComputerID())
        print("Awaiting Scan..")

        local sender, data, protocol = rednet.receive("reality_scan")

        print("Received scan! Size:")
        print(#data)
        decoded_data = textutils.unserialise(data)
    elseif input_split[1] == "save" then
        print("Serializing..")
        local serialized_data = textutils.serialise(decoded_data, {compact=true})
        print("Compressing data.. ("..prettySize(#serialized_data)..")")
        local compressed_data = lua_lzw.compress(serialized_data)
        print("Saving.. ("..prettySize(#compressed_data)..")")
        storage.writeTable({data=compressed_data})
        print("Saved!")
    elseif input_split[1] == "load" then
        print("Reading..")
        local compressed_data = storage.read().data
        if compressed_data then            
            print("Decompressing.. ("..prettySize(#compressed_data)..")")
            local decompressed_data = lua_lzw.decompress(compressed_data)
            if decompressed_data then
                print("Unserializing.. ("..prettySize(#decompressed_data)..")")
                decoded_data = textutils.unserialise(decompressed_data)
                print("Loaded!")
            else
                colorPrint(colors.red, "Unable to decompress data!")
            end
        else
            colorPrint(colors.red, "Unable to read data!")
        end
    elseif input_split[1] == "bounds" then
        print("Boundaries:")
        for k,v in pairs(forger_bounds) do
            print(k,v)
        end
        os.pullEvent("mouse_click")
    elseif input_split[1] == "setclear" then
        config.clear_block = input_split[2] or "stone"
        print("Set clear block to "..config.clear_block)
        writeConfig()
    elseif input_split[1] == "offset" then
        offset_x = tonumber(input_split[2]) or 0
        offset_y = tonumber(input_split[3]) or 0
        offset_z = tonumber(input_split[4]) or 0
        print("Offsets set to:")
        print(offset_x, offset_y, offset_z)
    elseif input_split[1] == "draw" then
        local modified_data = {}
        
        print("Building data..")
        local write_x, write_y = term.getCursorPos()
        for block, positions in pairs(decoded_data) do
            local new_positions = {}
            for k, pos in pairs(positions) do
                local newpos = {x = pos.x + offset_x, y = pos.y + offset_y, z = pos.z + offset_z}
                if within_bounds(newpos) then
                    new_positions[#new_positions+1] = newpos
                end
            end
            modified_data[block] = new_positions
        end
        
        local block_type_count = getTableSize(modified_data)

        print("Block Types: "..block_type_count)
        print("Block Count: "..getBlockCount(modified_data))

        if input_split[2] == "true" or input_split[2] == "y" or input_split[2] == "1" then
            print("Clearing..")
            forge.forgeReality({block=config.clear_block}, {playerPassable=true, lightPassable=true, invisible=false})
        end
        
        print("Drawing scan..")
        local progress = 0
        local write_x, write_y = term.getCursorPos()
        for block,positions in pairs(modified_data) do
            term.setCursorPos(write_x, write_y)
            term.clearLine()
            term.write(string.format("%.0f%%", (progress/block_type_count)*100))
            local stat, err = pcall(function()
                local options = {
                    invisible = false,
                    playerPassable = false,
                    lightPassable = false
                }
                if block == "minecraft:air" or block == "minecraft:cave_air" or block == "minecraft:void_air" then
                    options.invisible = true
                    options.playerPassable = true
                    options.lightPassable = true
                end
                forge.forgeRealityPieces(positions, {block=block}, options)
            end)
            if not stat then if err == "Terminated" then break else print(err) end end
            progress = progress+1
        end
        print("")
    elseif input_split[1] == "clear" then
        local anchor_list = forge.detectAnchors()
        local instructions = {}
        print("Clearing chamber..")
        for k,coords in pairs(anchor_list) do
            instructions[#instructions+1] = {{coords}, {block=config.clear_block}, {invisible=false, playerPassable=true, lightPassable=true}}
        end
        local instructions_layers = {}
        for k,v in pairs(instructions) do
            if not instructions_layers[v[1][1].y] then
                instructions_layers[v[1][1].y] = {}
            end
            instructions_layers[v[1][1].y][#instructions_layers[v[1][1].y]+1] = v
        end
        local write_x, write_y = term.getCursorPos()
        for i1=1, (#instructions_layers) do
            term.setCursorPos(write_x, write_y)
            term.clearLine()
            term.write(string.format("%.0f%%", (i1/#instructions_layers)*100))
            forge.batchForgeRealityPieces(instructions_layers[(#instructions_layers-i1)+1])
        end
        print("")
    elseif input_split[1] == "fill" then
        forge.forgeReality({block=input_split[2]}, {playerPassable=true, lightPassable=true, invisible=false})
    elseif input_split[1] == "random" then
        local chance = tonumber(input_split[2])
        local anchor_list = forge.detectAnchors()

        local instructions = {}
        for k,coords in pairs(anchor_list) do
            if (chance and math.random(0,100) < chance) or not chance then
                local random_block = allowed_blocks_list[math.random(1, #allowed_blocks_list)]
                instructions[#instructions+1] = {{coords}, {block=random_block}, {invisible=false, playerPassable=true, lightPassable=true}}
            end
        end

        local instructions_layers = {}
        for k,v in pairs(instructions) do
            if not instructions_layers[v[1][1].y] then
                instructions_layers[v[1][1].y] = {}
            end
            instructions_layers[v[1][1].y][#instructions_layers[v[1][1].y]+1] = v
        end

        print("Filling random blocks..")

        local write_x, write_y = term.getCursorPos()
        for k,v in ipairs(instructions_layers) do
            term.setCursorPos(write_x, write_y)
            term.clearLine()
            term.write(string.format("%.0f%%", (k/#instructions_layers)*100))
            forge.batchForgeRealityPieces(v)
        end
        print("")
    end 
    print()
    print("Command executed.")
    print("Press any key to exit")
    os.pullEvent("key")
    sleep(0.1)
end
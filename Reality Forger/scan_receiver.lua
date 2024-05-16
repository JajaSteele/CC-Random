local modems = {peripheral.find("modem")}
local forge = peripheral.find("reality_forger")
local completion = require("cc.completion")
local registry = peripheral.find("informative_registry")
local storage = peripheral.find("nbtStorage")
local lua_lzw = require("lualzw")
local tinyStructure = require("tinystructure")

local perlin = require("perlin")

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

local function debugFile(name, ...)
    local debug_file = io.open(name, "w")
    debug_file:write(textutils.serialise(...))
    debug_file:close()
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

local function sanitizeInstructions(instructions)
    local new_instructions = {}
    for k,instruction in pairs(instructions) do
        local new_part = {{}, instruction[2], instruction[3]}
        for k, coords in pairs(instruction[1]) do
            if coords.x ~= 0 or coords.z ~= 0 or coords.y > 0 then
                new_part[1][#new_part[1]+1] = coords
            end
        end
        if #new_part[1] > 0 then
            new_instructions[#new_instructions+1] = new_part
        end
    end

    return new_instructions
end

local function sanitizePositions(positions)
    local new_positions = {}
    for k,coords in pairs(positions) do
        if coords.x ~= 0 or coords.z ~= 0 or coords.y > 0 then
            new_positions[#new_positions+1] = coords
        end
    end

    return new_positions
end

local function layerInstructions(instructions)
    local layer_list = {}

    local instructions_layers = {}
    for k,v in pairs(instructions) do
        if not instructions_layers[v[1][1].y] then
            instructions_layers[v[1][1].y] = {}
            layer_list[#layer_list+1] = v[1][1].y
        end
        instructions_layers[v[1][1].y][#instructions_layers[v[1][1].y]+1] = v
    end

    return instructions_layers, layer_list
end

local config = {
    clear_block = "stone",
    terrain_stone = "stone",
    terrain_dirt = "dirt",
    terrain_grass = "mycelium",
    terrain_deco = "red_mushroom"
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

local offset_x = -25
local offset_y = -25
local offset_z = -25

local cmd_list = {
    "receive",
    "clear <instant y/n>",
    "draw <clear y/n>",
    "offset <x> <y> <z>",
    "fill <block>",
    "random",
    "setclear <block>",
    "bounds",
    "save",
    "load",
    "perlin <divider>",
    "terrain <divider>",
    "setterrain <stone> <dirt> <grass> <decoration>"
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
    elseif input_split[1] == "setterrain" then
        config.terrain_stone = input_split[2] or "stone"
        config.terrain_dirt = input_split[3] or "dirt"
        config.terrain_grass = input_split[4] or "mycelium"
        config.terrain_deco = input_split[5] or "red_mushroom"
    elseif input_split[1] == "save" then
        print("Encoding..")
        --FIXME: Switch to using proper sorting of registry values
        local serialized_data = tinyStructure.encode(tinyStructure.convertSparsePosMatrixToDenseMatrix(decoded_data), registry.list("block"))
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
                print("Decoding.. ("..prettySize(#decompressed_data)..")")
                --FIXME: Switch to using proper sorting of registry values
                decoded_data = tinyStructure.convertDenseMatrixToSparsePosMatrix(tinyStructure.decode(decompressed_data, registry.list("block")))
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
            local positions = sanitizePositions(positions)
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
        if input_split[2] == "true" or input_split[2] == "y" or input_split[2] == "1" then
            print("Clearing..")
            forge.forgeReality({block=config.clear_block}, {playerPassable=true, lightPassable=true, invisible=false})
        else
            for k,coords in pairs(anchor_list) do
                instructions[#instructions+1] = {{coords}, {block=config.clear_block}, {invisible=false, playerPassable=true, lightPassable=true}}
            end

            instructions = sanitizeInstructions(instructions)

            local instructions_layers, layer_list = layerInstructions(instructions)
            local write_x, write_y = term.getCursorPos()
            for k,v in ipairs(layer_list) do
                term.setCursorPos(write_x, write_y)
                term.clearLine()
                term.write(string.format("%.0f%%", (k/#layer_list)*100).." - "..k)
                forge.batchForgeRealityPieces(instructions_layers[v])
            end
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

        
        instructions = sanitizeInstructions(instructions)
        local instructions_layers, layer_list = layerInstructions(instructions)

        print("Filling random blocks..")

        local write_x, write_y = term.getCursorPos()
        for k,v in ipairs(layer_list) do
            term.setCursorPos(write_x, write_y)
            term.clearLine()
            term.write(string.format("%.0f%%", (k/#layer_list)*100).." - "..k)
            forge.batchForgeRealityPieces(instructions_layers[v])
        end
        print("")
    elseif input_split[1] == "perlin" then
        local divider = tonumber(input_split[2]) or 8
        local anchor_list = forge.detectAnchors()
        
        print("Generating..")
        local instructions = {}
        for k,coords in pairs(anchor_list) do
            if perlin:noise((coords.x/divider)+0.5, (coords.y/divider)+0.5, (coords.z/divider)+0.5) > 0 then
                instructions[#instructions+1] = {{coords}, {block="stone"}, {invisible=false, playerPassable=true, lightPassable=false}}
            else
                instructions[#instructions+1] = {{coords}, {block=config.clear_block}, {invisible=false, playerPassable=true, lightPassable=true}}
            end
        end

        local instructions_layers, layer_list = layerInstructions(instructions)

        print("Drawing..")
        local write_x, write_y = term.getCursorPos()
        for k,v in ipairs(layer_list) do
            term.setCursorPos(write_x, write_y)
            term.clearLine()
            term.write(string.format("%.0f%%", (k/#layer_list)*100).." - "..k)
            forge.batchForgeRealityPieces(instructions_layers[v])
        end
        print("")
    elseif input_split[1] == "terrain" then

        local divider = tonumber(input_split[2]) or 16
        
        print("Generating..")
        local instructions = {}
        for coords_x=forger_bounds.neg_x, forger_bounds.pos_x do
            for coords_z=forger_bounds.neg_z, forger_bounds.pos_z do
                local noise = perlin:noise((coords_x/divider)+0.5, (1/divider)+0.5, (coords_z/divider)+0.5)
                local level = (noise+1)/2
                local check_level = (level*4)+4
                local shroom_noise = perlin:noise(((coords_x+32)/8)+0.5, (1/16)+0.5, ((coords_z+32)/8)+0.5)
                local shroom_chance
                if shroom_noise > 0.125 then
                    shroom_chance = ((shroom_noise+1)/2)*16
                else
                    shroom_chance = 0
                end
                for i1=1, (math.abs(forger_bounds.pos_y)+math.abs(forger_bounds.neg_y)) do
                    local elevation = i1
                    if i1 <= check_level then
                        if i1+3 > check_level then
                            if i1+1 > check_level then
                                instructions[#instructions+1] = {{{x=coords_x, y=elevation, z=coords_z}}, {block=config.terrain_grass}, {invisible=false, playerPassable=false, lightPassable=false}}
                            else
                                instructions[#instructions+1] = {{{x=coords_x, y=elevation, z=coords_z}}, {block=config.terrain_dirt}, {invisible=false, playerPassable=false, lightPassable=false}}
                            end
                        else
                            instructions[#instructions+1] = {{{x=coords_x, y=elevation, z=coords_z}}, {block=config.terrain_stone}, {invisible=false, playerPassable=false, lightPassable=false}}
                        end
                    else
                        if i1-1 <= check_level and math.random(0,100) < shroom_chance then
                            print(shroom_chance)
                            instructions[#instructions+1] = {{{x=coords_x, y=elevation, z=coords_z}}, {block=config.terrain_deco}, {invisible=false, playerPassable=true, lightPassable=true}}
                        else
                            instructions[#instructions+1] = {{{x=coords_x, y=elevation, z=coords_z}}, {block=config.clear_block}, {invisible=false, playerPassable=true, lightPassable=true}}
                        end
                    end
                end
                for i1=1, 24 do
                    if math.abs(perlin:noise((coords_x/divider)+0.5, (i1/(divider/2))+0.5, (coords_z/divider)+0.5)) < 0.25 then
                        instructions[#instructions+1] = {{{x=coords_x, y=i1-24, z=coords_z}}, {block="stone"}, {invisible=false, playerPassable=false, lightPassable=false}}
                    else
                        instructions[#instructions+1] = {{{x=coords_x, y=i1-24, z=coords_z}}, {block=config.clear_block}, {invisible=false, playerPassable=true, lightPassable=true}}
                    end
                end
            end
        end

        --local instructions = sanitizeInstructions(instructions)

        local instructions_layers, layer_list = layerInstructions(instructions)

        print("Drawing..")
        local write_x, write_y = term.getCursorPos()
        for k,v in ipairs(layer_list) do
            term.setCursorPos(write_x, write_y)
            term.clearLine()
            term.write(string.format("%.0f%%", (k/#layer_list)*100).." - "..k)
            forge.batchForgeRealityPieces(instructions_layers[v])
        end
        print("")
    end
    print()
    print("Command executed.")
    print("Press any key to exit")
    os.pullEvent("key")
    sleep(0.1)
end


if not fs.exists("json.lua") then
    print("Couldn't find json lib, installing..")
    shell.run("wget https://raw.githubusercontent.com/rxi/json.lua/refs/heads/master/json.lua")
end
local json = require("json")

local preset_io = io.open("preset.json")
if not preset_io then
    error("Couldn't open 'preset.json'")
end

local preset_data = preset_io:read("*a")
preset_io:close()

local preset = json.decode(preset_data)

local function fill(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            term.setCursorPos(x+i1-1,y+i2-1)
            term.write(char or " ")
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                term.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    term.write()
                else
                    term.write(char or " ")
                end
            end
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function write(x,y,text,bg,fg, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_posx,old_posy = term.getCursorPos()
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()

    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    term.setCursorPos(x,y)
    term.write(text)

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

print("Loaded "..#preset.." entries from preset")
print("Generating map..")

local helper_map = {
    eterna = {
        pos={},
        neg={}
    },
    quanta = {
        pos={},
        neg={}
    },
    arcana = {
        pos={},
        neg={}
    },
    clues = {
        pos={},
        neg={}
    },
    rectification={
        pos={},
        neg={}
    }
}

for block, data in pairs(preset) do
    print(block)
    for stat, value in pairs(data[1]) do
        print(stat)
        if helper_map[stat] then
            local new_data = {
                stats=data[1],
                block=block
            }
            if value > 0 then
                helper_map[stat].pos[#helper_map[stat].pos+1] = new_data
            elseif value < 0 then
                helper_map[stat].neg[#helper_map[stat].neg+1] = new_data
            end
        end
    end
end

print("Map generated!")
sleep(0.5)

term.clear()
term.setCursorPos(1,1)

print("Enter an Eterna multiplier: (1 or 2, default 2)")
print("(On older versions, Eterna is 0-50 instead of 0-100)")
local eterna_mult = (tonumber(read()) or 2)

print("Enter min Eterna: (0 < 50 < 50)")
local min_eterna = (tonumber(read()) or 50)*eterna_mult
print("Enter max Eterna: ("..(min_eterna/eterna_mult).." < 50 < 50)")
local max_eterna = (tonumber(read()) or 50)*eterna_mult

term.clear()
term.setCursorPos(1,1)

print("Enter min Quanta: (0 < 50 < 100)")
local min_quanta = tonumber(read()) or 50
print("Enter max Quanta: ("..min_quanta.." < 50 < 100)")
local max_quanta = tonumber(read()) or 50

term.clear()
term.setCursorPos(1,1)

print("Enter min Arcana: (0 < 100 < 100)")
local min_arcana = tonumber(read()) or 100
print("Enter max Arcana: ("..min_arcana.." < 100 < 100)")
local max_arcana = tonumber(read()) or 100

term.clear()
term.setCursorPos(1,1)

print("Enter min Clues: (0 < 0 < 4)")
local min_clues = tonumber(read()) or 0
print("Enter min Rectification (0 < 0 < 100)")
local min_rectification = tonumber(read()) or 0

term.clear()
term.setCursorPos(1,1)

local blocks = {}
local max_blocks = 32

local curr = {
    maxEterna = 0,
    eterna = 0,
    quanta = 15,
    arcana = 0,
    clues = 0,
    rectification = 0,
}

local last_action = ""
local last_block = ""

local fail_reason = ""
local success = false

while true do
    local new_block = ""
    term.clear()
    write(2,2, "Status: "..last_action, colors.black, colors.white)
    write(2,3, "Status: "..(last_block:match(".+:(.+)") or "None"), colors.black, colors.white)
    write(3,5, "Eterna: "..(curr.eterna/eterna_mult).." ("..(curr.maxEterna/eterna_mult).." max)", colors.black, colors.lime)
    write(3,6, "Quanta: "..curr.quanta.."%", colors.black, colors.red)
    write(3,7, "Arcana: "..curr.arcana.."%", colors.black, colors.purple)

    write(3,8, "Clues: "..curr.clues, colors.black, colors.cyan)
    write(3,9, "Rectification: "..curr.rectification.."%", colors.black, colors.yellow)

    write(3,11, "Total Blocks: "..#blocks.."/"..max_blocks, colors.black, colors.lightGray)

    term.setCursorPos(1,9)

    if curr.clues < min_clues then
        last_action = "Increasing Clues"
        local curr_diff = min_clues - curr.clues
        table.sort(helper_map.clues.pos, function (a, b)
            return (a.stats.clues or 0) < (b.stats.clues or 0)
        end)
        for k,v in ipairs(helper_map.clues.pos) do
            if v.stats.clues >= curr_diff or k == #helper_map.clues.pos then
                new_block = v.block
                break
            end
        end
    end
    if curr.rectification < min_rectification then
        last_action = "Increasing Rectification"
        local curr_diff = min_rectification - curr.rectification
        table.sort(helper_map.rectification.pos, function (a, b)
            return (a.stats.rectification or 0) < (b.stats.rectification or 0)
        end)
        for k,v in ipairs(helper_map.rectification.pos) do
            if v.stats.rectification >= curr_diff or k == #helper_map.rectification.pos then
                new_block = v.block
                break
            end
        end
    end

    if curr.maxEterna < min_eterna then
        last_action = "Increasing Eterna"
        table.sort(helper_map.eterna.pos, function (a, b)
            return a.stats.maxEterna < b.stats.maxEterna
        end)
        for k,v in ipairs(helper_map.eterna.pos) do
            if v.stats.maxEterna >= min_eterna or k == #helper_map.eterna.pos then
                new_block = v.block
                break
            end
        end
    end

    if curr.eterna < min_eterna then
        last_action = "Increasing Eterna"
        local curr_diff = min_eterna - curr.eterna
        table.sort(helper_map.eterna.pos, function (a, b)
            return a.stats.eterna < b.stats.eterna
        end)
        for k,v in ipairs(helper_map.eterna.pos) do
            if v.stats.eterna >= curr_diff or k == #helper_map.eterna.pos then
                new_block = v.block
                break
            end
        end
    end
    if curr.eterna > max_eterna then
        last_action = "Decreasing Eterna"
        local curr_diff = max_eterna - curr.eterna
        table.sort(helper_map.eterna.neg, function (a, b)
            return a.stats.eterna > b.stats.eterna
        end)
        for k,v in ipairs(helper_map.eterna.neg) do
            if v.stats.eterna <= curr_diff or k == #helper_map.eterna.neg then
                new_block = v.block
                break
            end
        end
    end

    if curr.quanta < min_quanta then
        last_action = "Increasing Quanta"
        local curr_diff = min_quanta - curr.quanta
        table.sort(helper_map.quanta.pos, function (a, b)
            return a.stats.quanta < b.stats.quanta
        end)
        for k,v in ipairs(helper_map.quanta.pos) do
            if v.stats.quanta >= curr_diff or k == #helper_map.quanta.pos then
                new_block = v.block
                break
            end
        end
    end
    if curr.quanta > max_quanta then
        last_action = "Decreasing Quanta"
        local curr_diff = max_quanta - curr.quanta
        table.sort(helper_map.quanta.neg, function (a, b)
            return a.stats.quanta > b.stats.quanta
        end)
        for k,v in ipairs(helper_map.quanta.neg) do
            if v.stats.quanta <= curr_diff or k == #helper_map.quanta.neg then
                new_block = v.block
                break
            end
        end
    end

    if curr.arcana < min_arcana then
        last_action = "Increasing Arcana"
        local curr_diff = min_arcana - curr.arcana
        table.sort(helper_map.arcana.pos, function (a, b)
            return a.stats.arcana < b.stats.arcana
        end)
        for k,v in ipairs(helper_map.arcana.pos) do
            if v.stats.arcana >= curr_diff or k == #helper_map.arcana.pos then
                new_block = v.block
                break
            end
        end
    end
    if curr.arcana > max_arcana then
        last_action = "Decreasing Arcana"
        local curr_diff = max_arcana - curr.arcana
        table.sort(helper_map.arcana.neg, function (a, b)
            return a.stats.arcana > b.stats.arcana
        end)
        for k,v in ipairs(helper_map.arcana.neg) do
            if v.stats.arcana <= curr_diff or k == #helper_map.arcana.neg then
                new_block = v.block
                break
            end
        end
    end

    local new_block_data = preset[new_block]
    if new_block_data then
        if curr.maxEterna < (new_block_data[1].maxEterna or 0) then
            curr.maxEterna = (new_block_data[1].maxEterna or 0)
        end
        curr.eterna = clamp(curr.eterna + (new_block_data[1].eterna or 0), -99999, curr.maxEterna)
        curr.quanta = clamp(curr.quanta + (new_block_data[1].quanta or 0), -99999, 100)
        curr.arcana = clamp(curr.arcana + (new_block_data[1].arcana or 0), -99999, 100)

        curr.clues = clamp(curr.clues + (new_block_data[1].clues or 0), -99999, 4)
        curr.rectification = clamp(curr.rectification + (new_block_data[1].rectification or 0), -99999, 100)

        blocks[#blocks+1] = new_block
        last_block = new_block
    end

    sleep(0.1)

    if new_block == "" then
        success = true
        break
    end
    if #blocks > 32 then
        fail_reason = "Exceeded 32 blocks"
        success = false
        break
    end
end

term.clear()
term.setCursorPos(1,1)
write(1,1, string.format("%.1f", curr.eterna/eterna_mult), colors.black, colors.lime)
write(7,1, string.format("%.1f", curr.quanta), colors.black, colors.red)
write(13,1, string.format("%.1f", curr.arcana), colors.black, colors.purple)
write(19,1, string.format("%.1f", curr.rectification), colors.black, colors.yellow)
write(25,1, string.format("%.0f", curr.clues), colors.black, colors.cyan)
write(1,2, "Blocks: "..#blocks, colors.black, colors.lightGray)

term.setCursorPos(1,3)

if success then
    local condensed = {}
    for k, block in pairs(blocks) do
        if condensed[block] then
            condensed[block] = condensed[block] + 1
        else
            condensed[block] = 1
        end
    end
    for k,v in pairs(condensed) do
        print(v.."x "..k)
    end

    print("Auto-Build? (y/n)")
    local res = read():lower()

    if res == "y" or res == "true" or res == "yes" or res == "1" then
        local library = peripheral.find("sophisticatedstorage:shulker_box")
        local placer = peripheral.find("sophisticatedstorage:barrel")

        local rs_io = peripheral.find("redstoneIntegrator")

        if library and placer and rs_io then
            print("Gathering items..")
            for block, amount in pairs(condensed) do
                for slot,item in pairs(library.list()) do
                    if item.name == block then
                        if item.count >= amount then
                            library.pushItems(peripheral.getName(placer), slot, amount)
                        else
                            error("Not enough "..block.." ("..item.count.."/"..amount..")")
                        end
                    end
                end 
            end

            print("Assembling setup..")
            rs_io.setOutput("left", true)
            sleep(0.1)
            rs_io.setOutput("left", false)
        else
            error("No shulkerbox or barrel (soph storage)  or redstone IO found! Needs both")
        end
    end
else
    error("Couldn't find a setup, reason: "..fail_reason)
end
local me = peripheral.find("meBridge")
local completion = require "cc.completion"

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

print("Select an item:")
local list = me.listItems()
local temp_list = {}
for k,v in pairs(list) do
    temp_list[v.name] = 1
end
local name_list = {}
for k,v in pairs(temp_list) do
    name_list[#name_list+1] = k
end

local selected_item = read(nil, nil, function(text) return completion.choice(text, name_list) end, "")

term.clear()
local width,height = term.getSize()
write(1,1, "Throughput per minute: ".."CALCULATING")

local function IRL_thread()
    local data = me.getItem({name=selected_item})
    local old_amount = data.amount
    local new_amount = data.amount

    local next_test = os.epoch("utc") + 30000
    while true do
        repeat
            local time = os.epoch("utc")
            fill(1,2,width,2)
            write(1,2, "Time until update: "..string.format("%.2fs",(next_test-time)/1000))
            sleep()
        until time >= next_test
        next_test = os.epoch("utc") + 30000

        data = me.getItem({name=selected_item})
        old_amount = new_amount
        new_amount = data.amount

        local delta = (new_amount-old_amount)*2
        fill(1,1,width,1)
        write(1,1, "Throughput per minute: "..delta)
    end
end

local function INGAME_thread()
    local data = me.getItem({name=selected_item})
    local old_amount = data.amount
    local new_amount = data.amount

    local next_test = os.epoch("ingame") + 30*72000
    while true do
        repeat
            local time = os.epoch("ingame")
            fill(1,5,width,5)
            write(1,5, "Time until update (IG): "..string.format("%.2fs",(next_test-time)/72000))
            sleep()
        until time >= next_test
        next_test = os.epoch("ingame") + 30*72000

        data = me.getItem({name=selected_item})
        old_amount = new_amount
        new_amount = data.amount

        local delta = (new_amount-old_amount)*2
        fill(1,4,width,4)
        write(1,4, "Throughput per minute (IG): "..delta)
    end
end

parallel.waitForAny(IRL_thread, INGAME_thread)
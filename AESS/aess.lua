local me = peripheral.find("meBridge")
local player_detector = peripheral.find("playerDetector")

local DEBUG = false

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

local config = {}

local function loadConfig()
    if fs.exists(".aess_config.txt") then
        local file = io.open(".aess_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open(".aess_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

local config = {}

local function loadConfig()
    if fs.exists(".aess_points.txt") then
        local file = io.open(".aess_points.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open(".aess_points.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

local width, height = term.getSize()

local diffs = {
    item = {},
    fluid = {},
    gas = {}
}

local old_content = {
    item = nil,
    fluid = nil,
    gas = nil
}
local new_content = {
    item = nil,
    fluid = nil,
    gas = nil
}

local function compareContentItems(old,new)
    local searcheable_old = {}
    for k,item in pairs(old) do
        local existing_entry = searcheable_old[item.fingerprint]
        if existing_entry and item.name == existing_entry.name then
            searcheable_old[item.fingerprint].amount = searcheable_old[item.fingerprint].amount + item.amount
        else
            searcheable_old[item.fingerprint] = item
        end
    end

    local searcheable_new = {}
    for k,item in pairs(new) do
        local existing_entry = searcheable_new[item.fingerprint]
        if existing_entry and item.name == existing_entry.name then
            searcheable_new[item.fingerprint].amount = searcheable_new[item.fingerprint].amount + item.amount
        else
            searcheable_new[item.fingerprint] = item
        end
    end

    for k,item in pairs(old) do
        local new_item = searcheable_new[item.fingerprint]
        if new_item then
            if new_item.amount < item.amount then
                diffs.item[#diffs.item+1] = {
                    type = "modified",
                    amount = new_item.amount - item.amount,
                    name = item.name
                }
                if DEBUG then
                    print("More "..item.name.." in old")
                    os.pullEvent("key")
                end
            elseif new_item.amount > item.amount then
                diffs.item[#diffs.item+1] = {
                    type = "modified",
                    amount = new_item.amount - item.amount,
                    name = item.name
                }
                if DEBUG then
                    print("More "..item.name.." in new")
                    os.pullEvent("key")
                end
            end
        else
            diffs.item[#diffs.item+1] = {
                type = "removed",
                amount = -item.amount,
                name = item.name
            }
            if DEBUG then
                print("Couldn't find "..item.name.." in new")
                os.pullEvent("key")
            end
        end
    end

    for k,item in pairs(new) do
        local old_item = searcheable_old[item.fingerprint]
        if not old_item then
            diffs.item[#diffs.item+1] = {
                type = "added",
                amount = item.amount,
                name = item.name
            }
            if DEBUG then
                print("Couldn't find "..item.name.." in old")
                os.pullEvent("key")
            end
        end
    end
end

local function storageMonitorThread()
    while true do
        diffs.item = {}
        local new_list = me.listItems()
        old_content.item = new_content.item or new_list
        new_content.item = new_list
        compareContentItems(old_content.item, new_content.item)
        for k,v in pairs(diffs.item) do
            print(v.type.." | "..v.amount.." "..v.name)
        end
        for i1=1, 5 do
            term.setCursorPos(1,height)
            term.clearLine()
            term.write("Refreshing in "..(5-i1))
            sleep(0.75)
        end
        term.setCursorPos(1,height)
        print("")
        --os.pullEvent("mouse_click")
    end
end

parallel.waitForAll(storageMonitorThread)
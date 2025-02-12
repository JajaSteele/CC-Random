local me = peripheral.find("meBridge")
local player_detector = peripheral.find("playerDetector")

local DEBUG = false

local function deepcopy(o, seen)
    seen = seen or {}
    if o == nil then return nil end
    if seen[o] then return seen[o] end
  
    local no
    if type(o) == 'table' then
      no = {}
      seen[o] = no
  
      for k, v in next, o, nil do
        no[deepcopy(k, seen)] = deepcopy(v, seen)
      end
      setmetatable(no, deepcopy(getmetatable(o), seen))
    else -- number, string, boolean, etc
      no = o
    end
    return no
  end
  

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
local args = {...}

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

if args[1] == "config" or not fs.exists("/.aess_config.txt") then
    term.clear()
    term.setCursorPos(1,1)

    print("Welcome to the config wizard!")
    print("")
    print("Detection Range:")

    config.detection_range = tonumber(read()) or 100
    
    term.clear()
    term.setCursorPos(1,1)

    writeConfig()
end
loadConfig()

local width, height = term.getSize()

local buffer_hour = {}
local buffer_minute = {}

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

local player_buffer = {}

local function storageMonitorThread()
    while true do
        diffs.item = {}
        local new_list = me.listItems()
        old_content.item = new_content.item or new_list
        new_content.item = new_list
        compareContentItems(old_content.item, new_content.item)

        local last_diff = deepcopy(diffs)
        local last_players = deepcopy(player_buffer)

        buffer_minute[#buffer_minute+1] = {
            diff=last_diff,
            nearby_players=last_players
        }

        player_buffer = {}

        for i1=1, 5 do
            term.setCursorPos(1,height-1)
            term.clearLine()
            term.write("Refreshing in "..(5-i1))
            term.setCursorPos(1,height)
            term.clearLine()
            term.write("Buffer: "..#buffer_minute.."/"..(60/5))
            sleep(1)
        end
        term.setCursorPos(1,height)
        print("")
        --os.pullEvent("mouse_click")
    end
end

local function clockThread()
    local time = os.epoch("utc")/1000
    local next_min = time + (60-time%60)
    while true do
        local curr_time = os.epoch("utc")/1000
        if curr_time >= next_min then
            os.queueEvent("clock_min")
            next_min = curr_time + (60-curr_time%60)
        end
        sleep()
    end
end

local function storageMergerThread()
    while true do
        local data = {os.pullEvent()}
        if data[1] == "clock_min" then
            local merged_diffs = {
                fluid={},
                item={},
                gas={}
            }

            for k, chunk in ipairs(buffer_minute) do
                for diff_type, diff_data in pairs(chunk.diff) do
                    if not merged_diffs[diff_type][]
                end
            end
        end
    end
end

local function detectorThread()
    while true do
        local players = player_detector.getPlayersInRange(config.detection_range)
        for k,v in pairs(players) do
            player_buffer[v] = true
        end
        sleep(0.5)
    end
end

parallel.waitForAll(storageMonitorThread, detectorThread, storageMergerThread, clockThread)
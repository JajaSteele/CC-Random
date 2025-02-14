local me = peripheral.find("meBridge")
local player_detector = peripheral.find("playerDetector")
local lzw = require("lualzw")

if not fs.exists("/json.lua") then
    shell.run("wget https://github.com/rxi/json.lua/raw/refs/heads/master/json.lua /json.lua")
end

local json = require("json")

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

local function prettyETA(time)
    local seconds = time%60
    local minutes = math.floor(time/60)%60
    local hours = math.floor(time/3600)%24
    local days = math.floor(time/86400)%30
    local months = math.floor(time/2635200)%12
    local years = math.floor(time/31622400)

    local output = ""

    if years >= 1 then
        output = string.format("%dy %dM %dd %dh %dm %ds", years, months, days, hours, minutes, seconds)
    elseif months >= 1 then
        output = string.format("%dM %dd %dh %dm %ds", months, days, hours, minutes, seconds)
    elseif days >= 1 then
        output = string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)
    elseif hours >= 1 then
        output = string.format("%dh %dm %ds", hours, minutes, seconds)
    elseif minutes >=1 then
        output = string.format("%dm %ds", minutes, seconds)
    else
        output = string.format("%ds", seconds)
    end

    return output
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
    print("\n\nWebsocket URL:")
    config.url = read()

    term.clear()
    term.setCursorPos(1,1)
    print("\n\nKey:")
    config.key_value = read()

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
                if not diffs.item[item.name] then
                    diffs.item[item.name] = new_item.amount - item.amount
                else
                    diffs.item[item.name] = diffs.item[item.name] + (new_item.amount - item.amount)
                end
                if DEBUG then
                    print("More "..item.name.." in old")
                    os.pullEvent("key")
                end
            elseif new_item.amount > item.amount then
                if not diffs.item[item.name] then
                    diffs.item[item.name] = new_item.amount - item.amount
                else
                    diffs.item[item.name] = diffs.item[item.name] + (new_item.amount - item.amount)
                end
                if DEBUG then
                    print("More "..item.name.." in new")
                    os.pullEvent("key")
                end
            end
        else
            if not diffs.item[item.name] then
                diffs.item[item.name] = -item.amount
            else
                diffs.item[item.name] = diffs.item[item.name] - item.amount
            end
            if DEBUG then
                print("Couldn't find "..item.name.." in new")
                os.pullEvent("key")
            end
        end
    end

    for k,item in pairs(new) do
        local old_item = searcheable_old[item.fingerprint]
        if not old_item then
            if not diffs.item[item.name] then
                diffs.item[item.name] = item.amount
            else
                diffs.item[item.name] = diffs.item[item.name] + item.amount
            end
            if DEBUG then
                print("Couldn't find "..item.name.." in old")
                os.pullEvent("key")
            end
        end
    end
end

local player_buffer = {}
local websocket
local success_connected = false

local function compareStorage()
    diffs.item = {}
    local new_list = me.listItems()
    old_content.item = new_content.item or new_list
    new_content.item = new_list
    compareContentItems(old_content.item, new_content.item)

    local last_diff = deepcopy(diffs)

    buffer_minute[#buffer_minute+1] = {
        diff=last_diff
    }
end

local refresh_timer = 5
local last_size = 0
local total_size = 0
local total_size_compress = 0
local time_saved = 0

local function storageMonitorThread()
    while true do
        term.clear()
        write(1,2, "Refreshing in: "..refresh_timer.."s")
        write(1,4, "Refresh size difference: "..last_size.."b")
        write(1,5, "Total raw size: "..total_size.."b")
        write(1,6, "Total compressed size: "..total_size_compress.."b")
        write(1,8, "History saved: ~"..prettyETA(time_saved*60))
        sleep(1)
        if refresh_timer > 0 then
            refresh_timer = refresh_timer-1
        else
            compareStorage()
            refresh_timer = 5
        end
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

local function writeData(new_data, filepath)
    local file_in = io.open(filepath, "r")
    local data
    
    local old_size
    if file_in then
        local data_string = file_in:read("*a")
        local decompressed_string = lzw.decompress(data_string)
        old_size = #data_string
        data = textutils.unserialise(decompressed_string)
        file_in:close()
    else
        old_size = 0
        data = {}
    end

    data[#data+1] = new_data
    if #data > 60*24 then
        table.remove(data, 1)
    end

    time_saved = #data

    local new_data = textutils.serialise(data, {compact=true})
    total_size = #new_data
    local compressed_data = lzw.compress(new_data)
    local new_size = #compressed_data

    total_size_compress = new_size
    last_size = new_size-old_size

    local file_out = io.open(filepath, "w")
    file_out:write(compressed_data)
    file_out:close()
end

local function getData(filepath)
    local file_in = io.open(filepath, "r")
    local data
    if file_in then
        data = textutils.unserialise(lzw.decompress(file_in:read("*a")))
        file_in:close()
    else
        data = {}
    end

    local merged_diffs = {
        fluid={},
        item={},
        gas={}
    }

    for k, chunk in ipairs(buffer_minute) do
        for diff_type, diff_data in pairs(chunk.diff) do
            for item, count in pairs(diff_data) do
                if not merged_diffs[diff_type][item] then
                    merged_diffs[diff_type][item] = count
                else
                    merged_diffs[diff_type][item] = merged_diffs[diff_type][item] + count
                end
            end
        end
    end

    local new_data = {
        diffs = merged_diffs,
        nearby_players = player_buffer,
        time = os.epoch("utc") - 60*1000
    }

    data[#data+1] = new_data

    return data
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

            compareStorage()

            for k, chunk in ipairs(buffer_minute) do
                for diff_type, diff_data in pairs(chunk.diff) do
                    for item, count in pairs(diff_data) do
                        if not merged_diffs[diff_type][item] then
                            merged_diffs[diff_type][item] = count
                        else
                            merged_diffs[diff_type][item] = merged_diffs[diff_type][item] + count
                        end
                    end
                end
            end
            buffer_minute = {}

            local data = {
                diffs = merged_diffs,
                nearby_players = player_buffer,
                time = os.epoch("utc") - 60*1000
            }
            
            writeData(data, ".aess_data.txt")
            player_buffer = {}
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

local function websocketWatcher()
    while true do
        local event = {os.pullEvent()}
        if event[1] == "websocket_closed" or event[1] == "websocket_failure" then
            print("Attempting reconnect!")
            success_connected = false 
            os.queueEvent("websocket_reconnect")
        end
    end
end

local function websocketController()
    while true do
        os.pullEvent("websocket_reconnect")
        repeat
            if websocket then
                websocket.close()
            end
            websocket = http.websocket({url=(config.url).."/?key="..(config.key_value), timeout=5})
            if websocket then 
                success_connected = true 
                print("Successfully connected.") 
            else 
                success_connected = false 
                if websocket then
                    websocket.close()
                end
                print("Unable to connect.") 
            end
        until success_connected
    end
end

local function websocketReader()
    while true do
        local stat, err = pcall(function()
            if not success_connected then
                sleep(0.1)
            else
                local data = json.decode(websocket.receive())
                if data then
                    if data.type == "request_history" then
                        local history_data = getData(".aess_data.txt")
                        for k,v in ipairs(history_data) do
                            local payload_data = {
                                type="response_history",
                                data=v,
                            }
                            local payload_json = json.encode(payload_data)

                            
                            if payload_json then
                                websocket.send(payload_json)
                            end
                        end
                        local payload_data = {
                            type="response_history_finish",
                        }
                        local payload_json = json.encode(payload_data)
                        if payload_json then
                            websocket.send(payload_json)
                        end
                    end
                end
            end
        end)
        if not stat then print(err) end
        sleep(0.1)
    end
end

local function heartbeatThread()
    local data = json.encode({type="mc_heartbeat", content=""})
    while true do
        local stat, err = pcall(function()
            if not success_connected then
                sleep(0.1)
            else
                websocket.send(data)
                local data = websocket.receive(0.25)
                if not data then
                    print("Heartbeat failed, reconnecting")
                    os.queueEvent("websocket_reconnect")
                end
                sleep(15)
            end
        end)
        if not stat then print(err) sleep(0.1) end
    end
end

os.queueEvent("websocket_reconnect")

local stat, err = pcall(function (...)
    parallel.waitForAll(storageMonitorThread, detectorThread, storageMergerThread, clockThread, websocketWatcher, websocketController, websocketReader, heartbeatThread)
end)
if not stat then
    if err == "Terminated" then
        print("Terminated program.")
    else
        error(err)
    end
    if websocket then
        websocket.close()
    end
end
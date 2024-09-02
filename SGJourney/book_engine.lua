local function fill(x,y,x1,y1,bg,fg,char)
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
end

local function write(x,y,text,bg,fg)
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
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
    modem.open(2707)
end

local function getNearestGate_NoCache()
    modem.transmit(2707, 2707, {protocol="jjs_sg_dialer_ping", message="request_ping"})

    local temp_gates = {}

    local failed_attempts = 0
    while true do
        local timeout_timer = os.startTimer(0.075)
        local event = {os.pullEvent()}

        if event[1] == "modem_message" then
            if type(event[5]) == "table" and event[5].protocol == "jjs_sg_dialer_ping" and event[5].message == "response_ping" then
                failed_attempts = 0
                os.cancelTimer(timeout_timer)
                if event[6] and event[6] < 150 then  
                    temp_gates[#temp_gates+1] = {
                        id = event[5].id,
                        distance = event[6] or math.huge,
                        label = event[5].label
                    }
                end
            end
        elseif event[1] == "timer" then
            if event[2] == timeout_timer then
                failed_attempts = failed_attempts+1
            else
                os.cancelTimer(timeout_timer)
            end
        end

        if failed_attempts > 4 then
            break
        end
    end

    table.sort(temp_gates, function(a,b) return (a.distance < b.distance) end)

    if temp_gates[1] then
        return temp_gates[1]
    end
end

local args = {...}
local offline_mode = false

term.clear()
term.setCursorPos(1,1)

if args[1] == "y" or args[1] == "true" then
    print("Offline Mode: TRUE")
    offline_mode = true
end

local list_of_books = {}
local merged_books = {}

if not offline_mode then
    print("Searching address books")

    list_of_books = {rednet.lookup("jjs_sg_addressbook")}

    print("Found "..#list_of_books.." address books")

    sleep(0.5)

    merged_books = {}

    print("Fetching content")
    for k,book_id in pairs(list_of_books) do
        rednet.send(book_id, "", "jjs_sg_sync_request")
        local attempts = 0
        local id, msg, protocol
        repeat
            id, msg, protocol = rednet.receive("jjs_sg_sync_data", 0.075)
            attempts = attempts+1
        until id == book_id or attempts >= 5
        if msg then
            for k,data in pairs(msg) do
                merged_books[#merged_books+1] = data
            end
            term.setTextColor(colors.lime)
            print(book_id..": Success")
            sleep(0.1)
        else
            term.setTextColor(colors.red)
            print(book_id..": Fail")
            sleep(0.8)
        end
    end
    term.setTextColor(colors.white)

    print("Raw count: "..#merged_books)

    sleep(0.5)
end

local grouped_loaded_count = 0
local grouped_address = {}

if fs.exists("/.book_engine_cache.txt") then
    local cache_import = io.open("/.book_engine_cache.txt", "r")
    grouped_address = textutils.unserialize(cache_import:read("*a")) or {}
    for k,v in pairs(grouped_address) do
        grouped_loaded_count = grouped_loaded_count+1
    end
    cache_import:close()
    print("Loaded "..grouped_loaded_count.." cached entries")
end

local function existsInTable(list, string)
    for k,v in pairs(list) do
        if type(v) == "string" then
            if v == string then
                return true
            end
        end
    end
end

local grouped_count = 0

local new_addresses = 0
local new_names = 0

for k, data in pairs(merged_books) do
    if not grouped_address[table.concat(data.address, "-")] then
        grouped_address[table.concat(data.address, "-")] = {data.name}
        new_addresses = new_addresses+1
        new_names = new_names+1
    else
        if not existsInTable(grouped_address[table.concat(data.address, "-")], data.name) then
            grouped_address[table.concat(data.address, "-")][#grouped_address[table.concat(data.address, "-")]+1] = data.name
            new_names = new_names + 1
        end
    end
end

for k,v in pairs(grouped_address) do
    grouped_count = grouped_count+1
end

local w,h = term.getSize()

local address_removed = 0
local name_removed = 0

local address_remove = {}
for address,v in pairs(grouped_address) do
    local name_remove = {}
    if address == "" then
        address_remove[#address_remove+1] = address
        address_removed = address_removed+1
    else
        if #v <= 0 then
            address_remove[#address_remove+1] = address
        end
        for id, name in pairs(v) do
            if name == "" then
                name_remove[#name_remove+1] = id
                name_removed = name_removed + 1
            end
        end
    end

    local new_name_list = {}
    for id,name in pairs(v) do
        local add = true
        for k, to_remove in pairs(name_remove) do
            if id == to_remove then
                add = false
            end
        end
        if add then
            new_name_list[#new_name_list+1] = name
        end
    end

    grouped_address[address] = new_name_list
end

for k,v in pairs(address_remove) do
    grouped_address[v] = nil
end

print("")
print("Result:")
if not offline_mode then
    print(new_addresses.." new address")
    print(new_names.." new name")
end
print(address_removed.." address removed")
print(name_removed.." name removed")

print("")
print("Grouped Count: "..grouped_count.."\n  "..grouped_loaded_count.." Loaded\n  "..(grouped_count-grouped_loaded_count).." Fetched")
local book_engine_cache = io.open("/.book_engine_cache.txt", "w")
book_engine_cache:write(textutils.serialize(grouped_address, {compact=false}))
book_engine_cache:close()
print("Cache Saved!")
print("Press any key to continue")
os.pullEvent("key")

sleep(0.1)

local filtered_address = {}

local scroll = 0

local close_button_status = false
local close_button_target = ""

local close_button_y = 3
local close_button_func = function()
    local nearest = getNearestGate_NoCache()
    if nearest then
        close_button_status = true
        close_button_target = nearest.label
        os.queueEvent("redraw_list")
        rednet.send(nearest.id, "", "jjs_sg_disconnect")
    end
    sleep(1)
    close_button_status = false
    os.queueEvent("redraw_list")
end

local close_button_info = {
    func=close_button_func,
    data={
        type="lclick_buttons"
    }
}

local list_start = 5
local list_end = h-2

local name_list_start = 10
local name_list_end = 10+5

local disable_search_threads = false

local search_match = ""

local function searchThread()
    while true do
        filtered_address = {}
        for address, names in pairs(grouped_address) do
            for k,name in pairs(names) do
                if name:lower():match(search_match) then
                    local raw_address = {}
                    for k,v in ipairs(split(address, "-")) do
                        if tonumber(v) then
                            raw_address[#raw_address+1] = tonumber(v)
                        end
                    end
                    filtered_address[#filtered_address+1] = {address=address, raw_address=raw_address, matched_name = name, all_names = names, is_dialed = false}
                    break
                end
            end
        end
        scroll = 0
        os.queueEvent("redraw_list")
        term.setCursorPos(1, h)
        term.setCursorBlink(true)
        search_match = read():lower()
    end
end

local click_map = {}

for x=1, w do
    click_map[x] = {}
    for y=list_start, list_end do
        click_map[x][y] = false
    end
end

local function drawThread()
    for x=1, w do
        click_map[x][close_button_y] = close_button_info
    end
    while true do
        local line_count = list_start-1
        local entry_count = 1
        term.clear()
        write(1,1, "Total: "..grouped_count.." - Search: "..#filtered_address, colors.black, colors.yellow)
        if close_button_status then
            write(1,3, "Closing "..close_button_target, colors.black, colors.red)
        else
            write(1,3, "Close Nearest Gate", colors.black, colors.orange)
        end
        write(1,h-1, "Enter Search Request:", colors.black, colors.yellow)

        for i1=1, #filtered_address do
            local entry = filtered_address[entry_count+scroll]
            if entry then
                if entry.is_dialed then
                    write(1, 1+line_count, entry.matched_name, colors.black, colors.lightBlue)
                    write(1, 2+line_count, entry.address, colors.black, colors.blue)
                else
                    write(1, 1+line_count, entry.matched_name, colors.black, colors.white)
                    write(1, 2+line_count, entry.address, colors.black, colors.lightGray)
                end

                local dial_func = function()
                    local nearest_gate = getNearestGate_NoCache()
                    local address = entry.raw_address
                    address[#address+1] = 0

                    local address_data = table.concat(address, "-")
                    if nearest_gate then
                        entry.is_dialed = true
                        os.queueEvent("redraw_list")
                        rednet.send(nearest_gate.id, address_data, "jjs_sg_startdial")
                    end
                    sleep(0.5)
                    entry.is_dialed = false
                    os.queueEvent("redraw_list")
                end
                
                local info_table = {
                    func=dial_func,
                    data = {
                        raw_address=entry.raw_address,
                        address=entry.address,
                        name=entry.matched_name,
                        all_names = entry.all_names,
                        type="address"
                    }
                }

                for x=1, w do
                    for y=1+line_count, 2+line_count do
                        click_map[x][y] = info_table
                    end
                end

                line_count = line_count+2
                if 2+line_count > list_end then
                    break
                end
                entry_count = entry_count+1
            end
        end
        os.pullEvent("redraw_list")
    end
end

local function scrollThread()
    while true do
        local event, dir, x, y = os.pullEvent("mouse_scroll")
        if not disable_search_threads then
            scroll = clamp(scroll+dir, 0, #filtered_address)
            os.queueEvent("redraw_list")
        end
    end
end

local function clickThread()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        local click_info = {}
        local data
        if click_map[x][y] then
            click_info = click_map[x][y]
            data = click_info.data
        end

        if not disable_search_threads then
            if data then
                if button == 1 then
                    if data.type == "address" then
                        disable_search_threads = true
                        local names = data.all_names
                        term.setCursorBlink(false)
                        local name_scroll = 0
                        term.clear()
                        write(1,1, "Info Viewer", colors.black, colors.yellow)

                        write(1,3, "Matching Name:", colors.black, colors.lightGray)
                        write(1,4, data.name, colors.black, colors.white)

                        write(1,6, "Address:", colors.black, colors.lightGray)
                        write(1,7, table.concat(data.raw_address, " "), colors.black, colors.white)

                        write(1,9, "Other Names: ("..#names..")", colors.black, colors.lightGray)

                        while true do
                            local count = 1
                            local line_offset = 0
                            for i1=1, #names do
                                fill(1, name_list_start+line_offset, w, name_list_start+line_offset, colors.black, colors.white, " ")
                                local name = names[count+name_scroll]
                                if name then
                                    write(1, name_list_start+line_offset, name, colors.black, colors.yellow)
                                    count = count+1
                                    line_offset = line_offset+1
                                end
                            end
                            local event = {os.pullEvent()}
                            if event[1] == "mouse_click" and event[2] == 2 then
                                break
                            elseif event[1] == "mouse_scroll" then
                                name_scroll = clamp(name_scroll+event[2], 0, #names)
                            end
                        end
                        term.setCursorBlink(true)
                        disable_search_threads = false
                    elseif data.type == "lclick_buttons" then
                        click_info.func()
                    end
                elseif button == 2 or button == 3 then
                    if data.type == "address" then
                        click_info.func()
                    end
                end
            end
            os.queueEvent("redraw_list")
        end
    end
end

local stat, err = pcall(function()
    parallel.waitForAny(drawThread, searchThread, scrollThread, clickThread)
end)

if not stat then
    if err == "Terminated" then
        term.clear()
        term.setCursorPos(1,1)
        term.setCursorBlink(true)
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
        print("Book Engine terminated!")
    else
        error(err)
    end
end

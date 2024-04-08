local scan_count = 0

local scan
local scan_pos

local pos

local ply

local filter

local filter_preset = "default"

local exit = false

if fs.exists("GSX/preset.txt") then
    local file = io.open("GSX/preset.txt", "r")
    filter_preset = file:read("*a")
    file:close()
end

local function savePreset()
    local file = io.open("GSX/preset.txt", "w")
    file:write(filter_preset)
    file:close()
end

local completion = require("cc.completion")

local player_list = {}

local player_username = ""

if fs.exists("GSX/username.txt") then
    local file = io.open("GSX/username.txt", "r")
    player_username = file:read("*a")
    file:close()
end

local function getColorName(color)
    for k,v in pairs(colors) do
        if v == color then
            return k
        end
    end
end

local color_table = {
    colors.red,
    colors.orange,
    colors.brown,
    colors.yellow,
    colors.lime,
    colors.green,
    colors.cyan,
    colors.lightBlue,
    colors.blue,
    colors.purple,
    colors.magenta,
    colors.pink,
    colors.white,
    colors.lightGray,
    colors.gray
}

local function saveFilter()
    local filter_file = io.open("/GSX/filter/"..filter_preset..".txt", "w")
    filter_file:write(textutils.serialise(filter))
    filter_file:close()
end

local function loadFilter()
    local filter_file = io.open("/GSX/filter/"..filter_preset..".txt", "r")
    filter = textutils.unserialise(filter_file:read("*a"))
    filter_file:close()
end

if fs.exists("/GSX/filter/"..filter_preset..".txt") then
    local filter_file = io.open("/GSX/filter/"..filter_preset..".txt", "r")
    filter = textutils.unserialise(filter_file:read("*a"))
    filter_file:close()
else
    filter = {
        {id="minecraft:damaged_anvil",color=colors.lightGray,name="Damaged Anvil"}
    }
    saveFilter()
end

local w,h = term.getSize()

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

local function rect(x,y,x1,y1,bg,fg,char)
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

local function clamp(x,min,max) 
    if x > max then 
        return max 
    elseif x < min then 
        return min 
    else 
        return x 
    end 
end

local function outside_range(x,min,max) 
    if x > max then 
        return "greater"
    elseif x < min then 
        return "lesser"
    else 
        return "inside"
    end 
end

local function inside_range(x,min,max,equal) 
    if equal then
        if x >= max then 
            return false
        elseif x <= min then 
            return false
        else 
            return true
        end 
    else
        if x > max then 
            return false
        elseif x < min then 
            return false
        else 
            return true
        end 
    end
end

local function isPresent(comp_type)
    return (peripheral.wrap("back") and peripheral.getType(peripheral.wrap("back")) == comp_type)
end

local function check(t,l)
    local res = false
    for k,v in pairs(l) do
        if t == v.id then
            return v
        end
    end
end

local function deltaAngle(curr,targ)
    return (180 - math.abs((targ - curr) - 180))
end

local function ptp(x_start,y_start,x_end,y_end)
    return math.atan2((x_end - x_start), (y_end - y_start)) * -180 / math.pi
end

local cursors_table = { --Order: x > y
    inside={
        inside="X", --X
        greater=string.char(0x1F), --Arrow DOWN
        lesser=string.char(0x1E), --Arrow UP
    },
    greater={
        inside=string.char(0x10), --Arrow RIGHT
        greater=string.char(0x04), --Arrow MULTI
        lesser=string.char(0x04), --Arrow MULTI
    },
    lesser={
        inside=string.char(0x11), --Arrow LEFT
        greater=string.char(0x04), --Arrow MULTI
        lesser=string.char(0x04), --Arrow MULTI
    }
}

local function drawScanCursor(pos_x, pos_y, color)
    local curs_pos_x = clamp(pos_x, 1, w)
    local curs_pos_y = clamp(pos_y, 1, h)

    local range_x = outside_range(pos_x, 1, w)
    local range_y = outside_range(pos_y, 1, h)
    local char = cursors_table[range_x][range_y]

    local old_fg = term.getTextColor()
    term.setTextColor(color or colors.white)
    term.setCursorPos(curs_pos_x, curs_pos_y)
    term.write(char)
    term.setTextColor(old_fg)
end

local function coreThread()
    while true do
        while not isPresent("geoScanner") do
            pocket.equipBack()
        end
        local geo = peripheral.find("geoScanner")

        scan = geo.scan(8)
        scan_count = scan_count+1

        while not isPresent("playerDetector") do
            pocket.equipBack()
        end
        ply = peripheral.find("playerDetector")
        scan_pos = ply.getPlayerPos(player_username)
        player_list = ply.getOnlinePlayers()
        sleep(2.25)
    end
end

local function drawPosThread()
    while true do
        local stat, err = pcall(function()
            if isPresent("playerDetector") then
                local ply_temp = peripheral.find("playerDetector")
                if ply_temp and ply_temp.getPlayerPos then
                    pos = ply_temp.getPlayerPos(player_username)
                end
            end
            term.clear()
            local dist_box_x1 = math.floor(w/2)-2
            local dist_box_y1 = math.floor(h/2)-2
            local dist_box_x2 = math.floor(w/2)+2
            local dist_box_y2 = math.floor(h/2)+2

            local cross_distances = {}

            fill(dist_box_x1, dist_box_y1, dist_box_x2, dist_box_y2, colors.black, colors.gray, "\x7F")
            if pos and scan_pos then
                for k,v in pairs(scan or {}) do
                    local check_res = check(v.name, filter)
                    if check_res and pos then
                        local rot_hori = ptp(pos.x, pos.z, scan_pos.x+v.x, scan_pos.z+v.z)%360
                        local dist = math.abs(v.x)+math.abs(v.z)
                        local rot_vert = ptp(pos.y+pos.eyeHeight, 0, scan_pos.y, dist)%360

                        local cursor_pos_x = (w/2)-((deltaAngle(rot_hori, pos.yaw%360)/90)*w)
                        local cursor_pos_y = (h/2)-((deltaAngle(rot_vert, pos.pitch)/90)*h)

                        if inside_range(cursor_pos_x, dist_box_x1-0.75, dist_box_x2+0.75, true) and inside_range(cursor_pos_y, dist_box_y1-0.75, dist_box_y2+0.75, true) then
                            cross_distances[#cross_distances+1] = {
                                dist = dist,
                                offset = math.abs((deltaAngle(rot_hori, pos.yaw%360)/90)*w)+math.abs((deltaAngle(rot_vert, pos.pitch)/90)*h),
                                type = v.name,
                                full_dist = dist+(math.abs(pos.y-(scan_pos.y+v.y)))
                            }
                        end

                        drawScanCursor(cursor_pos_x, cursor_pos_y, check_res.color)
                    end
                end
            end

            table.sort(cross_distances, function(a,b)
                return a.offset < b.offset
            end)

            write(1, 1, "Dist: "..((cross_distances[1] or {dist="N/A"}).full_dist or "N/A"), colors.black, colors.lightBlue)
            write(1, 2, "Type: "..((cross_distances[1] or {type="N/A"}).type or "N/A"), colors.black, colors.orange)

            sleep(0.125)
        end)
    end
end

local buttons = {
    filterEditor=function()
        local filter_scroll = 0
        while true do
            term.clear()
            term.setCursorPos(1,1)
            fill(1, 1, w, 1, colors.gray, nil, " ")
            write(1, 1, string.char(0x07).." Filter Editor", colors.gray, colors.orange)
            write(w, 1, "X", colors.gray, colors.red)
            write(w-1, 1, "|", colors.gray, colors.lightGray)
            write(w-2, 1, "?", colors.gray, colors.yellow)

            write(1, 2, "Preset: ", colors.black, colors.yellow)
            write(10, 2, filter_preset, colors.black, colors.orange)

            local entries = {}

            local count = 1
            for i1=1, h-3 do
                if not filter then break end

                local selected = filter[i1+filter_scroll]
                if not selected then break end
                local y_pos = 2+count
                write(1, y_pos, "\xB7", colors.black, selected.color)
                write(3, y_pos, selected.name, colors.black, colors.white)
                entries[y_pos] = i1+filter_scroll
                count = count+1
                if y_pos == h then
                    break
                end
            end

            local scrollbar_pos = 3+((h-4)*(filter_scroll/(#(filter or {})-(h-3))))

            fill(w, 3, w, h-1, colors.black, colors.gray, "\x7C")
            write(w, scrollbar_pos, "\x12", colors.black, colors.lightBlue)

            write(1, h, "Entries: "..#filter, colors.black, colors.yellow)

            local scroll_text = tostring(filter_scroll)

            write(w-#scroll_text, h, scroll_text, colors.black, colors.blue)

            local event = {os.pullEvent()}
            if event[1] == "mouse_scroll" then
                if inside_range(event[4], 3, h) then
                    filter_scroll = clamp(filter_scroll+(event[2]*1), 0, clamp(#(filter or {})-(h-3), 0, #filter))
                end
            elseif event[1] == "mouse_click" then
                if event[4] == 1 then
                    if event[3] == w then
                        saveFilter()
                        break
                    elseif event[3] == w-2 then
                        term.clear()
                        fill(1, 1, w, 1, colors.gray, nil, " ")
                        fill(1, h, w, h, colors.gray, nil, " ")

                        write(1, 1, string.char(0x07).." Controls", colors.gray, colors.yellow)
                        write(w, 1, "X", colors.gray, colors.red)

                        write(1, 3, "Left-Click", colors.black, colors.yellow)
                        write(1, 4, "Edit filter or", colors.black, colors.orange)
                        write(1, 5, "Switch preset", colors.black, colors.orange)

                        write(1, 7, "Right-Click", colors.black, colors.yellow)
                        write(1, 8, "Delete filter or", colors.black, colors.orange)
                        write(1, 9, "Delete preset", colors.black, colors.orange)

                        write(1, 11, "Middle-Click", colors.black, colors.yellow)
                        write(1, 12, "Create new filter or", colors.black, colors.orange)
                        write(1, 13, "Create new preset", colors.black, colors.orange)
                        while true do
                            local _, button, click_x, click_y = os.pullEvent("mouse_click")
                            if click_y == 1 and click_x == w then
                                break
                            end
                        end
                    end 
                elseif event[4] == 2 then --If Y is equal to 2
                    if event[2] == 1 then --If left click
                        term.setCursorPos(1,2)
                        fill(1,2,w,2,colors.black, nil, " ")
                        local selected_filter = read(nil, nil, function(text) return completion.choice(text, fs.list("/GSX/filter/")) end, filter_preset..".txt")
                        if fs.exists("/GSX/filter/"..selected_filter) and not fs.isDir("/GSX/filter/"..selected_filter) then
                            filter_preset = selected_filter:gsub("(.+)%.%w+", "%1")
                            savePreset()
                            loadFilter()
                        end
                    elseif event[2] == 3 then --If middle click
                        term.setCursorPos(1,2)
                        fill(1,2,w,2,colors.black, nil, " ")
                        local new_filter = read(nil, nil, function(text) return completion.choice(text, {"New Preset"}) end, "")
                        if not fs.exists("/GSX/filter/"..new_filter) then
                            filter_preset = new_filter
                            savePreset()
                            filter = {}
                            saveFilter()
                        end
                    elseif event[2] == 2 then --If Right Click
                        term.setCursorPos(1,2)
                        fill(1,2,w,2,colors.black, nil, " ")
                        local confirmation = read(nil, nil, function(text) return completion.choice(text, {"Delete? (Y/N)"}) end, "")
                        if confirmation:lower() == "y" or confirmation:lower() == "yes" then
                            filter = {}
                            fs.delete("/GSX/filter/"..filter_preset..".txt")
                            filter_preset = "default"
                            savePreset()
                            loadFilter()
                        end
                    end
                elseif event[4] > 2 then
                    local entry_num = entries[event[4]]
                    local entry_table = filter[entry_num]

                    if entry_num and entry_table then
                        if event[2] == 1 then --If left click
                            while true do
                                term.clear()
                                term.setCursorPos(1,1)
                                fill(1, 1, w, 1, colors.gray, nil, " ")
                                write(1, 1, string.char(0x07).." Filter Editor ("..entry_num..")", colors.gray, colors.orange)

                                write(w, 1, "X", colors.gray, colors.red)

                                write(1,3, "Name:", colors.black, colors.lightGray)
                                write(1,4, entry_table.name, colors.black, colors.white)

                                write(1,6, "ID:", colors.black, colors.lightGray)
                                write(1,7, entry_table.id, colors.black, colors.white)

                                write(1,9, "Color:", colors.black, colors.lightGray)
                                write(1,10, getColorName(entry_table.color), colors.black, entry_table.color)

                                local event = {os.pullEvent()}

                                if event[1] == "mouse_click" then
                                    if event[2] == 1 then --IF left click
                                        if event[4] == 4 then
                                            term.setCursorPos(2,4)
                                            fill(1, 4, w, 4, colors.black, nil, " ")
                                            local new_name = read(nil, nil, function(text) return completion.choice(text, {entry_table.name}) end, entry_table.name)
                                            entry_table.name = new_name
                                        elseif event[4] == 7 then
                                            term.setCursorPos(2,7)
                                            fill(1, 7, w, 7, colors.black, nil, " ")
                                            local new_id = read(nil, nil, function(text) return completion.choice(text, {entry_table.id}) end, entry_table.id)
                                            entry_table.id = new_id
                                        elseif event[4] == 10 then
                                            term.setCursorPos(2,10)
                                            fill(1, 10, w, 10, colors.black, nil, " ")
                                            term.setCursorPos(2,10)
                                            local old_fg = term.getTextColor()
                                            for k,v in pairs(color_table) do
                                                term.setTextColor(v)
                                                term.write("X")
                                            end
                                            term.setTextColor(old_fg)

                                            local _, button, click_x, click_y = os.pullEvent("mouse_click")
                                            if click_y == 10 and inside_range(click_x, 2, 1+#color_table) then
                                                entry_table.color = color_table[click_x-1]
                                            end
                                        elseif event[4] == 1 then
                                            if event[3] == w then
                                                saveFilter()
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                        elseif event[2] == 2 then --If right click
                            fill(3, event[4], w, event[4], colors.red, nil, " ")
                            write(1, event[4], "X", colors.black, colors.red)
                            write(3, event[4], entry_table.name, colors.red, colors.yellow)
                            local _, button, click_x, click_y = os.pullEvent("mouse_click")
                            if click_y == event[4] and click_x == 1  then
                                entry_table = nil
                                table.remove(filter, entry_num)
                                saveFilter()
                                filter_scroll = clamp(filter_scroll, 0, clamp(#(filter or {})-(h-3), 0, #filter))
                            end
                        end
                    end

                    if event[2] == 3 then --if middle click
                        filter[#filter+1] = {id="none",color=colors.white,name="New Filter"}
                        filter_scroll = clamp(filter_scroll+(#filter*2), 0, clamp(#(filter or {})-(h-3), 0, #filter))
                    end
                end
            end
            sleep(0)
        end
    end,
    startScanner=function()
        parallel.waitForAny(coreThread, drawPosThread)
    end,
    exit=function()
        exit = true
        return "EXIT NOW"
    end,
    setUsername=function()
        sleep(0.25)
        while not isPresent("playerDetector") do
            pocket.equipBack()
        end
        local temp_detector = peripheral.find("playerDetector")
        player_list = temp_detector.getOnlinePlayers() or {}
        term.clear()
        write(1,1,"Enter New User:", colors.black, colors.yellow)
        term.setCursorPos(1,2)
        
        local new_user = read(nil, nil, function(text) return completion.choice(text, player_list) end, player_username)
        player_username = new_user

        local file = io.open("GSX/username.txt", "w")
        file:write(player_username)
        file:close()
    end
}

local mainMenuButtons = {
    {id=1, x=1, y=3, text="Start Scanner", fg=colors.lime, bg=colors.black, func=buttons.startScanner, key=keys.one},
    {id=2, x=1, y=4, text="Edit Filters", fg=colors.orange, bg=colors.black, func=buttons.filterEditor, key=keys.two},
    {id=3, x=1, y=6, text="Set User", fg=colors.yellow, bg=colors.black, func=buttons.setUsername, key=keys.three},
    {id="E", x=1, y=8, text="Exit Program", fg=colors.red, bg=colors.black, func=buttons.exit, key=keys.e}
}

while true do
    term.clear()
    term.setCursorPos(1,1)
    fill(1, 1, w, 1, colors.lightGray, nil, " ")
    write(1, 1, string.char(0x07).." GeoScannerX", colors.lightGray, colors.black)

    write(1, h, "User: "..player_username)

    for k,v in pairs(mainMenuButtons) do
        write(v.x, v.y, v.id..". "..v.text, v.bg, v.fg) --Writes the button's text starting with the ID , egs. "1. ButtonText"
    end

    local event = {os.pullEvent()}

    if event[1] == "key" then
        for k,v in pairs(mainMenuButtons) do
            if event[2] == v.key then
                local stat, err = pcall(v.func)
                if not stat and err ~= "Terminated" then error(err) end
                break
            end
        end
    elseif event[1] == "mouse_click" then
        for k,v in pairs(mainMenuButtons) do
            if event[4] == v.y then
                local stat, err = pcall(v.func)
                if not stat and err ~= "Terminated" then error(err) end
                break
            end
        end
    end

    if exit then
        return
    end

    sleep(0.25)
end
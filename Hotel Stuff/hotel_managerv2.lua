local modems = {peripheral.find("modem")}
local completion = require("cc.completion")

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

local args = {...}

local config = {}

local width, height = term.getSize()

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

local width, height = term.getSize()
local height_middle = math.ceil(height/2)

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

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

if args[1] == "config" or not fs.exists("/Hotel_clientconfig.txt") then
    print("Welcome to the configuration wizard!")
    print("id_pass?")
    config.id_pass = read()

    local configfile = io.open("/Hotel_clientconfig.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end

local configfile = io.open("/Hotel_clientconfig.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

modem.closeAll()
os.sleep(0.1)
rednet.open(peripheral.getName(modem))

term.clear()
term.setCursorPos(1,1)

print("Searching servers..")

local function sort_func(a,b)
    return a.id < b.id
end

local hotel_list = {rednet.lookup("hotel_server_"..config.id_pass)}

local is_updating = false

local function update_list()
    is_updating = true
    os.queueEvent("updating_list")
    hotel_list = {rednet.lookup("hotel_server_"..config.id_pass)}
    for k,v in ipairs(hotel_list) do
        if v then
            rednet.send(v, "", "serverNameRequest")
            local id, msg, protocol = rednet.receive("serverNameReply",1)

            rednet.send(v, config.id_pass, "hotelUserRequest")
            local id, username, protocol = rednet.receive("hotelUserReply",1)

            rednet.send(v, config.id_pass, "hotelDateRequest")
            local id, last_date, protocol = rednet.receive("hotelDateReply",1)
            hotel_list[k] = {
                id=v,
                name=msg or "UNKNOWN",
                user=username or "UNKNOWN",
                date=last_date
            }
        end
    end
    table.sort(hotel_list, sort_func)
    is_updating = false
end

update_list()

term.clear()
term.setCursorPos(1,1)

fill(1,1, width, 1, colors.lightGray, colors.white, " ")
write(1,1, "Hotel Manager", colors.lightGray, colors.black)

local scroll = 0

local max_id_length = 0
local max_name_length = 0
local max_user_length = 0

local id_column = 1
local name_column = id_column+max_id_length+3
local user_column = name_column+max_name_length+3
local date_column = user_column+max_user_length+3

local function update_max_lengths()
    max_id_length = 0
    for k,v in pairs(hotel_list) do
        if #tostring(v.id) > max_id_length then
            max_id_length = #tostring(v.id)
        end
    end
    name_column = id_column+max_id_length+3

    max_name_length = 0
    for k,v in pairs(hotel_list) do
        if #(v.name) > max_name_length then
            max_name_length = #(v.name)
        end
    end
    user_column = name_column+max_name_length+3

    max_user_length = 0
    for k,v in pairs(hotel_list) do
        if #(v.user) > max_user_length then
            max_user_length = #(v.user)
        end
    end
    date_column = user_column+max_user_length+3
end

update_max_lengths()

local next_update = os.epoch("utc")+30000

local main_thread = function()
    while true do
        if is_updating then
            repeat
                sleep(0.5)
            until not is_updating
        end
        fill(1,2, width, 2, colors.black, colors.yellow, " ")
        write(id_column, 2, "ID", colors.black, colors.yellow)
        write(name_column-2, 2, "| Name", colors.black, colors.yellow)
        write(user_column-2,2, "| User", colors.black, colors.yellow)
        write(date_column-2,2, "| Last Usage Date", colors.black, colors.yellow)

        for i1=1, height-2 do
            local fg = colors.lightGray

            if (i1+scroll)%2 == 1 then
                fg = colors.gray
            end


            local entry = hotel_list[i1+scroll]
            if not entry then
                break
            end
            fill(1, 2+i1, width, 2+i1, colors.black, fg, " ")

            write(id_column, 2+i1, entry.id, colors.black, fg)
            write(id_column-2, 2+i1, "|", colors.black, colors.gray)

            write(name_column, 2+i1, entry.name, colors.black, fg)
            write(name_column-2, 2+i1, "|", colors.black, colors.gray)

            write(user_column, 2+i1, entry.user, colors.black, fg)
            write(user_column-2, 2+i1, "|", colors.black, colors.gray)

            write(date_column, 2+i1, entry.date, colors.black, fg)
            write(date_column-2, 2+i1, "|", colors.black, colors.gray)
        end
        local event = {os.pullEvent()}
        if event[1] == "mouse_scroll" then
            scroll = clamp(scroll+event[2], 0, clamp(#hotel_list-(height-2), 0, #hotel_list))
        elseif event[1] == "mouse_click" then
            local x, y = event[3], event[4]

            if y > 2 then
                local entry_num = (y-2)+scroll
                local entry = hotel_list[entry_num]

                if entry then
                    term.setCursorPos(user_column, y)
                    local completion_table = {}
                    local ply = peripheral.find("playerDetector")
                    if ply then
                        completion_table = ply.getOnlinePlayers()
                    else
                        completion_table = {entry.user}
                    end
                    fill(user_column, y, width, y, colors.black, colors.lime, " ")
                    term.setTextColor(colors.lime)
                    local new_name = read(nil, nil, function(text) return completion.choice(text, completion_table) end, entry.user)

                    rednet.send(entry.id, config.id_pass, "changeHotelUser_Auth")
                    local id, reply = rednet.receive("changeHotelUser_Auth_Reply", 1)
                    if reply == "ALLOWED" then
                        rednet.send(entry.id, new_name, "changeHotelUser_NewUser")
                        hotel_list[entry_num].user = new_name
                        update_max_lengths()
                    elseif reply == "DENIED" then
                        term.setCursorPos(user_column, y)
                        fill(user_column, y, width, y, colors.red, colors.white, " ")
                        write(user_column, y, "Access Denied", colors.red, colors.white)
                        sleep(3)
                    else
                        term.setCursorPos(user_column, y)
                        fill(user_column, y, width, y, colors.red, colors.white, " ")
                        write(user_column, y, "Unknown Error", colors.red, colors.white)
                        sleep(3)
                    end
                end
            elseif y == 1 then
                next_update = os.epoch("utc")+500
            end
        end
    end
end

local update_thread = function()
    while true do
        repeat
            sleep(1)
        until os.epoch("utc") >= next_update
        update_list()
        next_update = os.epoch("utc")+30000
    end
end

local status_thread = function()
    while true do
        os.pullEvent("updating_list")
        local count = 0
        while is_updating do
            count = count+1
            write(#"Hotel Manager"+2, 1, string.rep(".", (count%3)+1).."  ", colors.lightGray, colors.black)
            sleep(0.25)
        end
        fill(#"Hotel Manager"+2, 1, width, 1, colors.lightGray, colors.black, " ")
    end
end

local stat, err = pcall(function()
    parallel.waitForAny(status_thread, main_thread, update_thread)
end)
if not stat then
    if err == "Terminated" then
        term.clear()
        term.setCursorPos(1,1)
        print("Hotel Manager has been terminated")
        return
    else
        error(err)
    end
end
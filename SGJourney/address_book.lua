local printer = peripheral.find("printer")
local completion = require("cc.completion")
local chat_box = peripheral.find("chatBox")

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host("jjs_sg_addressbook", tostring(os.getComputerID()))
end

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

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function endPage()
    local stat
    repeat
        stat = printer.endPage()
        sleep(0.25)
    until stat == true
end

local address_book = {}

local function loadSave()
    if fs.exists("saved_address.txt") then
        local file = io.open("saved_address.txt", "r")
        address_book = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open("saved_address.txt", "w")
    file:write(textutils.serialise(address_book))
    file:close()
end

local config = {}

local function loadConfig()
    if fs.exists("saved_config.txt") then
        local file = io.open("saved_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open("saved_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

local exit = false

loadConfig()

config.pocket_mode = config.pocket_mode or false
local hold_shift = false
local hold_alt = false
local hold_ctrl = false

local pocket_show_address = false

local cmd_history = {}

local w,h = term.getSize()

local function addressToString(address, separator, hasPrefixSuffix)
    local output = ""
    separator = separator or ""
    for k,v in ipairs(address) do
        if k == 1 and not hasPrefixSuffix then
            output=output..tostring(v)
        else
            output=output..separator..tostring(v)
        end
    end
    if hasPrefixSuffix then output = output..separator end
    return output
end

local commands = {
    {
        main="edit", 
        args={
            {name="entry", type="int", outline="<>"}
        },
        func=(function(...)
            local entry_num = ...
            local selected_entry = address_book[tonumber(entry_num)]
            if selected_entry then
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Editing: Name")
                term.setCursorPos(1, h-1)
                term.write("> ")
                selected_entry.name = read(nil, nil, function(text) return completion.choice(text, {selected_entry.name or "No Name"}) end, selected_entry.name or "No Name")

                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Editing: Address")
                term.setCursorPos(1, h-1)
                term.write("> ")
                local new_address = read(nil, nil, function(text) write(1, h-2, "Editing: Address ("..#(split(text, " ") or {}).." Symbols)") return completion.choice(text, {table.concat(selected_entry.address, " ")}) end, table.concat(selected_entry.address, " "))
                local new_address_table = split(new_address, " ")
                for k,v in pairs(new_address_table) do
                    new_address_table[k] = tonumber(v)
                end
                selected_entry.address = new_address_table

                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Editing: Security Level")
                term.setCursorPos(1, h-1)
                term.write("> ")
                local new_security = read(nil, nil, function(text) return completion.choice(text, {"public", "private"}) end, selected_entry.security or "private")
                if new_security == "public" or new_security == "private" then
                    selected_entry.security = new_security
                else
                    selected_entry.security = "private"
                end
            end
        end)
    },
    {
        main="new", 
        args={
            {name="entry", type="int", outline="<>"}
        },
        func=(function(...)
            local entry_num = ...
            local selected_entry = {}
            if selected_entry then
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Adding: Name")
                term.setCursorPos(1, h-1)
                term.write("> ")
                selected_entry.name = read(nil, nil, function(text) return completion.choice(text, {selected_entry.name or "New Entry"}) end, selected_entry.name or "New Entry")

                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Adding: Address")
                term.setCursorPos(1, h-1)
                term.write("> ")
                local new_address = read(nil, nil, function(text) write(1, h-2, "Editing: Address ("..#(split(text, " ") or {}).." Symbols)") return completion.choice(text, {table.concat(selected_entry.address or {}, " ")}) end, table.concat(selected_entry.address or {}, " "))
                local new_address_table = split(new_address, " ")
                for k,v in pairs(new_address_table) do
                    new_address_table[k] = tonumber(v)
                end
                selected_entry.address = new_address_table

                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Adding: Security Level")
                term.setCursorPos(1, h-1)
                term.write("> ")
                local new_security = read(nil, nil, function(text) return completion.choice(text, {"public", "private"}) end, selected_entry.security or "private")
                if new_security == "public" or new_security == "private" then
                    selected_entry.security = new_security
                else
                    selected_entry.security = "private"
                end
                table.insert(address_book, tonumber(entry_num) or #address_book+1, selected_entry)
            end
        end)
    },
    {
        main="remove", 
        args={
            {name="entry", type="int", outline="<>"}
        },
        func=(function(...)
            local entry_num = ...
            table.remove(address_book, entry_num)
        end)
    },
    {
        main="exit", 
        args={},
        func=(function(...)
            exit = true
        end)
    },
    {
        main="save", 
        args={},
        func=(function(...)
            writeSave()
        end)
    },
    {
        main="print", 
        args={
            {name="compact", type="bool", outline="<>"},
            {name="security", type="public or private or both", outline="[]"},
        },
        func=(function(...)
            local mode , security = ...

            if mode == "true" or mode == "1" or mode == "yes" then
                mode = true
            else
                mode = false
            end

            security = security or "public"

            printer.newPage()
            printer.setPageTitle("Page 1")
            local page_w, page_h = printer.getPageSize()
            printer.setCursorPos(1,1)

            local page_num = 1

            for k,v in ipairs(address_book) do
                local pos_x, pos_y = printer.getCursorPos()
                if pos_y >= page_h-1 then
                    endPage()
                    page_num = page_num+1
                    printer.newPage()
                    printer.setPageTitle("Page "..page_num)
                    printer.setCursorPos(1,1)
                end
                local pos_x, pos_y = printer.getCursorPos()

                if v.security == security or security == "both" then
                    printer.write("#"..v.name.."")
                    
                    printer.setCursorPos((mode and 2 or 1),pos_y+1)
                    printer.write(addressToString(v.address, " ", false))
                    printer.setCursorPos(1,pos_y+(mode and 2 or 3))
                end
            end
            endPage()
        end)
    },
    {
        main="chat", 
        args={
            {name="entry", type="int", outline="<>"},
            {name="player", type="username", outline="[]"},
        },
        func=(function(...)
            local entry_num, username = ...
            local selected_entry = address_book[tonumber(entry_num)]

            local msg_text = '["",{"text":"\n"},{"text":"Name: ","color":"yellow"},{"text":"$NAME","color":"aqua","clickEvent":{"action":"copy_to_clipboard","value":"$NAME"},"hoverEvent":{"action":"show_text","contents":"Click to Copy"}},{"text":"\n"},{"text":"Address: ","color":"yellow"},{"text":"$ADDRESS","color":"aqua","clickEvent":{"action":"copy_to_clipboard","value":"$ADDRESS"},"hoverEvent":{"action":"show_text","contents":"Click to Copy"}}]'
            msg_text = msg_text:gsub("$ADDRESS", addressToString(selected_entry.address, "-", true))
            msg_text = msg_text:gsub("$NAME", selected_entry.name)
            
            local msg_text_whisper = '["",{"text":"(Whisper)","italic":true,"color":"gray"},{"text":"\n"},{"text":"Name: ","color":"yellow"},{"text":"$NAME","color":"aqua","clickEvent":{"action":"copy_to_clipboard","value":"$NAME"},"hoverEvent":{"action":"show_text","contents":"Click to Copy"}},{"text":"\n"},{"text":"Address: ","color":"yellow"},{"text":"$ADDRESS","color":"aqua","clickEvent":{"action":"copy_to_clipboard","value":"$ADDRESS"},"hoverEvent":{"action":"show_text","contents":"Click to Copy"}}]'
            msg_text_whisper = msg_text_whisper:gsub("$ADDRESS", addressToString(selected_entry.address, "-", true))
            msg_text_whisper = msg_text_whisper:gsub("$NAME", selected_entry.name)

            if username then
                chat_box.sendFormattedMessageToPlayer(msg_text_whisper, username, "Address Book")
            else
                chat_box.sendFormattedMessage(msg_text, "Address Book")
            end
        end)
    },
    {
        main="pocket",
        args={},
        func=(function()
            config.pocket_mode = not config.pocket_mode
            writeConfig()
        end)
    },
    {
        main="sg",
        args={
            {name="mode", type="dial/stop", outline="<>"},
            {name="entry", type="int/temp", outline="[]"},
        },
        func=(function(...)
            local mode, entry = ...

            if not (mode == "dial" or mode == "stop") then
                return
            end

            local temp_address = {}

            if entry == "temp" then
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Adding: Address")
                term.setCursorPos(1, h-1)
                term.write("> ")
                local new_address = read(nil, nil, function(text) write(1, h-2, "Enter Address ("..#(split(text, " ") or {}).." Symbols)") return completion.choice(text, {}) end, "")
                local new_address_table = split(new_address, " ")
                for k,v in ipairs(new_address_table) do
                    if tonumber(v) then
                        temp_address[#temp_address+1] = tonumber(v)
                    end
                end
            end

            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "Fetching Gates..")

            local hosts
            for i1=1, 5 do
                hosts = {rednet.lookup("jjs_sg_remotedial")}
                if hosts[1] then
                    break
                end
                sleep(0.5)
                if i1 > 1 then
                    fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                    write(1, h-2, "Fetching Gates.. (x"..i1..")")
                end
            end
            local gates = {}
            local gates_completion = {}

            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "Fetching Labels..")

            for k,v in ipairs(hosts) do
                rednet.send(v, "", "jjs_sg_getlabel")
                local id, name
                for i1=1, 5 do
                    id, name = rednet.receive("jjs_sg_sendlabel", 1)
                    if name then break end
                    if i1 > 1 then
                        fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                        write(1, h-2, "Fetching Gates.. (x"..i1..")")
                    end
                end
                gates[name or "unknown"] = id
                gates_completion[#gates_completion+1] = name
                sleep(0.125)
            end

            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "Select Gate")
            term.setCursorPos(1, h-1)
            term.write("> ")
            local selected_gate = read(nil, nil, function(text) return completion.choice(text, gates_completion) end, "")

            if gates[selected_gate] then
                if mode == "dial" and (address_book[tonumber(entry)] or entry == "temp") then
                    if entry == "temp" then
                        rednet.send(gates[selected_gate], table.concat(temp_address, "-"), "jjs_sg_startdial")
                    else
                        rednet.send(gates[selected_gate], table.concat(address_book[tonumber(entry)].address, "-"), "jjs_sg_startdial")
                    end
                elseif mode == "stop" then
                    rednet.send(gates[selected_gate], "", "jjs_sg_disconnect")
                end
            end
        end)
    },
    {
        main="transfer",
        args={
            {name="mode", type="in/out", outline="<>"},
            {name="first", type="int", outline="[]"},
            {name="last", type="int", outline="[]"}
        },
        func=(function(...)
            local mode, first, last = ...

            if not modem or not mode then
                return
            end

            local connection_attempts = 0
            local connected = false

            if mode:lower() == "in" then
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "(Current ID: "..os.getComputerID()..")")
                term.setCursorPos(1, h-1)
                term.write("> Waiting for Transmitter..")

                local id, msg = rednet.receive("jjs_sg_transmit_confirm_client", 10)
                
                if (msg == "confirm") then
                    rednet.send(id, "confirm", "jjs_sg_transmit_confirm_client")
                    fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                    write(1, h-2, "CONNECTED")
                    connected = true
                else
                    return
                end

                if connected then
                    local id, entries_to_add = rednet.receive("jjs_sg_transmit_data", 10)
                    local count = 0
                    for k,v in ipairs(entries_to_add) do
                        if first then
                            table.insert(address_book, tonumber(first+count) or #address_book+1, v)
                        else
                            table.insert(address_book, #address_book+1, v)
                        end
                        count = count+1
                    end
                end

            elseif mode:lower() == "out" then
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Enter Receiver's ID:")
                term.setCursorPos(1, h-1)
                term.write("> ")

                local selected_id = read(nil, nil, nil, "")
                selected_id = tonumber(selected_id)
                
                if not selected_id then 
                    return
                end
                
                while true do
                    rednet.send(selected_id, "confirm", "jjs_sg_transmit_confirm_client")
                    local id, msg = rednet.receive("jjs_sg_transmit_confirm_client", 2)
                    connection_attempts = connection_attempts+1
                    if (id == selected_id and msg == "confirm") then
                       connected = true
                       break 
                    elseif connection_attempts > 6 then
                        break
                    end
                end

                local address_to_send = {}

                for i1=(first or 1), (last or #address_book) do
                    address_to_send[#address_to_send+1] = address_book[i1]
                end

                if connected then
                    fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                    write(1, h-2, "CONNECTED")
                    sleep(0.5)
                    rednet.send(selected_id, address_to_send, "jjs_sg_transmit_data")
                end
            end
        end)
    },
    {
        main="shell",
        args={
            {name="cmd", type="cmd", outline="<>"}
        },
        func=(function(...)
            shell.run(...)
        end)
    },
    {
        main="clearall",
        args={},
        func=(function(...)
            for i1=1, #address_book do
                table.remove(address_book, 1)
            end
            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "Cleared all data")
            sleep(0.5)
            write(1, h-2, "(Not permanent if unsaved)")
            sleep(0.5)
        end)
    },
    {
        main="reload",
        args={},
        func=(function(...)
            loadSave()
            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "Reloaded from file!")
            sleep(0.5)
        end)
    },
}

local function getCommand(name)
    for k,v in pairs(commands) do
        if v.main == name then
            return v
        end
    end
    return nil
end

local function getCommandNum(name)
    for k,v in pairs(commands) do
        if v.main == name then
            return k
        end
    end
    return nil
end

local function getCommandList()
    local list = {}
    for k,v in pairs(commands) do
        list[#list+1] = v.main
    end
    return list
end

local function isCommand(name)
    for k,v in pairs(commands) do
        if v.main == name then
            return true
        end
    end
    return false
end

local function getArgNames(cmd, limit)
    limit = limit or math.huge
    local list = {}
    if type(cmd) == "table" then
        for k,v in ipairs(cmd.args) do
            list[#list+1] = v.outline:sub(1,1)..v.name..":"..v.type..""..v.outline:sub(2,2)
            if k >= limit then
                break
            end
        end
    elseif type(cmd) == "string" then
        for k,v in ipairs(getCommand(cmd)) do
            list[#list+1] = v.outline:sub(1,1)..v.name..":"..v.type..""..v.outline:sub(2,2)
            if k >= limit then
                break
            end
        end
    end
    return list
end

local function getCommandNameList()
    local cmd_list = ""
    for key,cmd in ipairs(commands) do
        if key == 1 then
            cmd_list = cmd_list..cmd.main
        else
            cmd_list = cmd_list..", "..cmd.main
        end
    end
    return cmd_list
end


local scroll = 0

local cmd_list_scroll = 0

local is_on_terminal = false

loadSave()
term.clear()

local function command_autocomplete(text)
    local cmd_split = split(text, " ")
    local cmd_completion = {}
    cmd_completion = getCommandList()
    if isCommand(cmd_split[1]) or isCommand(text) then
        local cmd = getCommand(cmd_split[1])
        fill(11, h-2, w, h-2, colors.black, colors.white, " ")
        local old_x, old_y = term.getCursorPos()
        term.setCursorPos(11, h-2)
        term.setTextColor(colors.lightGray)
        local arg_names = getArgNames(cmd)
        
        for k,v in ipairs(arg_names) do
            if (cmd_split[k+1] or "") ~= ""  then
                term.write(cmd_split[k+1].." ")
            else
                term.write(v.." ")
            end
        end

        term.setTextColor(colors.white)
        term.setCursorPos(old_x, old_y)
    else
        fill(11, h-2, w, h-2, colors.black, colors.white, " ")
        write(11, h-2, getCommandNameList(), colors.black, colors.lightGray)
    end
    return completion.choice(text, cmd_completion)
end

local function listThread()
    while true do
        local old_x, old_y = term.getCursorPos()
        term.setCursorPos(1,1)
        term.write("Address Book")
        for i1=1, h-4 do
            local selected_num = i1+scroll
            local selected_address = address_book[selected_num]
            if selected_address then
                fill(1,1+i1, w, 1+i1, colors.black, colors.white, " ")
                local address_string = addressToString(selected_address.address, "-", true)

                if not config.pocket_mode or (config.pocket_mode and not pocket_show_address) then
                    term.setCursorPos(1, 1+i1)
                    term.write(selected_num..".")
                    if selected_address.security == "public" then
                        term.setTextColor(colors.lime)
                        term.write("\x6F ")
                    else
                        term.setTextColor(colors.red)
                        term.write("\xF8 ")
                    end
                    term.setTextColor(colors.white)
                    term.write(selected_address.name)
                end
                
                if not config.pocket_mode or (config.pocket_mode and pocket_show_address) then
                    term.setCursorPos(w-#address_string, 1+i1)
                    term.write(address_string)
                end
            else
                fill(1,1+i1, w, 1+i1, colors.black, colors.white, " ")
            end
        end
        term.setCursorPos(old_x, old_y)
        os.pullEvent("drawList")
    end
end
local function consoleThread()
    while true do
        term.setCursorPos(1,h-2)
        fill(1,h-2, w,h-1, colors.black, colors.white, " ")
        term.write("Commands: ")
        term.setTextColor(colors.lightGray)
        local cmd_list = getCommandNameList()
        term.write(cmd_list)
        term.setTextColor(colors.white)

        term.setCursorPos(1,h-1)
        term.write("> ")

        is_on_terminal = true

        local input_cmd = read(nil, nil, command_autocomplete, "")
        local split_cmd = split(input_cmd, " ")

        local cmd_data = getCommand(split_cmd[1])
        if cmd_data then
            local stat, err = pcall(cmd_data.func, table.unpack(split_cmd, 2))
            if not stat then error(err) end
        end

        os.queueEvent("drawList")

        is_on_terminal = false

        sleep(0.25)
    end
end

local function scrollThread()
    while true do
        local event, scroll_input, x, y = os.pullEvent("mouse_scroll")
        if is_on_terminal then
            scroll = math.ceil(clamp(scroll+(scroll_input*3), 0, clamp(#address_book-(h-4), 0, #address_book)))
            os.queueEvent("drawList")
        end
    end
end

local function keyThread()
    while true do
        local event, key, holding = os.pullEvent()
        if (event == "key" or event == "key_up") and not holding then
            if event == "key" then
                if key == keys.leftShift or key == keys.rightShift then
                    hold_shift = true
                    os.queueEvent("drawList")
                elseif key == keys.leftAlt or key == keys.rightAlt then
                    hold_alt = true
                    pocket_show_address = true
                    os.queueEvent("drawList")
                elseif key == keys.leftCtrl or key == keys.rightCtrl then
                    hold_ctrl = true
                    os.queueEvent("drawList")
                end
            elseif event == "key_up" then
                if key == keys.leftShift or key == keys.rightShift then
                    hold_shift = false
                    os.queueEvent("drawList")
                elseif key == keys.leftAlt or key == keys.rightAlt then
                    hold_alt = false

                    if not hold_ctrl then
                        pocket_show_address = false
                    end
                    os.queueEvent("drawList")
                elseif key == keys.leftCtrl or key == keys.rightCtrl then
                    hold_ctrl = false
                    os.queueEvent("drawList")
                end
            end
        end
    end
end

local function lookupThread()
    while true do
        local id, msg, protocol = rednet.receive()
        local return_data
        if protocol == "jjs_sg_lookup_address" then
            local to_search = table.concat(msg, "-")
            for k,v in pairs(address_book) do
                if table.concat(v.address, "-") == to_search then
                    return_data = v
                    break
                end
            end
        elseif protocol == "jjs_sg_lookup_name" then
            local to_search = msg
            for k,v in pairs(address_book) do
                if v.name == to_search then
                    return_data = v
                    break
                end
            end
        end

        if return_data then
            rednet.send(id, return_data, "jjs_sg_lookup_return")
        else
            rednet.send(id, return_data, "jjs_sg_lookup_fail")
        end
    end
end

local function exitThread()
    while true do
        if exit then
            return
        end
        sleep(0.5)
    end
end

parallel.waitForAny(consoleThread, listThread, scrollThread, keyThread, lookupThread, exitThread)


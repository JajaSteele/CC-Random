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

    modem.open(2707)
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

config.sgw_key = config.sgw_key or nil
config.sgw_socket = config.sgw_socket or nil
config.sgw_enabled = config.sgw_enabled or false
config.pocket_mode = config.pocket_mode or false
config.master_id = config.master_id or nil
config.nearest_range = config.nearest_range or 200

local function writeSave()
    local file = io.open("saved_address.txt", "w")
    file:write(textutils.serialise(address_book))
    file:close()
end
local function loadSave()
    if fs.exists("saved_address.txt") then
        local file = io.open("saved_address.txt", "r")
        address_book = textutils.unserialise(file:read("*a"))
        file:close()
    end
    if config.master_id then
        rednet.send(config.master_id, "", "jjs_sg_sync_request")
        local attempts = 0
        local id, msg, protocol
        repeat
            id, msg, protocol = rednet.receive("jjs_sg_sync_data", 0.075)
            attempts = attempts+1
        until id == config.master_id or attempts >= 5
        if msg then
            address_book = msg
            writeSave()
        end
    end
end

local hold_shift = false
local hold_alt = false
local hold_ctrl = false

local pocket_show_address = false

local input_text = ""
local is_on_help = false
local scroll = 0

local cmd_history = {}

local w,h = term.getSize()

local websocket_connection
local websocket_success = false

local cached_nearest_gate = {}

local function getNearestGate()
    if cached_nearest_gate.id then
        local attempts = 0
        repeat
            modem.transmit(cached_nearest_gate.id, os.getComputerID(), {protocol="jjs_checkalive", message="ask_alive"})
            modem.open(os.getComputerID())
            local wait_timer = os.startTimer(0.075)
            local data = {os.pullEvent()}
            if data[1] == "modem_message" then
                local event, side, channel, replyChannel, msg, distance = table.unpack(data)
                if type(msg) == "table" and msg.protocol == "jjs_checkalive" and msg.message == "confirm_alive" then
                    os.cancelTimer(wait_timer)
                    if distance and distance < config.nearest_range then
                        return cached_nearest_gate
                    else
                        break
                    end
                end
            elseif data[1] == "timer" then
                if data[2] == wait_timer then
                    attempts = attempts+1
                else
                    os.cancelTimer(wait_timer)
                end
            end
        until attempts > 4
    end
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
                if event[6] and event[6] < config.nearest_range then  
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
        cached_nearest_gate = temp_gates[1]
    end
    return cached_nearest_gate
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
                if event[6] and event[6] < config.nearest_range then  
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

local commands

commands = {
    {
        main="edit", 
        args={
            {name="entry", type="int", outline="<>", desc="Which entry to edit"}
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
                new_address = new_address:gsub("-", " ")
                local temp_address = split(new_address, " ")
                local new_address_table = {}
                for k,v in pairs(temp_address) do
                    new_address_table[#new_address_table+1] = tonumber(v)
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
        end),
        short_description={
            "Edits the specified entry",
        },
        long_description={
            "Edits the specified entry",
            "Use the 'save' command to save the change",
        }
    },
    {
        main="new", 
        args={
            {name="entry", type="int", outline="<>", desc="Where to place the new entry (If empty, will place new entry at the bottom)"}
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
                new_address = new_address:gsub("-", " ")
                local temp_address = split(new_address, " ")
                local new_address_table = {}
                for k,v in pairs(temp_address) do
                    new_address_table[#new_address_table+1] = tonumber(v)
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
        end),
        short_description={
            "Creates a new entry",
        },
        long_description={
            "Creates a new entry",
            "Use the 'save' command to save the change",
        }
    },
    {
        main="remove", 
        args={
            {name="entry", type="int", outline="<>", desc="Which entry to delete"}
        },
        func=(function(...)
            local entry_num = ...
            table.remove(address_book, entry_num)
        end),
        short_description={
            "Removes the specified entry",
        },
        long_description={
            "Removes the specified entry",
            "Use the 'save' command to save the change",
        }
    },
    {
        main="exit", 
        args={},
        func=(function(...)
            exit = true
        end),
        short_description={
            "Exits the program",
        },
        long_description={
            "Exits the program",
        }
    },
    {
        main="save", 
        args={},
        func=(function(...)
            writeSave()
            rednet.broadcast("", "jjs_sg_sync_reload")
        end),
        short_description={
            "Saves the address book to file",
        },
        long_description={
            "Saves the address book to the save file , NO BACKUPS ARE MADE!",
        }
    },
    {
        main="print", 
        args={
            {name="compact", type="bool", outline="<>", desc="Changes the printing format"},
            {name="security", type="public or private or both", outline="[]", desc="Which entries to print"},
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
        end),
        short_description={
            "Prints the address book on paper using a printer",
        },
        long_description={
            "Prints the address book on paper using a printer",
        }
    },
    {
        main="chat", 
        args={
            {name="entry", type="int", outline="<>", desc="Which entry to share"},
            {name="player", type="username", outline="[]", desc="Player who will receive the address in chat"},
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
        end),
        short_description={
            "Shares the specified address to chat",
        },
        long_description={
            "Shares the specified address to global chat, or to the specified player if [player] is included",
            "Tip: You can click in the chat to copy the address/name!"
        }
    },
    {
        main="pocket",
        args={
            {name="config", type="", outline="[]", desc="Shows the websocket config"},
        },
        func=(function()
            config.pocket_mode = not config.pocket_mode
            writeConfig()
        end),
        short_description={
            "Toggles SGW mode",
        },
        long_description={
            "SGW mode allows to control the gate with a smartwatch (needs additional setup so its mostly for myself lol)",
        }
    },
    {
        main="sgw",
        args={},
        func=(function(...)
            local config_mode = ...

            if not config.sgw_socket or config_mode then
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Websocket URL:")
                term.setCursorPos(1, h-1)
                term.write("> ")
                config.sgw_socket = read(nil, nil, nil, config.sgw_socket)

                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Key:")
                term.setCursorPos(1, h-1)
                term.write("> ")
                config.sgw_key = read(nil, nil, nil, config.sgw_key)

                if websocket_connection then
                    websocket_connection.close()
                end
                websocket_connection = nil
                websocket_success = false

                writeConfig()
            end

            if not config_mode then
                config.sgw_enabled = not config.sgw_enabled
                writeConfig()
            end

            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "SGW: "..tostring(config.sgw_enabled))
            sleep(0.5)
        end),
        short_description={
            "Toggles pocket mode",
        },
        long_description={
            "Pocket mode only displays addresses when holding Alt (can also hold Ctrl before releasing Alt to lock the display)",
        }
    },
    {
        main="sg",
        args={
            {name="mode", type="(quick)dial/(quick)stop", outline="<>", desc="What action to execute on the gate (Can also add 'quick' to use the closest gate, egs: 'sg quickdial 1')"},
            {name="entry", type="int/temp", outline="[]", desc="Which entry to dial, if using dial/quickdial"},
        },
        func=(function(...)
            local mode, entry = ...

            if not (mode == "dial" or mode == "quickdial" or mode == "stop" or mode == "quickstop") then
                return
            end

            local temp_address = {}

            if entry == "temp" then
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Adding: Address")
                term.setCursorPos(1, h-1)
                term.write("> ")
                local new_address = read(nil, nil, function(text) write(1, h-2, "Enter Address ("..#(split(text, " ") or {}).." Symbols)") return completion.choice(text, {}) end, "")
                new_address = new_address:gsub("-", " ")
                local new_address_table = split(new_address, " ")
                for k,v in ipairs(new_address_table) do
                    if tonumber(v) then
                        temp_address[#temp_address+1] = tonumber(v)
                    end
                end
            end

            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "Fetching Gates..")

            local selected_gate 
            local gates = {}
            
            if mode == "dial" or mode == "stop" then
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
                
                selected_gate = read(nil, nil, function(text) return completion.choice(text, gates_completion) end, "")
            elseif mode == "quickdial" or mode == "quickstop" then
                modem.transmit(2707, 2707, {protocol="jjs_sg_dialer_ping", message="request_ping"})

                local temp_gates = {}

                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Found "..(#temp_gates).." gates..")

                local failed_attempts = 0
                while true do
                    local timeout_timer = os.startTimer(0.075)
                    local event = {os.pullEvent()}

                    if event[1] == "modem_message" then
                        if type(event[5]) == "table" and event[5].protocol == "jjs_sg_dialer_ping" and event[5].message == "response_ping" then
                            failed_attempts = 0
                            os.cancelTimer(timeout_timer)
                            if event[6] and event[6] < config.nearest_range then  
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

                    fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                    write(1, h-2, "Found "..(#temp_gates).." gates..")
                end

                table.sort(temp_gates, function(a,b) return (a.distance < b.distance) end)

                if temp_gates[1] then
                    gates[temp_gates[1].label] = temp_gates[1].id
                    selected_gate = temp_gates[1].label

                    fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                    write(1, h-2, "Nearest gate: (# < "..config.nearest_range..")")
                    write(1, h-1, "> "..selected_gate)
                else
                    fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                    write(1, h-1, "> Couldn't find a gate!", colors.black, colors.red)
                    sleep(0.5)
                end
            end

            if gates[selected_gate] then
                if (mode == "dial" or mode == "quickdial") and (address_book[tonumber(entry)] or entry == "temp") then
                    if entry == "temp" then
                        rednet.send(gates[selected_gate], table.concat(temp_address, "-"), "jjs_sg_startdial")
                    else
                        rednet.send(gates[selected_gate], table.concat(address_book[tonumber(entry)].address, "-"), "jjs_sg_startdial")
                    end
                elseif (mode == "stop" or mode == "quickstop") then
                    rednet.send(gates[selected_gate], "", "jjs_sg_disconnect")
                end
            end

            if mode == "quickdial" or mode == "quickstop" then
                sleep(0.5)
            end
        end),
        short_description={
            "Various remote Stargate commands",
        },
        long_description={
            "'dial' will send the specified entry's address to the gate you select afterward (or nearest gate if using quick mode), Shortcut: Middle-click or Shift+Click",
            "'stop' will stop the gate you select afterward (or nearest gate if using quick mode), Shortcut: F4",
        }
    },
    {
        main="transfer",
        args={
            {name="mode", type="in/out", outline="<>", desc="Which way the transfer is going"},
            {name="first", type="int", outline="[]", desc="First entry to send (or place of the new addresses if incoming)"},
            {name="last", type="int", outline="[]", desc="Last entry to send"}
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
        end),
        short_description={
            "Transfer the specified addresses to another computer",
        },
        long_description={
            "Transfers all the addresses between [first] and [last] entry nums (or all of them if un-specified)",
            "1. the transmitting computer will do 'transfer out [first] [last]'",
            "2. the receiving computer will do 'transfer in [first]'",
            "3. and now the transmitting computer will have to rapidly input the receiver's ID, then press Enter"
        }
    },
    {
        main="shell",
        args={
            {name="cmd", type="string", outline="<>", desc="What command and args to use"}
        },
        func=(function(...)
            shell.run(...)
        end),
        short_description={
            "Execute a shell command"
        },
        long_description={
            "Executes a shell command/program with",
            "the provided args"
        }
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
        end),
        short_description={
            "Temp. clear the address book"
        },
        long_description={
            "Temporarily clears the address book",
            "(Until you use the save command, or reload the program/list)"
        }
    },
    {
        main="reload",
        args={},
        func=(function(...)
            loadSave()
            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "Reloaded from file!")
            sleep(0.5)
        end),
        short_description={
            "Reloads the address book"
        },
        long_description={
            "Reloads the address book from the save file, Shortcut: F5"
        }
    },
    {
        main="help",
        args={},
        func=(function()
            is_on_help = true
            scroll = 0
            
            local is_displaying_cmd = false

            local function helpDrawThread()
                while true do
                    if not is_displaying_cmd then
                        term.setCursorPos(1,1)
                        term.setTextColor(colors.white)
                        term.write("Command Guide")
                        fill(1,2, w, h-1, colors.black, colors.white, " ")
                        term.setCursorPos(1,2)
                        local count = 0
                        for i1=1, #commands do
                            local cmd_entry_num = (i1+scroll)
                            local cmd_entry = commands[cmd_entry_num]

                            if cmd_entry then
                                term.setTextColor(colors.yellow)
                                print(cmd_entry.main)
                            end
                        end
                    end
                    os.pullEvent("drawHelp")
                end
            end

            local function helpClickThread()
                while true do
                    local event, button, x, y = os.pullEvent("mouse_click")

                    if button == 1 then
                        if y > 1 then
                            local cmd_num = ((y-1)+scroll)
                            local cmd_entry = commands[cmd_num]

                            if cmd_entry then
                                while true do
                                    is_displaying_cmd = true
                                    fill(1,1, w, h-1, colors.black, colors.white, " ")
                                    term.setCursorPos(1,2)

                                    write(1, 1, "Command Guide", colors.black, colors.white)
                                    write(1, 2, cmd_entry.main, colors.black, colors.yellow)

                                    write(1, 4, "Arguments:", colors.black, colors.white)
                                    for i1=1, #(cmd_entry.args) do
                                        local arg = cmd_entry.args[i1]
                                        write(1, 4+i1, arg.outline:sub(1,1)..arg.name..arg.outline:sub(2,2), colors.black, colors.lightGray)
                                    end

                                    write(1, 4+(#(cmd_entry.args))+2, "Description:", colors.black, colors.white)
                                    term.setTextColor(colors.lightGray)
                                    term.setCursorPos(1, 4+(#(cmd_entry.args))+3)
                                    print(table.concat(cmd_entry.short_description, "\n"))
                                    
                                    local event1, button1, x1, y1 = os.pullEvent("mouse_click")

                                    if button1 == 1 then
                                        if y1 > 4 then
                                            if y1 >= (4+(#(cmd_entry.args))+2) then
                                                fill(1, 4, w, h, colors.black, colors.lightGray, " ")
                                                write(1, 4, "Full Description:", colors.black, colors.white)
                                                term.setTextColor(colors.lightGray)
                                                term.setCursorPos(1, 4+3)
                                                print(table.concat(cmd_entry.long_description, "\n\n"))
                                            else
                                                local arg_num = (y1-4)
                                                local arg = cmd_entry.args[arg_num]
                                                
                                                if arg then
                                                    fill(1, 4, w, h, colors.black, colors.lightGray, " ")
                                                    write(1, 4, arg.name, colors.black, colors.white)
                                                    write(1, 4+1, arg.type, colors.black, colors.lightGray)
                                                    term.setTextColor(colors.gray)
                                                    term.setCursorPos(1, 4+3)
                                                    print(arg.desc)
                                                end
                                            end
                                            local event2, button2 = os.pullEvent("mouse_click")
                                        end
                                    elseif button1 == 2 then
                                        break
                                    end
                                end
                                is_displaying_cmd = false
                                os.queueEvent("drawHelp")
                            end
                        end
                    elseif button == 2 then
                        break
                    end
                end
            end

            parallel.waitForAny(helpDrawThread, helpClickThread)
            is_on_help = false

            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)
        end),
        short_description={
            "Shows a (shitty) command guide"
        },
        long_description={
            "Shows a (shitty) command guide"
        }
    },
    {
        main="disk",
        args={
            {name="direction", type="import/export", outline="<>", desc="'import' from disk or 'export' to disk"}
        },
        func=(function(...)
            local mode = ...

            if mode == "import" then
                if fs.exists("/disk/saved_address.txt") then
                    local import_file = io.open("/disk/saved_address.txt", "r")
                    local import_book = textutils.unserialise(import_file:read("*a"))
                    import_file:close()
                        
                    address_book = import_book

                    fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                    write(1, h-2, "Imported from disk")
                    sleep(0.5)
                end
            elseif mode == "export" then
                local export_file = io.open("/disk/saved_address.txt", "w")
                export_file:write(textutils.serialise(address_book))
                export_file:close()

                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Exported to disk")
                sleep(0.5)
            end
        end),
        short_description={
            "Imports or exports the addresses to/from the disk/pocket in disk drive"
        },
        long_description={
            "Imports or exports the addresses to/from the disk/pocket in disk drive",
        }
    },
    {
        main="slave",
        args={
            {name="id", type="int", outline="<>", desc="ID of the master computer"}
        },
        func=(function(...)
            local master_id = ...
            config.master_id = tonumber(master_id)
            writeConfig()
        end),
        short_description={
            "Turns addressbook into a slave computer"
        },
        long_description={
            "Turns addressbook into a slave computer",
            "The addresses will automatically be copied from master address book on startup/reload"
        }
    },
    {
        main="range",
        args={
            {name="range", type="int", outline="<>", desc="Range in blocks"}
        },
        func=(function(...)
            local nearest_range = ...
            config.nearest_range = tonumber(nearest_range) or config.nearest_range
            writeConfig()
            fill(1, h-2, w, h-1, colors.black, colors.white, " ")
            write(1, h-2, "Set range to: "..config.nearest_range)
            sleep(0.5)
        end),
        short_description={
            "Sets the range for Quickdial and Quickstop"
        },
        long_description={
            "Sets the maximum range for Quickdial and Quickstop"
        }
    },
    {
        main="dialback",
        args = {},
        func = function()
            local nearest_gate = getNearestGate_NoCache()
            if nearest_gate then
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-2, "Nearest gate: (# < "..config.nearest_range..")")
                write(1, h-1, "> "..nearest_gate.label)
                sleep(0.5)

                rednet.send(nearest_gate.id, "gate_dialback", "jjs_sg_rawcommand")
                local id, msg, prot = rednet.receive("jjs_sg_rawcommand_confirm", 0.5)
                if id == nearest_gate.id and msg then
                    fill(1, h-2, w, h-1, colors.black, colors.lime, " ")
                    write(1, h-2, "Command Success", colors.black, colors.white)
                    sleep(0.5)
                else
                    fill(1, h-2, w, h-1, colors.black, colors.red, " ")
                    write(1, h-2, "Command Fail", colors.black, colors.red)
                    sleep(0.5)
                end
            else
                fill(1, h-2, w, h-1, colors.black, colors.white, " ")
                write(1, h-1, "> Couldn't find a gate!", colors.black, colors.red)
                sleep(0.5)
            end
        end,
        short_description = {
            "Dials the last connected address on the nearest gate"
        },
        long_description={
            "Dials the last connected address on the nearest gate",
            "You can also press F6 to execute the command quickly"
        }
    }
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

local cmd_list_scroll = 0

local is_on_terminal = false

loadSave()
term.clear()

local function command_autocomplete(text)
    input_text = text
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
        term.clearLine()
        term.write("Address Book ["..os.getComputerID().."]")
        if config.master_id then
            term.write(" <"..tostring(config.master_id)..">")
        end
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
        if is_on_terminal and not is_on_help then
            scroll = math.ceil(clamp(scroll+(scroll_input*3), 0, clamp(#address_book-(h-4), 0, #address_book)))
            os.queueEvent("drawList")
        end
        if is_on_help then
            scroll = math.ceil(clamp(scroll+(scroll_input*1), 0, #commands))
            os.queueEvent("drawHelp")
        end
    end
end

local function keyThread()
    while true do
        local event, key, holding = os.pullEvent()
        if (event == "key" or event == "key_up") and not holding and not is_on_help then
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

                if is_on_terminal then
                    if key == keys.f4 then
                        for i1=1, #input_text do
                            os.queueEvent("key", keys.backspace, false)
                        end

                        local text_to_input = "sg quickstop"
                        for i1=1, #text_to_input do
                            os.queueEvent("char", text_to_input:sub(i1,i1))
                        end
                        os.queueEvent("key", keys.enter, false)
                    elseif key == keys.f3 then
                        for i1=1, #input_text do
                            os.queueEvent("key", keys.backspace, false)
                        end

                        local text_to_input = "sg quickdial temp"
                        for i1=1, #text_to_input do
                            os.queueEvent("char", text_to_input:sub(i1,i1))
                        end
                        os.queueEvent("key", keys.enter, false)
                    elseif key == keys.f5 then
                        for i1=1, #input_text do
                            os.queueEvent("key", keys.backspace, false)
                        end

                        local text_to_input = "reload"
                        for i1=1, #text_to_input do
                            os.queueEvent("char", text_to_input:sub(i1,i1))
                        end
                        os.queueEvent("key", keys.enter, false)
                    elseif key == keys.f1 then
                        for i1=1, #input_text do
                            os.queueEvent("key", keys.backspace, false)
                        end

                        local text_to_input = "help"
                        for i1=1, #text_to_input do
                            os.queueEvent("char", text_to_input:sub(i1,i1))
                        end
                        os.queueEvent("key", keys.enter, false)
                    elseif key == keys.f6 then
                        for i1=1, #input_text do
                            os.queueEvent("key", keys.backspace, false)
                        end

                        local text_to_input = "dialback"
                        for i1=1, #text_to_input do
                            os.queueEvent("char", text_to_input:sub(i1,i1))
                        end
                        os.queueEvent("key", keys.enter, false)
                    end
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

        if protocol == "jjs_sg_lookup_address" or protocol == "jjs_sg_lookup_name" then
            if return_data then
                rednet.send(id, return_data, "jjs_sg_lookup_return")
            else
                rednet.send(id, return_data, "jjs_sg_lookup_fail")
            end
        end
    end
end

local function clickThread()
    while true do
        local event, button, x, y = os.pullEvent()
        if (event == "mouse_click" or event == "monitor_touch") and y > 1 and y < h-2 and is_on_terminal then
            local entry_num = (y-1)+scroll
            local text_to_input = ""
            local auto_enter = false
            local full_erase = true
            if hold_shift or button == 3 then
                text_to_input = "sg quickdial "..entry_num
                auto_enter = true
            else
                text_to_input = tostring(entry_num)
                full_erase = false
            end

            if full_erase then
                for i1=1, #input_text do
                    os.queueEvent("key", keys.backspace, false)
                end
            end

            for i1=1, #text_to_input do
                os.queueEvent("char", text_to_input:sub(i1,i1))
            end
            if auto_enter then
                os.queueEvent("key", keys.enter, false)
            end
        end
    end
end

local function masterThread()
    while true do
        local id, msg, protocol = rednet.receive("jjs_sg_sync_request")
        local file = io.open("saved_address.txt", "r")
        rednet.send(id, textutils.unserialise(file:read("*a")), "jjs_sg_sync_data")
        file:close()
    end
end

local function reloadSlaveThread()
    while true do
        local id, msg, protocol = rednet.receive("jjs_sg_sync_reload")
        if id == config.master_id then
            loadSave()
            os.queueEvent("drawList")
        end
    end
end

local function exitThread()
    while true do
        if exit then
            term.setTextColor(colors.white)
            term.setBackgroundColor(colors.black)
            term.clear()
            term.setCursorPos(1,1)
            return
        end
        sleep(0.5)
    end
end

local function SGWThread()
    while true do
        if config.sgw_enabled and config.sgw_socket then
            local websocket, err
            local stat, err2 = pcall(function()
                local full_url = config.sgw_socket
                if full_url and full_url:sub(#full_url, #full_url) ~= "/" then
                    full_url = full_url.."/"
                end
                full_url = full_url.."?key="..textutils.urlEncode(config.sgw_key)
                websocket, err = http.websocket(full_url)
            end)

            if websocket_connection then
                websocket_connection.close()
            end

            if websocket then
                websocket_connection = websocket
                write(1, h, "SGW Connection Success", colors.black, colors.lime)
                websocket_success = true
                sleep(0.5)
                fill(1, h, w, h, colors.black, colors.white, " ")
                os.queueEvent("sgw_wake")
            else
                if not stat then
                    write(1, h, "SGW: "..err2, colors.black, colors.red)
                    websocket_success = false
                    sleep(2)
                    fill(1, h, w, h, colors.black, colors.white, " ")
                else
                    write(1, h, "SGW: "..err, colors.black, colors.red)
                    websocket_success = false
                    sleep(2)
                    fill(1, h, w, h, colors.black, colors.white, " ")
                end
            end
            while websocket_success and config.sgw_enabled do
                sleep()
            end
        else
            if websocket_success then
                websocket_connection.close()
                websocket_success = false
                write(1, h, "SGW Connection Closed", colors.black, colors.orange)
                sleep(0.5)
                fill(1, h, w, h, colors.black, colors.white, " ")
            end
            sleep(2)
        end
    end
end

local sgw_command_queue = {}

local function SGWListenerThread()
    while true do
        if websocket_success and config.sgw_enabled then
            local msg 
            local stat, err2 = pcall(function()
                msg = websocket_connection.receive()
            end)
            if stat and msg then
                local queue_msg = true
                if msg == "fetch_addressbook" then
                    queue_msg = false
                    websocket_connection.send("addressbook_transfer_start")
                    for k,address in ipairs(address_book) do
                        websocket_connection.send(textutils.serialize(address, {compact=true}))
                    end
                    websocket_connection.send("addressbook_transfer_end")
                elseif msg:match("address_full_request") then
                    queue_msg = false
                    local split_address = split(msg, " ")
                    for k,v in ipairs(split_address) do
                        local symbol = tonumber(v)
                        if symbol and symbol >= 0 and symbol < 39 then
                            sgw_command_queue[#sgw_command_queue+1] = {attempts=0, cmd=v}
                        end
                    end
                elseif msg == "confirm_alive" then
                    queue_msg = false
                end
                if queue_msg then
                    sgw_command_queue[#sgw_command_queue+1] = {attempts=0, cmd=msg}
                end
            else
                write(1, h, "SGW: "..(err2 or "Listener Error"), colors.black, colors.red)
                websocket_success = false
                sleep(2)
                fill(1, h, w, h, colors.black, colors.white, " ")
            end
        else
            os.pullEvent("sgw_wake")
        end
    end
end

local function SGWSenderThread()
    while true do
        if websocket_success and config.sgw_enabled then
            local last_command = sgw_command_queue[1]
            if last_command then
                local nearest_gate = getNearestGate()
                if nearest_gate and nearest_gate.id then
                    if last_command.attempts == 0 then
                        fill(1, h, w, h, colors.black, colors.white, " ")
                        write(1, h, "SGW: "..last_command.cmd, colors.black, colors.lightBlue)
                    end
                    rednet.send(nearest_gate.id, last_command.cmd, "jjs_sg_rawcommand")
                    local id, msg, prot = rednet.receive("jjs_sg_rawcommand_confirm", 0.15)

                    if id and msg then
                        fill(1, h, w, h, colors.black, colors.white, " ")
                        table.remove(sgw_command_queue, 1)
                    else
                        write(1, h, "SGW ("..last_command.attempts.."): "..last_command.cmd, colors.black, colors.orange)
                        last_command.attempts = last_command.attempts+1
                        if last_command.attempts > 3 then
                            fill(1, h, w, h, colors.red, colors.black, " ")
                            write(1, h, "SGW Fail: "..last_command.cmd, colors.red, colors.black)
                            sleep(0.5)
                            fill(1, h, w, h, colors.black, colors.white, " ")
                            sgw_command_queue = {}
                        end
                    end
                else
                    write(1, h, "SGW: "..last_command.cmd, colors.black, colors.red)
                    table.remove(sgw_command_queue, 1)
                    sleep(1)
                    fill(1, h, w, h, colors.black, colors.white, " ")
                end
            end
        else
            os.pullEvent("sgw_wake")
        end
        sleep(0)
    end
end

local function SGWHeartbeatThread()
    while true do
        if websocket_success and config.sgw_enabled and websocket_connection then
            local stat, err = pcall(function()
                websocket_connection.send("check_alive")
                local msg = websocket_connection.receive(0.25)
                if msg == "confirm_alive" then
                    return
                else
                    error("No Response")
                end
            end)
            if not stat then
                write(1, h, "SGW: "..(err or "Heartbeat Error"), colors.black, colors.red)
                sleep(2)
                fill(1, h, w, h, colors.black, colors.white, " ")
                websocket_connection.close()
                websocket_success = false
            else
                sleep(5)
            end
        else
            os.pullEvent("sgw_wake")
        end
        sleep()
    end
end

parallel.waitForAny(consoleThread, listThread, scrollThread, keyThread, lookupThread, exitThread, clickThread, masterThread, reloadSlaveThread, SGWThread, SGWListenerThread, SGWSenderThread, SGWHeartbeatThread)


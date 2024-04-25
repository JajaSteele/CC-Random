local sg = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local completion = require("cc.completion")

local modems = {peripheral.find("modem")}

local modem

local is_dialing = false

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host("jjs_sg_remotedial", "jjs_sg_remotedial_home_"..os.getComputerID())
    
    modem.open(2707)
end

local dl = peripheral.find("Create_DisplayLink")

local function writeToDisplayLink(line1, line2)
    dl.clear()
    dl.setCursorPos(1,1)
    dl.write(line1 or "")
    dl.setCursorPos(1,2)
    dl.write(line2 or "")
    dl.update()
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

local config = {}
config.label = "Computer "..os.getComputerID()
config.monitor = true
config.address_book_id = nil
local function loadConfig()
    if fs.exists("saved_config_easydial.txt") then
        local file = io.open("saved_config_easydial.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open("saved_config_easydial.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end


loadConfig()

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local address = {}
local display_address = {}

local input_text = ""

local auto_address_call = {}

local monitor = peripheral.find("monitor")
if monitor and config.monitor then
    local mw, mh = monitor.getSize()
    monitor.setTextScale(1)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setPaletteColor(colors.white, 0xFFFFFF)
    monitor.setPaletteColor(colors.black, 0x000000)
end
local function fancyReboot()
    if monitor and config.monitor then
        monitor.setPaletteColor(colors.black, 0x110000)
        local width, height = monitor.getSize()
        local monitor_text = "Rebooting.."
        writeToDisplayLink("Rebooting..")
        monitor.clear()
        monitor.setCursorPos(math.ceil(width/2)-math.ceil(#monitor_text/2), 3)
        monitor.clearLine()
        monitor.setTextColor(colors.red)
        monitor.write(monitor_text)
    end
    os.reboot()
end

local function wait_for_key(pattern, key, mode)
    while true do
        local event = {os.pullEvent()}
        if event[1] == "char" and mode ~= "key" then
            if event[2]:match(pattern) then
                return event[2]
            end
        elseif event[1] == "key" and mode ~= "char" then
            if event[2] == key then
                return event[2]
            end
        end
    end
end

local function addressLookup(lookup_value)
    if not lookup_value then
        return {name="Unknown Address"}
    end

    local id_to_send = config.address_book_id or 0
    if type(lookup_value) == "string" then
        rednet.send(id_to_send, lookup_value, "jjs_sg_lookup_name")
    elseif type(lookup_value) == "table" then
        rednet.send(id_to_send, lookup_value, "jjs_sg_lookup_address")
    end

    for i1=1, 5 do
        local id, msg, protocol = rednet.receive(nil, 0.075)
        if id == id_to_send then
            if protocol == "jjs_sg_lookup_return" then
                return msg
            else
                return {name="Unknown Address"}
            end
        end
    end
end

local function clearGate()
    if sg.isStargateConnected() or sg.getChevronsEngaged() > 0 then
        sg.closeChevron()
        if (0-sg.getCurrentSymbol()) % 39 < 19 then
            sg.rotateAntiClockwise(0)
        else
            sg.rotateClockwise(0)
        end

        repeat
            sleep()
        until sg.getCurrentSymbol() == 0

        sleep(0.25)
        sg.openChevron()
        sleep(0.25)
        sg.closeChevron()
    else
        if (0-sg.getCurrentSymbol()) % 39 < 19 then
            sg.rotateAntiClockwise(0)
        else
            sg.rotateClockwise(0)
        end
    end
end

local function inputThread()
    while true do
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.white)
        print("Address:")
        for k,v in ipairs(address) do
            term.setTextColor(colors.white)
            term.write("-")
            if v.dialed then
                term.setTextColor(colors.orange)
            elseif v.dialing then
                term.setTextColor(colors.lightGray)
            else
                term.setTextColor(colors.gray)
            end
            term.write(v.num)
        end
        term.setTextColor(colors.white)
        term.write("-")
        term.setTextColor(colors.lightGray)
        term.write(input_text)

        if monitor and config.monitor then
            monitor.setPaletteColor(colors.white, 0xFFDEAA)
            monitor.setPaletteColor(colors.black, 0x100500)
            monitor.setBackgroundColor(colors.black)
            local mw, mh = monitor.getSize()
            monitor.clear()
            monitor.setCursorPos(1,1)
            monitor.setTextColor(colors.white)
            monitor.write("Address:")
            monitor.setCursorPos(1,2)
            for k,v in ipairs(address) do
                monitor.setTextColor(colors.white)
                monitor.write("-")
                if v.dialed then
                    monitor.setTextColor(colors.orange)
                elseif v.dialing then
                    monitor.setTextColor(colors.lightGray)
                else
                    monitor.setTextColor(colors.gray)
                end
                monitor.write(v.num)
            end
            monitor.setTextColor(colors.white)
            monitor.write("-")
            monitor.setTextColor(colors.lightGray)
            monitor.write(input_text)
        end

        local event = {os.pullEvent()}

        if event[1] == "char" then
            if event[2]:match("%d") then
                input_text = input_text..event[2]
            end
        end
        if event[1] == "key" then
            if event[2] == keys.backspace then
                input_text = input_text:sub(1, #input_text-1)
                if #input_text == 0 then
                    input_text = tostring(address[#address].num)

                    table.remove(address, #address)
                    table.remove(display_address, #display_address)
                end
            elseif event[2] == keys.enter or event[2] == keys.numPadEnter then
                if #input_text > 0 then
                    address[#address+1] = {
                        num=tonumber(input_text),
                        dialed=false
                    }
                    display_address[#display_address+1] = tonumber(input_text)
                    input_text = ""
                end
                address[#address+1] = {
                    num=0,
                    dialed=false,
                    dialing=false
                }
                display_address[#display_address+1] = 0
                while true do
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.white)
                    print("Address:")
                    local display_text = ""
                    for k,v in ipairs(address) do
                        if v.num ~= 0 then
                            term.setTextColor(colors.white)
                            term.write("-")
                            display_text = display_text.."-"
                            if v.dialed then
                                term.setTextColor(colors.orange)
                            elseif v.dialing then
                                term.setTextColor(colors.lightGray)
                            else
                                term.setTextColor(colors.gray)
                            end
                            term.write(v.num)
                            display_text = display_text..v.num
                        elseif v.num == 0 and (v.dialing or v.dialed) then
                            term.setTextColor(colors.white)
                            term.write("-")
                            display_text = display_text.."-"
                            if v.dialed then
                                term.setTextColor(colors.yellow)
                            else
                                term.setTextColor(colors.red)
                            end
                            term.write(v.num)
                            display_text = display_text..v.num
                        end
                    end
                    term.setTextColor(colors.white)
                    term.write("-")
                    
                    if monitor and config.monitor then
                        local mw, mh = monitor.getSize()

                        monitor.setCursorPos(1,1)
                        monitor.clearLine()
                        monitor.setTextColor(colors.white)
                        monitor.write("Address:")
                        monitor.setCursorPos(1,2)
                        monitor.clearLine()

                        local display_text = ""
                        for k,v in ipairs(address) do
                            if v.num ~= 0 then
                                monitor.setTextColor(colors.white)
                                monitor.write("-")
                                display_text = display_text.."-"
                                if v.dialed then
                                    monitor.setTextColor(colors.orange)
                                elseif v.dialing then
                                    monitor.setTextColor(colors.lightGray)
                                else
                                    monitor.setTextColor(colors.gray)
                                end
                                monitor.write(v.num)
                                display_text = display_text..v.num
                                if config.address_book_id and k == #address then
                                    local address_to_lookup = {}
                                    for k, v in ipairs(address) do
                                        if v.num ~= 0 then
                                            address_to_lookup[k] = v.num
                                        end
                                    end
                                    local address_name = addressLookup(address_to_lookup)

                                    if address_name then
                                        local old_pos_x, old_pos_y = monitor.getCursorPos()
                                        monitor.setCursorPos(math.ceil(mw/2)-math.ceil(#(address_name.name)/2), mh)
                                        monitor.setTextColor(colors.orange)
                                        monitor.clearLine()
                                        monitor.write(address_name.name)
                                        monitor.setCursorPos(old_pos_x, old_pos_y)
                                    end
                                end
                            elseif v.num == 0 and (v.dialing or v.dialed) then
                                monitor.setTextColor(colors.white)
                                monitor.write("-")

                                monitor.setTextColor(colors.orange)
                                monitor.setCursorPos(1,3)
                                monitor.clearLine()
                                monitor.write("[["..string.rep(" ", mw-4).."]]")
                                local text = "!STAND BACK!"
                                monitor.setCursorPos(math.ceil(mw/2)-math.ceil(#text/2), 3)
                                monitor.setTextColor(colors.red)
                                monitor.clearLine()
                                monitor.write(text)

                                if config.address_book_id then
                                    local address_to_lookup = {}
                                    for k, v in ipairs(address) do
                                        if v.num ~= 0 then
                                            address_to_lookup[k] = v.num
                                        end
                                    end
                                    local address_name = addressLookup(address_to_lookup) or {name="Unknown Address"}

                                    local old_pos_x, old_pos_y = monitor.getCursorPos()
                                    monitor.setCursorPos(math.ceil(mw/2)-math.ceil(#(address_name.name)/2), mh)
                                    monitor.setTextColor(colors.yellow)
                                    monitor.clearLine()
                                    monitor.write(address_name.name)
                                    monitor.setCursorPos(old_pos_x, old_pos_y)
                                end
                            end
                        end
                        if not (address[#address].dialing or address[#address].dialed) then
                            monitor.setTextColor(colors.white)
                            monitor.write("-")    
                        end
                    end

                    if address[#address].dialed and sg.isStargateConnected() and sg.getOpenTime() > (20*1) then
                        if monitor and config.monitor then
                            local mw, mh = monitor.getSize()
                            monitor.setTextColor(colors.green)
                            monitor.setCursorPos(1,3)
                            monitor.write("[["..string.rep(" ", mw-4).."]]")
                            local text = "!READY!"
                            monitor.setCursorPos(math.ceil(mw/2)-math.ceil(#text/2), 3)
                            monitor.setTextColor(colors.lime)
                            monitor.write(text)
                        end

                        term.setTextColor(colors.orange)
                        term.setCursorPos(1,4)
                        term.write("Dialing Successful!")
                        term.setCursorPos(1,8)

                        repeat
                            local event = os.pullEvent()
                        until event == "stargate_disconnected" or event == "stargate_reset"

                        if monitor and config.monitor then
                            monitor.clear()
                        end

                        fancyReboot()
                        return
                    end
                    
                    sleep(0.5)
                end
            elseif event[2] == keys.space then
                address[#address+1] = {
                    num=tonumber(input_text),
                    dialed=false
                }
                display_address[#display_address+1] = tonumber(input_text)
                input_text = ""
            end
        end
    end
end

local function dialThread()
    while true do
        for k,v in ipairs(address) do
            if not v.dialed then
                address[k].dialing = true
                if (v.num-sg.getCurrentSymbol()) % 39 < 19 then
                    sg.rotateAntiClockwise(v.num)
                else
                    sg.rotateClockwise(v.num)
                end
                
                repeat
                    sleep()
                until sg.getCurrentSymbol() == v.num
                sleep(0.25)
                sg.openChevron()
                sleep(0.25)
                sg.closeChevron()
                address[k].dialing = false
                address[k].dialed = true
            end
            sleep(0.25)
        end
        sleep()
    end
end

local function autoInputThread()
    sleep(1)
    for k,v in ipairs(auto_address_call) do
        local symbol_string = tostring(v)
        for i1=1, #symbol_string do
            os.queueEvent("char", tostring(symbol_string:sub(i1,i1)))
            os.sleep(0.125)
        end
        os.sleep(0.25)
        os.queueEvent("key", keys.space, false)
    end
    os.queueEvent("key", keys.enter, false)
    repeat 
        sleep()
    until sg.isStargateConnected()
end

local dial_book = {
    {name="Earth", address={31,21,11,1,16,14,18,12}},
    {name="Abydos", address={26,6,14,31,11,29}},
    {name="Chulak", address={8,1,22,14,36,19}}
}

if sg.getChevronsEngaged() > 0 and not sg.isStargateConnected() then
    sg.closeChevron()
    sg.disconnectStargate()
    if (0-sg.getCurrentSymbol()) % 39 < 19 then
        sg.rotateAntiClockwise(0)
    else
        sg.rotateClockwise(0)
    end
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function mainThread()
    local w, h = term.getSize()

    term.clear()
    term.setCursorPos(1,1)
    print("Select Mode:")
    print("1. Manual Dial")
    print("2. Dial Book")
    print("3. Clipboard")
    print("4. Exit")
    print("5. Set Label")
    print("6. Set Energy Target")
    print("7. Toggle Monitor ("..tostring(config.monitor)..")")
    print("8. Set Addressbook ID ("..tostring(config.address_book_id)..")")

    write(3, h, "Label: "..config.label, colors.black, colors.yellow)

    term.setCursorPos(1,h)
    local mode = tonumber(wait_for_key("%d"))

    if is_dialing then
        return
    end

    if mode == 1 then
        clearGate()
        parallel.waitForAny(inputThread, dialThread)
        is_dialing = true
    elseif mode == 2 then
        term.clear()
        term.setCursorPos(1,1)
        print("Select Destination:")
        for k,v in ipairs(dial_book) do
            print(k..". "..v.name)
        end
        
        term.setCursorPos(1,h)
        local selected = tonumber(wait_for_key("%d"))

        if dial_book[selected] then
            is_dialing = true
            auto_address_call = dial_book[selected].address
            clearGate()
            parallel.waitForAll(inputThread, dialThread, autoInputThread)
        end
    elseif mode == 3 then
        term.clear()
        term.setCursorPos(1,1)
        print("Waiting for Clipboard (Press CTRL+V)")
        local name, clipboard = os.pullEvent("paste")

        local temp_address = split(clipboard, "-")
        auto_address_call = {}

        for k,v in ipairs(temp_address) do
            if tonumber(v) then
                auto_address_call[#auto_address_call+1] = tonumber(v)
                print(tonumber(v))
            end
        end
        
        is_dialing = true
        clearGate()
        parallel.waitForAll(inputThread, dialThread, autoInputThread)
    elseif mode == 4 then
        term.clear()
        term.setCursorPos(1,1)
        return
    elseif mode == 5 then
        term.clear()
        term.setCursorPos(1,1)
        print("New Label:")
        local new_label = read(nil, nil, nil, config.label)
        config.label = new_label
        writeConfig()
        fancyReboot()
        return
    elseif mode == 6 then
        term.clear()
        term.setCursorPos(1,1)
        print("New Energy Target:")
        local new_target = tonumber(read(nil, nil, nil, tostring(sg.getEnergyTarget())))
        sg.setEnergyTarget(new_target or sg.getEnergyTarget())
        fancyReboot()
        return
    elseif mode == 7 then
        term.clear()
        term.setCursorPos(1,1)
        config.monitor = (not config.monitor)
        print("Set to: "..tostring(config.monitor))
        sleep(1)
        writeConfig()
        fancyReboot()
        return
    elseif mode == 8 then
        term.clear()
        term.setCursorPos(1,1)
        local list_of_books = {rednet.lookup("jjs_sg_addressbook")}
        
        for k,v in pairs(list_of_books) do
            list_of_books[k] = tostring(v)
        end
        print("Address Book ID:")
        local new_address_book = read(nil, nil, function(text) return completion.choice(text, list_of_books) end, config.address_book_id)
        if tonumber(new_address_book) then
            config.address_book_id = tonumber(new_address_book)
            writeConfig()
        end
        fancyReboot()
        return
    end
end

local function mainRemote()
    while true do
        local id, msg, protocol = rednet.receive()

        if is_dialing then
            return
        end

        if protocol == "jjs_sg_startdial" then
            local temp_address = split(msg, "-")
            auto_address_call = {}

            for k,v in ipairs(temp_address) do
                if tonumber(v) then
                    auto_address_call[#auto_address_call+1] = tonumber(v)
                    print(tonumber(v))
                end
            end
            
            clearGate()
            is_dialing = true
            parallel.waitForAll(inputThread, dialThread, autoInputThread)
        elseif protocol == "jjs_sg_getlabel" then
            rednet.send(id, config.label, "jjs_sg_sendlabel")
        end
    end
end

local function mainFailsafe()
    while true do
        local event, code = os.pullEvent()
        if event == "stargate_reset" and code < 0 then
            fancyReboot()
            return
        end
    end
end

local function mainRemoteCommands()
    while true do
        local id, msg, protocol = rednet.receive()
        if protocol == "jjs_sg_disconnect" then
            clearGate()
            fancyReboot()
        elseif protocol == "jjs_sg_getlabel" then
            rednet.send(id, config.label, "jjs_sg_sendlabel")
        end
    end
end

local function mainRemoteDistance()
    while true do
        local event, side, channel, reply_channel, message, distance = os.pullEvent("modem_message")
        if type(message) == "table" then
            if message.protocol == "jjs_sg_dialer_ping" and message.message == "request_ping" then
                modem.transmit(reply_channel, 2707, {protocol="jjs_sg_dialer_ping", message="response_ping", id=os.getComputerID(), label=config.label})
            end
        end
    end
end

local screensaver_text = "  Stargate Idle  "
local screensaver_color = colors.gray

local function screenSaverMonitor()
    if monitor and config.monitor then
        local width, height = monitor.getSize()
        local scroll = 0
        monitor.setPaletteColor(colors.gray, 0x222222)
        while true do
            if is_dialing then
                break
            end
            local old_x, old_y = monitor.getCursorPos()
            
            monitor.setCursorPos(1-(#screensaver_text) + scroll, 2)
            monitor.clearLine()
            monitor.setTextColor(screensaver_color)
            monitor.write(string.rep(screensaver_text.."-", math.ceil(width/#screensaver_text)+2))

            monitor.setCursorPos(1-(#screensaver_text) - scroll, 4)
            monitor.clearLine()
            monitor.setTextColor(screensaver_color)
            monitor.write(string.rep(screensaver_text.."-", math.ceil(width/#screensaver_text)+2))

            monitor.setCursorPos(old_x, old_y)
            scroll = scroll+1
            if scroll > #screensaver_text then
                scroll = 0
            end
            sleep(0.5)
        end
        monitor.setPaletteColor(colors.gray, term.nativePaletteColor(colors.gray))
    end
end

local function gateIncomingMonitor()
    if monitor and config.monitor then
        local width, height = monitor.getSize()
        while true do
            local old_x, old_y = monitor.getCursorPos()
            local event = {os.pullEvent("stargate_incoming_wormhole")}

            local monitor_text = ""
            screensaver_text = "  Incoming Wormhole  "
            screensaver_color = colors.orange
            if event[2] then
                local address_incoming = addressLookup(event[2])
                if address_incoming then
                    monitor_text = address_incoming.name
                else
                    monitor_text = table.concat(event[2], "-")
                end
                monitor.setCursorPos(math.ceil(width/2)-math.ceil(#monitor_text/2), 3)
                monitor.clearLine()
                monitor.setTextColor(colors.yellow)
                monitor.write(monitor_text)
            end
            monitor.setCursorPos(old_x, old_y)
        end
    end
end

local function gateClosingMonitor()
    if monitor and config.monitor then
        local width, height = monitor.getSize()
        while true do
            local old_x, old_y = monitor.getCursorPos()
            local event = {os.pullEvent("stargate_disconnected")}

            local monitor_text = ""
            screensaver_text = "  Stargate Idle  "
            screensaver_color = colors.gray
            monitor.setCursorPos(1, 3)
            monitor.clearLine()
            monitor.setCursorPos(old_x, old_y)
        end
    end
end

if sg.isStargateConnected() and not sg.isStargateDialingOut() then
    if sg.getConnectedAddress then
        os.queueEvent("stargate_incoming_wormhole", sg.getConnectedAddress())
    else
        os.queueEvent("stargate_incoming_wormhole", nil)
    end
end

local stat, err = pcall(function()
    parallel.waitForAll(mainThread, mainRemote, mainFailsafe, mainRemoteCommands, mainRemoteDistance, screenSaverMonitor, gateIncomingMonitor, gateClosingMonitor)
end)

if not stat then
    if err == "Terminated" then
        fancyReboot()
    else
        error(err)
    end
end
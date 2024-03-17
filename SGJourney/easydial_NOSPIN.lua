local sg = peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local address = {}
local display_address = {}

local input_text = ""

local auto_address_call = {}

local monitor = peripheral.find("monitor")
if monitor then
    local mw, mh = monitor.getSize()
    monitor.setTextScale(1)
    monitor.clear()
    monitor.setPaletteColor(colors.white, 0xFFFFFF)
    monitor.setPaletteColor(colors.black, 0x000000)
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

local function clearGate()
    if sg.isStargateConnected() then
        sg.engageSymbol(0)
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

        if monitor then
            monitor.setPaletteColor(colors.white, 0xFFDEAA)
            monitor.setPaletteColor(colors.black, 0x100500)
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
                    
                    if monitor then
                        local mw, mh = monitor.getSize()

                        monitor.clear()
                        monitor.setCursorPos(1,1)
                        monitor.setTextColor(colors.white)
                        monitor.write("Address:")
                        monitor.setCursorPos(1,2)

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
                            elseif v.num == 0 and (v.dialing or v.dialed) then
                                monitor.setTextColor(colors.white)
                                monitor.write("-")

                                monitor.setTextColor(colors.orange)
                                monitor.setCursorPos(1,3)
                                monitor.write("[["..string.rep(" ", mw-4).."]]")
                                local text = "!STAND BACK!"
                                monitor.setCursorPos(math.ceil(mw/2)-math.ceil(#text/2), 3)
                                monitor.setTextColor(colors.red)
                                monitor.write(text)
                            end
                        end
                        if not (address[#address].dialing or address[#address].dialed) then
                            monitor.setTextColor(colors.white)
                            monitor.write("-")    
                        end
                    end

                    if address[#address].dialed and sg.isStargateConnected() and sg.getOpenTime() > (20*1) then
                        if monitor then
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

                        if monitor then
                            monitor.clear()
                        end

                        os.reboot()
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
                
                sg.engageSymbol(v.num)

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
    until sg.isStargateConnected() or sg.getRecentFeedback() < 0
end

local dial_book = {
    {name="Earth", address={31,21,11,1,16,14,18,12}},
    {name="Abydos", address={26,6,14,31,11,29}},
    {name="Chulak", address={8,1,22,14,36,19}}
}

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local stat, err = pcall(function()
    local w, h = term.getSize()

    term.clear()
    term.setCursorPos(1,1)
    print("Select Mode:")
    print("1. Manual Dial")
    print("2. Dial Book")
    print("3. Clipboard")
    print("4. Exit")

    term.setCursorPos(1,h)
    local mode = tonumber(wait_for_key("%d"))

    if mode == 1 then
        clearGate()
        parallel.waitForAny(inputThread, dialThread)
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
        
        clearGate()
        parallel.waitForAll(inputThread, dialThread, autoInputThread)
    elseif mode == 4 then
        term.clear()
        term.setCursorPos(1,1)
        return
    end
end)

if not stat then
    if err == "Terminated" then
        os.reboot()
    else
        error(err)
    end
end
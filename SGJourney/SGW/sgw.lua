local config = {}

local function loadConfig()
    if fs.exists("config_sgw.txt") then
        local file = io.open("config_sgw.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open("config_sgw.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()

if not config.url then
    print("Enter Websocket (host:port) :")
    local url = read()
    config.url = url
    writeConfig()
end

local monitor = peripheral.find("monitor")

local websocket, err = http.websocket("ws://"..config.url)

if not websocket then
    error("Connection to websocket failed! Reason: \n"..err)
else
    print("Successfully Connected to websocket!")
end

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

if not interface.rotateClockwise then
    error("Gate needs to be MilkyWay (or be able to rotate)")
end

local command_queue = {}

local function websocketThread()
    while true do
        local msg = websocket.receive()
        command_queue[#command_queue+1] = {message=msg}
    end
end

local gate_target_symbol = interface.getCurrentSymbol()
local update_timer = 0
local has_updated = false

local awaiting_encode = false

local monitor_mode = false
if monitor then
    monitor_mode = true
end

local symbol_encode_queue = {}

local function gateControlThread()
    while true do
        local cmd = command_queue[1]
        if cmd then
            local message = cmd.message
            if message == "left" then
                local current_symbol = interface.getCurrentSymbol()
                if monitor_mode then
                    gate_target_symbol = (gate_target_symbol-1)%39
                else
                    gate_target_symbol = (gate_target_symbol+1)%39
                end
                update_timer = 10
                has_updated = false
            elseif message == "right" then
                local current_symbol = interface.getCurrentSymbol()
                if monitor_mode then
                    gate_target_symbol = (gate_target_symbol+1)%39
                else
                    gate_target_symbol = (gate_target_symbol-1)%39
                end
                update_timer = 10
                has_updated = false
            elseif message == "click" then
                if interface.getCurrentSymbol() == gate_target_symbol then
                    interface.openChevron()
                    sleep(0.25)
                    interface.encodeChevron()
                    sleep(0.25)
                    interface.closeChevron()
                else
                    awaiting_encode = true
                end
            elseif tonumber(message) then
                symbol_encode_queue[#symbol_encode_queue+1] = tonumber(message)
            end
            print(message)
            print("New Target: "..gate_target_symbol)
            table.remove(command_queue, 1)
        end
        if update_timer > 0 then
            update_timer = update_timer-1
        end
        if update_timer <= 0 and not has_updated then
            os.queueEvent("rotate_target")
            has_updated = true
        end
        sleep()
    end
end

local function gateRotationThread()
    while true do
        os.pullEvent("rotate_target")

        if (gate_target_symbol-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(gate_target_symbol)
        else
            interface.rotateClockwise(gate_target_symbol)
        end
    end
end

local function delayedEncodeThread()
    while true do
        if awaiting_encode then
            repeat
                sleep(0.25)
            until interface.getCurrentSymbol() == gate_target_symbol
            awaiting_encode = false
            sleep(0.5)
            interface.openChevron()
            sleep(0.25)
            interface.encodeChevron()
            sleep(0.25)
            interface.closeChevron()
        end
        sleep()
    end
end

local function encodeQueueThread()
    while true do
        local to_encode = symbol_encode_queue[1]
        if to_encode then
            if interface.engageSymbol then
                interface.engageSymbol(to_encode)
                sleep(0.25)
            elseif interface.rotateClockwise then
                if interface.isChevronOpen(to_encode) then
                    interface.closeChevron()
                end
        
                if (to_encode-interface.getCurrentSymbol()) % 39 < 19 then
                    interface.rotateAntiClockwise(to_encode)
                else
                    interface.rotateClockwise(to_encode)
                end
                
                repeat
                    sleep(0.1)
                until interface.getCurrentSymbol() == to_encode
        
                sleep(0.1)
                interface.openChevron()
                sleep(0.1)
                interface.encodeChevron()
                sleep(0.1)
                interface.closeChevron()
            else
                print("Couldn't dial number!")
            end
            table.remove(symbol_encode_queue, 1)
        end
        sleep()
    end
end

local function monitorManager()
    while true do
        if monitor then
            monitor.setTextScale(4.5)
            monitor.clear()
            monitor.setCursorPos(1,1)
            if interface.getCurrentSymbol() == gate_target_symbol then
                if monitor_mode then
                    monitor.setTextColor(colors.lime)
                else
                    monitor.setTextColor(colors.green)
                end
            else
                if monitor_mode then
                    monitor.setTextColor(colors.white)
                else
                    monitor.setTextColor(colors.lightGray)
                end
            end
            monitor.setBackgroundColor(colors.black)
            monitor.write(tostring(gate_target_symbol))
            sleep()
        else
            monitor = peripheral.find("monitor")
            sleep(2)
        end
    end
end

local function monitorTouchThread()
    while true do
        os.pullEvent("monitor_touch")
        monitor_mode = not monitor_mode
        print("Monitor Mode: "..tostring(monitor_mode))
    end
end

parallel.waitForAll(websocketThread, gateControlThread, gateRotationThread, monitorManager, delayedEncodeThread, monitorTouchThread, encodeQueueThread)
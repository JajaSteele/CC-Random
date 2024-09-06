local target_stargate = {32,28,19,6,3,29,27,16}
local monitor = peripheral.wrap("top")

local function getCenter(text, width)
    return math.ceil(width/2)-math.floor(#text/2)
end

local function displayOnMonitorTimed(text, color, time)
    if monitor then
        local width, height = monitor.getSize()
    
        monitor.clear()
        monitor.setCursorPos(getCenter(text, width), 3)
        monitor.setTextColor(color)
        monitor.write(text)
        sleep(time)
    end
end
displayOnMonitorTimed("Program Starting", colors.green, 1)

local program_path = shell.getRunningProgram()
local program_link = "https://raw.githubusercontent.com/JajaSteele/CC-Random/main/SGJourney/museum_program.lua"

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local startup_program_pcall = ([[
    while true do
        local stat, err = pcall(function()
            print("Starting Program '&p' in ]]..(0.5)..[[s")
            sleep(]]..(0.5)..[[)
            if not shell.execute("&p") then
                error("Program Errored")
            end
        end)
        if not stat then 
            if err == "Terminated" then 
                print("Program Terminated") break 
            end 
            print(err) 
            print("Restarting in ]]..(1)..[[s") 
            sleep(]]..(1)..[[) 
        end
    end
]])
local args = {...}

if args[1] ~= "l" then
    local request = http.get(program_link)
    if request then
        local new_program = request.readAll()
        request:close()
        local current_program_file = io.open(program_path, "r")
        if current_program_file then
            local current_program = current_program_file:read("*a")
            current_program_file:close()

            if new_program ~= current_program then
                local new_program_file = io.open(program_path, "w")
                if not new_program_file then
                    new_program_file = io.open("/museum_program.lua", "w")
                    program_path = "/museum_program.lua"
                    if not new_program_file then
                        print("Unable to write program file!")
                        return
                    end
                end
                new_program_file:write(new_program)
                print("Auto-Updated program!")
                print("Refreshing startup program..")
                displayOnMonitorTimed("Update Success", colors.lime, 1)
                local startup_file = io.open("/startup.lua", "w")
                local startup_data = startup_program_pcall:gsub("&p", program_path)
                startup_file:write(startup_data)
                sleep(0.2)
                print("Rebooting..")
                sleep(1)
                os.reboot()
            else
                print("online file equals local file, updating cancelled")
                displayOnMonitorTimed("Update Cancel", colors.yellow, 1)
                sleep(0.5)
            end
        else
            local new_program_file = io.open(program_path, "w")
            new_program_file:write(new_program)
            print("Auto-Downloaded program!")
            displayOnMonitorTimed("Download Success", colors.lime, 1)
            print("Rebooting..")
            sleep(1)
            os.reboot()
        end
    else
        print("Failed to request file, updating cancelled")
        displayOnMonitorTimed("Update Fail", colors.red, 1)
        sleep(0.5)
    end
else
    print("Updated Disabled via arguments")
    displayOnMonitorTimed("Update Disabled", colors.red, 1)
end

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local stop_dial = false

local function engageAddress(address)
    if interface.engageSymbol and not interface.rotateClockwise then
        for k,v in ipairs(address) do
            if stop_dial then
                break
            end
            interface.engageSymbol(v)
            sleep(0.25)
        end
        interface.engageSymbol(0)
    elseif interface.engageSymbol and interface.rotateClockwise then
        if (0-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(0)
        else
            interface.rotateClockwise(0)
        end
        repeat
            sleep()
        until interface.getCurrentSymbol() == 0
        interface.rotateAntiClockwise(-1)


        for k,v in ipairs(address) do
            if stop_dial then
                break
            end
            repeat
                sleep()
            until ((interface.getCurrentSymbol()/38)*(#address+1)) >= k
            interface.engageSymbol(v)
            os.sleep(0.25)
        end


        repeat
            local symbol = interface.getCurrentSymbol()
            sleep()
        until symbol == 0

        interface.endRotation()
        sleep(0.125)

        if (0-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(0)
        else
            interface.rotateClockwise(0)
        end

        sleep(0.125)

        if (0-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(0)
        else
            interface.rotateClockwise(0)
        end

        repeat
            local symbol = interface.getCurrentSymbol()
            sleep(0.125)
        until symbol == 0
        sleep(0.25)
        interface.openChevron()
        sleep(0.25)
        interface.encodeChevron()
        sleep(0.25)
        interface.closeChevron()
    elseif interface.rotateClockwise then
        for k,number in ipairs(address) do
            if stop_dial then
                break
            end
            if interface.isChevronOpen(number) then
                interface.closeChevron()
            end

            if (number-interface.getCurrentSymbol()) % 39 < 19 then
                interface.rotateAntiClockwise(number)
            else
                interface.rotateClockwise(number)
            end
            
            repeat
                sleep(0)
            until interface.getCurrentSymbol() == number

            
            interface.openChevron()
            sleep(0.25)
            interface.encodeChevron()
            sleep(0.25)
            interface.closeChevron()
        end

        if interface.isChevronOpen(0) then
            interface.closeChevron()
        end

        if (0-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(0)
        else
            interface.rotateClockwise(0)
        end
        
        repeat
            sleep(0)
        until interface.getCurrentSymbol() == 0

        
        interface.openChevron()
        sleep(0.25)
        interface.encodeChevron()
        sleep(0.25)
        interface.closeChevron()
    else
        print("Couldn't dial number!")
    end
end

local side_list = {
    "back",
    "front",
    "top",
    "bottom",
    "left",
    "right"
}

if monitor then
    local width, height = monitor.getSize()
    local gate_type = interface.getStargateType()
    gate_type = gate_type:match(".+:(.+)")
    gate_type = gate_type:gsub("_", " ")
    local gate_type_fancy = {}  
    for k,word in ipairs(split(gate_type, " ")) do
        if not word:match("stargate") then
            local new_word = word:sub(1,1):upper()..word:sub(2, #word)
            gate_type_fancy[#gate_type_fancy+1] = new_word
        end
    end
    gate_type = table.concat(gate_type_fancy, " ")
    local gate_variant = interface.getStargateVariant()
    if gate_variant == "sgjourney:empty" then
        gate_variant = "Default Variant"
    end

    monitor.clear()
    monitor.setCursorPos(getCenter(gate_type, width), 2)
    monitor.setTextColor(colors.green)
    monitor.write(gate_type)
    monitor.setCursorPos(getCenter(gate_variant, width), 4)
    monitor.setTextColor(colors.blue)
    monitor.write(gate_variant)
end

local function redstoneThread()
    local redstone_status = false
    while true do
        os.pullEvent("redstone")
        local new_status = false
        for k,side in pairs(side_list) do
            local signal = redstone.getInput(side)
            if signal then
                new_status = true
                break
            end
        end

        if redstone_status == false and new_status == true then
            os.queueEvent("redstone_update", true)
        elseif redstone_status == true and new_status == false then
            os.queueEvent("redstone_update", false)
        end
        redstone_status = new_status
    end
end

local function cancelThread()
    while true do
        local event = {os.pullEvent()}
        local signal
        if event[1] == "redstone_signal" then
            signal = event[2]
        elseif event[1] == "monitor_touch" and event[2] == "top" then
            signal = true
        end
        if signal == true then
            print("Cancelling Dial")
            stop_dial = true
            interface.disconnectStargate()
            if interface.rotateClockwise then
                if (0-interface.getCurrentSymbol()) % 39 < 19 then
                    interface.rotateAntiClockwise(0)
                else
                    interface.rotateClockwise(0)
                end
                
                repeat
                    sleep(0)
                until interface.getCurrentSymbol() == 0
            end
            interface.disconnectStargate()
            return
        end
    end
end

local function mainThread()
    while true do
        local event = {os.pullEvent()}
        local signal
        if event[1] == "redstone_signal" then
            signal = event[2]
        elseif event[1] == "monitor_touch" and event[2] == "top" then
            signal = true
        end
        if signal == true then
            if interface.isStargateConnected() or interface.getChevronsEngaged() > 0 then
                print("Disconnecting Gate")
                interface.disconnectStargate()
                if interface.rotateClockwise then
                    if (0-interface.getCurrentSymbol()) % 39 < 19 then
                        interface.rotateAntiClockwise(0)
                    else
                        interface.rotateClockwise(0)
                    end
                    
                    repeat
                        sleep(0)
                    until interface.getCurrentSymbol() == 0
                end
            else
                print("Dialing Address")
                stop_dial = false
                parallel.waitForAny((function() 
                    engageAddress(target_stargate)
                end), cancelThread)
            end
        end
    end
end

if interface then
    if interface.rotateClockwise then
        if interface.isChevronOpen(0) then
            interface.closeChevron()
        end

        if (0-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(0)
        else
            interface.rotateClockwise(0)
        end
        
        repeat
            sleep(0)
        until interface.getCurrentSymbol() == 0
        
        if interface.engageSymbol then
            interface.disconnectStargate()
        else
            interface.openChevron()
            sleep(0.25)
            interface.encodeChevron()
            sleep(0.25)
            interface.closeChevron()
        end
    end
end

parallel.waitForAny(redstoneThread, mainThread)
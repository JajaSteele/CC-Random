local target_stargate = {32,28,19,6,3,29,27,16}

local program_path = shell.getRunningProgram()
local program_link = "https://raw.githubusercontent.com/JajaSteele/CC-Random/main/SGJourney/museum_program.lua"

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
                if not new_program_file then
                    print("Unable to write program file!")
                    return
                end
            end
            new_program_file:write(new_program)
            print("Auto-Updated program!")
            print("Rebooting..")
            sleep(2)
            os.reboot()
        else
            print("online file equals local file, updating cancelled")
            sleep(0.5)
        end
    else
        local new_program_file = io.open(program_path, "w")
        new_program_file:write(new_program)
        print("Auto-Downloaded program!")
        print("Rebooting..")
        sleep(2)
        os.reboot()
    end
else
    print("Failed to request file, updating cancelled")
    sleep(0.5)
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

local startup_file = io.open("/startup.lua", "w")
local startup_data = startup_program_pcall:gsub("&p", program_path)
startup_file:write(startup_data)

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local function engageAddress(address)
    if interface.engageSymbol and not interface.rotateClockwise then
        for k,v in ipairs(address) do
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

local function mainThread()
    while true do
        local event, signal = os.pullEvent("redstone_update")
        if signal == true then
            if interface.isStargateConnected() or interface.getChevronsEngaged() > 0 then
                interface.disconnectStargate()
            else
                engageAddress(target_stargate)
            end
        end
    end
end

parallel.waitForAny(redstoneThread, mainThread)
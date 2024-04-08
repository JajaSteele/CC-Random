local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local last_address = {}

local function loadSave()
    if fs.exists("last_address.txt") then
        local file = io.open("last_address.txt", "r")
        last_address = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open("last_address.txt", "w")
    file:write(textutils.serialise(last_address))
    file:close()
end

loadSave()

local config = {}

local function writeConfig()
    local file = io.open("last_address_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

local function loadConfig()
    if fs.exists("last_address_config.txt") then
        local file = io.open("last_address_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    else
        print("Select a mode (Crystal Interface only!):")
        print("1 = Fast")
        print("2 = Fancy-Quick (MW Only)")
        config.mode = tonumber(read())
        writeConfig()
    end
end

loadConfig()

local start_dialing = false
local to_dial = {}

local function lastAddressSaverThread()
    while true do
        local event = {os.pullEvent()}
        if (event[1] == "stargate_incoming_wormhole" and (event[2] and event[2] ~= {})) or (event[1] == "stargate_outgoing_wormhole") then
            last_address = event[2]
            writeSave()
            print("Set last address to: "..table.concat(event[2], " "))
        end
    end
end

local function rsThread()
    while true do
        os.pullEvent("redstone")
        for k,v in pairs(rs.getSides()) do
            if rs.getInput(v) then
                print("Received redstone signal")
                if interface.isStargateConnected() then
                    interface.disconnectStargate()
                    print("Disconnected the stargate")
                    break
                else
                    to_dial = last_address
                    start_dialing = true
                    break
                end
            end
        end
    end
end

local function dialThread()
    while true do
        if start_dialing then

            if interface.getChevronsEngaged() > 0 then
                interface.disconnectStargate()
                print("Cleared the stargate's chevrons")
            end

            print("Dialing: "..table.concat(to_dial, " "))

            if interface.closeChevron then
                interface.closeChevron()
            end

            if interface.engageSymbol and config.mode == 2 then
                if (0-interface.getCurrentSymbol()) % 39 < 19 then
                    interface.rotateAntiClockwise(0)
                else
                    interface.rotateClockwise(0)
                end
                repeat
                    sleep()
                until interface.getCurrentSymbol() == 0

                interface.rotateAntiClockwise(-1)
            end

            for k,v in ipairs(to_dial) do
                if interface.engageSymbol then
                    if config.mode == 2 then
                        repeat
                            sleep()
                        until ((interface.getCurrentSymbol()/38)*(#to_dial+1)) >= k
                        interface.engageSymbol(v)
                        os.sleep(0.25)
                    else
                        interface.engageSymbol(v)
                        os.sleep(0.125)
                    end
                elseif interface.rotateClockwise then
                    if (v-interface.getCurrentSymbol()) % 39 < 19 then
                        interface.rotateAntiClockwise(v)
                    else
                        interface.rotateClockwise(v)
                    end

                    repeat
                        sleep()
                    until interface.isCurrentSymbol(v)

                    interface.openChevron()
                    sleep(0.125)
                    interface.closeChevron()
                end
            end

            if interface.engageSymbol and config.mode == 2 then
                repeat
                    local symbol = interface.getCurrentSymbol()
                    sleep()
                until symbol == 0

                sleep(0.25)

                if (0-interface.getCurrentSymbol()) % 39 < 19 then
                    interface.rotateAntiClockwise(0)
                else
                    interface.rotateClockwise(0)
                end

                sleep(0.25)

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
                sleep(0.75)
                interface.closeChevron()
            elseif interface.engageSymbol and config.mode == 1 then
                interface.engageSymbol(0)
            else
                if (0-interface.getCurrentSymbol()) % 39 < 19 then
                    interface.rotateAntiClockwise(0)
                else
                    interface.rotateClockwise(0)
                end

                repeat
                    sleep(0.125)
                until interface.isCurrentSymbol(0)

                interface.openChevron()
                sleep(0.35)
                interface.closeChevron()
            end
            
            start_dialing = false
        end
        sleep(0.5)
    end
end

if interface.isStargateConnected() and interface.getConnectedAddress then
    last_address = interface.getConnectedAddress()
    writeSave()
    print("Set last address to: "..table.concat(interface.getConnectedAddress(), " "))
end

parallel.waitForAll(lastAddressSaverThread, rsThread, dialThread)
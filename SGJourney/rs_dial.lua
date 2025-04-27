local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local function engageChevron(number)
    if interface.engageSymbol and not (interface.rotateClockwise and settings.get("sg.slowdial")) then
        interface.engageSymbol(number, not settings.get("sg.slowdial"))
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
        sleep(0)
        interface.closeChevron()
    else
        print("Couldn't dial number!")
    end
end

local config = {}

local function loadConfig()
    if fs.exists("/rs_dial_config.txt") then
        local file = io.open("/rs_dial_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open("/rs_dial_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()

local side_list = {
    "back",
    "front",
    "top",
    "bottom",
    "left",
    "right"
}

if config.addresses == nil or ({...})[1] == "config" then
    config.addresses = {}
    print("For each side, enter either:")
    print("* An address (-1-2-3- format)")
    print("* 'disconnect' to close the gate on signal")
    print("* Or simply nothing to disable that side")
    print("")
    for k,side in ipairs(side_list) do
        print("Side: "..side)
        local address = {}
        local temp_addr1 = read()
        if temp_addr1 == "disconnect" then
            config.addresses[side] = "disconnect"
        else
            local temp_addr2 = split(temp_addr1, "-")
            for k,v in ipairs(temp_addr2) do
                if tonumber(v) then
                    address[#address+1] = tonumber(v)
                end
            end
            if #address > 0 then
                config.addresses[side] = address
            end
        end
        print("")
    end
    writeConfig()
end

local redstone_status = {}
for k,side in pairs(side_list) do
    redstone_status[side] = redstone.getInput(side)
end
local function redstoneThread()
    while true do
        os.pullEvent("redstone")
        local on_list = {}
        for k,side in pairs(side_list) do
            if redstone.getInput(side) and not redstone_status[side] then
                on_list[#on_list+1] = side
            end
        end

        if #on_list > 0 then
            os.queueEvent("redstone_on", on_list)
        end
    end
end

local function executionThread()
    while true do
        local event, sides = os.pullEvent("redstone_on")
        pcall(function()
            for k, side in pairs(sides) do
                local address = config.addresses[side]
                if type(address) == "table" then
                    print("Dialing:")
                    print(table.concat(address, "-"))
                    if interface.isStargateConnected() or interface.getChevronsEngaged() > 0 then
                        interface.disconnectStargate()
                    end
                    for k,symbol in ipairs(address) do
                        engageChevron(symbol)
                        sleep(0.25)
                    end
                    engageChevron(0)
                    return
                elseif type(address) == "string" then
                    if address == "disconnect" then
                        print("Disconnecting")
                        if interface.isStargateConnected() or interface.getChevronsEngaged() > 0 then
                            interface.disconnectStargate()
                        end
                        return
                    end
                end
            end
        end)
    end
end

while true do
    print("Starting Threads")
    local stat, err = pcall(function()
        parallel.waitForAll(executionThread, redstoneThread)
    end)

    if not stat then
        if err == "Terminated" then
            print("Terminating Program")
            break
        else
            print("ERROR:")
            print(err)
        end
    end
    sleep(1)
end
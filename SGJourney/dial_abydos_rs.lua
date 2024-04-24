local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

if not fs.exists("/startup.lua") then
    local startup = io.open("/startup.lua", "w")
    startup:write([[shell.run("dial_abydos_rs.lua")]])
    startup:close()
end

local address_to_dial = {26,6,14,31,11,29,0}

local function redstoneThread()
    while true do
        os.pullEvent("redstone")

        if rs.getInput("front") then
            print("Dialing")
            if interface.isStargateConnected() then
                interface.disconnectStargate()
            end
            if interface.getChevronsEngaged() > 0 then
                interface.disconnectStargate()
            end
            for k,v in ipairs(address_to_dial) do
                interface.engageSymbol(v)
                sleep(0.35)
            end
        end
    end
end

local function disconnectThread()
    while true do
        local stat, err = pcall(function()
            while true do
                if interface.isStargateConnected() and interface.getOpenTime() > (20*3) then
                    interface.disconnectStargate()
                    print("Disconnected")
                end
                sleep(0.1)
            end
        end)
        if not stat then print(err) end
    end
end

parallel.waitForAll(redstoneThread, disconnectThread)
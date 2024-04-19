local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

if not fs.exists("/startup.lua") then
    local startup = io.open("/startup.lua", "w")
    startup:write([[shell.run("test_the_gate.lua")]])
    startup:close()
end

local address_to_dial = {32, 28, 19, 6, 3, 29, 27, 16, 0}

while true do
    os.pullEvent("redstone")

    if rs.getInput("top") then
        if interface.isStargateConnected() then
            interface.disconnectStargate()
        else
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

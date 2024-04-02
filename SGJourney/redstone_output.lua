local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local completion = require "cc.completion"

local config = {}

if fs.exists("cfg_rs_sg.txt") then
    local cfg_file = io.open("cfg_rs_sg.txt","r")
    config = textutils.unserialise(cfg_file:read("*a"))
    cfg_file:close()
else
    print("Starting Config!")
    print("Outgoing Side?")
    config.outgoing = read(nil, nil, completion.side)

    print("Incoming Side?")
    config.incoming = read(nil, nil, completion.side)

    print("Idle Side?")
    config.idle = read(nil, nil, completion.side)

    local cfg_file = io.open("cfg_rs_sg.txt","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

if interface.isStargateConnected() then
    if interface.isStargateDialingOut() then
        rs.setOutput(config.outgoing, true)
        rs.setOutput(config.incoming, false)
        rs.setOutput(config.idle, false)
        print("New State: outgoing")
    else
        rs.setOutput(config.incoming, true)
        rs.setOutput(config.outgoing, false)
        rs.setOutput(config.idle, false)
        print("New State: incoming")
    end
else
    rs.setOutput(config.idle, true)
    rs.setOutput(config.outgoing, false)
    rs.setOutput(config.incoming, false)
    print("New State: idle")
end

while true do
    local event = {os.pullEvent()}

    if event[1] == "stargate_incoming_wormhole" then
        rs.setOutput(config.incoming, true)
        rs.setOutput(config.outgoing, false)
        rs.setOutput(config.idle, false)
        print("New State: incoming")
    elseif event[1] == "stargate_outgoing_wormhole" then
        rs.setOutput(config.outgoing, true)
        rs.setOutput(config.incoming, false)
        rs.setOutput(config.idle, false)
        print("New State: outgoing")
    elseif event[1] == "stargate_disconnected" or event[1] == "stargate_reset" then
        rs.setOutput(config.idle, true)
        rs.setOutput(config.outgoing, false)
        rs.setOutput(config.incoming, false)
        print("New State: idle")
    end
end
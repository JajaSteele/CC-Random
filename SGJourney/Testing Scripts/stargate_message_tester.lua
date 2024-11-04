local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local stat, err = pcall(function()
    print("Waiting for incoming connection")
    os.pullEvent("stargate_incoming_connection")
    interface.sendStargateMessage("connection")
    print("Connection!")
end)
if not stat then
    print("Failed: "..err)
end

local stat, err = pcall(function()
    print("Waiting for kawoosh to start")
    os.pullEvent("stargate_incoming_wormhole")
    interface.sendStargateMessage("kawoosh")
    print("Kawoosh!")
end)
if not stat then
    print("Failed: "..err)
end

local stat, err = pcall(function()
    print("Waiting for kawoosh to end")
    repeat
        sleep()
    until interface.isWormholeOpen()
    interface.sendStargateMessage("formed")
    print("Formed!")
end)
if not stat then
    print("Failed: "..err)
end
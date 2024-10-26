local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local stat, err = pcall(function()
    print("Waiting for incoming wormhole")
    os.pullEvent("stargate_incoming_wormhole")
    interface.sendStargateMessage("connection")
end)
if not stat then
    print("Failed: "..err)
end

local stat, err = pcall(function()
    print("Waiting for kawoosh to start")
    repeat
        sleep()
    until interface.getOpenTime() > 0
    interface.sendStargateMessage("kawoosh")
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
end)
if not stat then
    print("Failed: "..err)
end
local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

while true do
    os.pullEvent("stargate_incoming_wormhole")
    repeat
        sleep(1)
    until not interface.isStargateConnected() or interface.getOpenTime() > (20*5)
    print("Auto-closing")
    interface.disconnectStargate()
end
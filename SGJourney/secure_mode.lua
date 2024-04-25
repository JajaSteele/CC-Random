local sg = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local monitor = peripheral.find("monitor")

if monitor then
    monitor.setBackgroundColor(colors.red)
    monitor.clear()
    monitor.setTextColor(colors.yellow)
    monitor.setCursorPos(1,1)
    monitor.write("SECURE MODE")
    monitor.setCursorPos(1,2)
    monitor.write("ALL INCOMING WORMHOLES DENIED")
end

print("Blocking all incoming wormholes.")
while true do
    os.pullEvent("stargate_incoming_wormhole")
    repeat
        sleep()
    until sg.isStargateConnected() and sg.isWormholeOpen()
    sg.disconnectStargate()

    print("Blocked one incoming wormhole")
end
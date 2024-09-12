local monitor = peripheral.find("monitor")

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

monitor.setTextScale(4.5)

while true do
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.write(interface.getCurrentSymbol())
    sleep()
end
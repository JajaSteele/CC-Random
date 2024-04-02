local monitor = peripheral.find("monitor")
local interface = peripheral.wrap("bottom")

monitor.setTextScale(4.5)

while true do
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.write(interface.getCurrentSymbol())
    sleep()
end
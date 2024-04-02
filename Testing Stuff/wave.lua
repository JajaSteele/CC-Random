local monitor = peripheral.find("monitor")

monitor.setTextScale(0.5)
local w,h = monitor.getSize()

local monitor_win = window.create(monitor, 1,1, monitor.getSize())

local divide = 1
local reverse = false

while true do
    monitor_win.setVisible(false)
    monitor_win.clear()
    for i1=1, w*100 do
        monitor_win.setCursorPos(i1/100,((h/2)+((h/2)*(math.sin((i1/100)/(w/divide)))))+1)
        monitor_win.write("#")
    end
    monitor_win.setCursorPos(1,h)
    monitor_win.write(divide)
    monitor_win.setVisible(true)
    sleep()
    if reverse then
        divide = divide-1
    else
        divide = divide+1
    end

    if divide > 40 then
        reverse = true
    elseif divide < 2 then
        reverse = false
    end
end
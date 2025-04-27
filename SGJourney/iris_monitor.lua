local sg = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local monitor = peripheral.find("monitor")

monitor.setTextScale(2.5)
local width, height = monitor.getSize()
local mon = window.create(monitor, 1,1, width,height)
mon.clearLine = function()
    local x,y = mon.getCursorPos()
    mon.write(string.rep(" ", width-(x-1)))
    mon.setCursorPos(x,y)
end
while true do
    mon.setVisible(false)
    mon.setCursorPos(1,1)
    mon.clearLine()
    mon.write(string.format("%.1f%%",sg.getIrisProgressPercentage()))
    mon.setCursorPos(1,2)
    local iris = sg.getIris()
    if iris then
        mon.setTextColor(colors.green)
        mon.clearLine()
        mon.write((iris):match(".+:(.+)").."      ")
    else
        mon.setTextColor(colors.red)
        mon.clearLine()
        mon.write("No Iris      ")
    end
    mon.setTextColor(colors.white)
    mon.setCursorPos(1,3)
    mon.clearLine()
    mon.write(sg.getIrisDurability().."/"..sg.getIrisMaxDurability())
    mon.setVisible(true)
    sleep()
end
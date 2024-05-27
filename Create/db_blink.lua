local dp = peripheral.find("Create_DisplayLink")
local monitor = peripheral.find("monitor")

local dp_height, dp_width = dp.getSize()

local function setBlock(x,y, state)
    if state then
        dp.setCursorPos((4*(x-1))+1, (2*(y-1))+1)
        dp.write("####")
        dp.setCursorPos((4*(x-1))+1, (2*(y-1))+2)
        dp.write("####")
    else
        dp.setCursorPos((4*(x-1))+1, (2*(y-1))+1)
        dp.write("    ")
        dp.setCursorPos((4*(x-1))+1, (2*(y-1))+2)
        dp.write("    ")
    end
end

dp.clear()

local state = true
setBlock(2,2, true)
setBlock(3,3, true)
setBlock(2,4, true)
while true do
    setBlock(5,4, state)
    setBlock(6,4, state)
    dp.update()
    state = not state
    sleep(0.5)
end

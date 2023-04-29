local pld = peripheral.find("playerDetector")

local timer = 1
local toggle = true

while true do
    if pld.isPlayersInRange(100) then
        if toggle then
            rs.setOutput("back",true)
            timer = 1
            toggle = false
        end
    else
        toggle = true
    end
    os.sleep(0.5)
    if timer > 0 then
        timer = timer-1
    else
        rs.setOutput("back",false)
    end
end
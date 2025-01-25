local detector = peripheral.find("environmentDetector")

local moon_phases = {
    [0] = "Full moon", 
    [1] = "Waning gibbous", 
    [2]= "Third quarter", 
    [3] = "Waning crescent", 
    [4] = "New moon", 
    [5] = "Waxing crescent", 
    [6] = "First quarter", 
    [7] = "Waxing gibbous"
}

print("Select a moon phase:")
local selected = tonumber(read())

if not moon_phases[selected] then
    error("Invalid phase")
end


while true do
    local current = detector.getMoonId()
    if current ~= selected then
        print(current.." ~= "..selected..", Skipping")
        redstone.setOutput("front", true)
        sleep(1)
        redstone.setOutput("front", false)
        sleep(35)
    else
        print("Right moon phase detected!")
        print("Exiting..")
        sleep(1)
        return
    end
end
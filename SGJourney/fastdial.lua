local sg = peripheral.find("basic_interface")

local current = sg.getCurrentSymbol()
print("current: "..current)
print("input:")
local target = tonumber(read())

local function spin(length, direction)
    if direction > 0 then
        for i1=1, length do
            for i2=1, 5 do
                rs.setAnalogOutput("right", 14)
                sleep()
                rs.setAnalogOutput("right", 0)
            end
            if i1%3 == 0 then
                rs.setAnalogOutput("right", 5)
                sleep()
                rs.setAnalogOutput("right", 0)
            end
            if i1%9 == 0 then
                rs.setAnalogOutput("right", 5)
                sleep()
                rs.setAnalogOutput("right", 0)
            end
        end
    else
        for i1=1, length do
            for i2=1, 5 do
                rs.setAnalogOutput("right", 5)
                sleep()
                rs.setAnalogOutput("right", 0)
            end
            if i1%3 == 0 then
                rs.setAnalogOutput("right", 14)
                sleep()
                rs.setAnalogOutput("right", 0)
            end
            if i1%9 == 0 then
                rs.setAnalogOutput("right", 14)
                sleep()
                rs.setAnalogOutput("right", 0)
            end
        end
    end
end

while true do
    current = sg.getCurrentSymbol()
    repeat
        target = math.random(0,38)
    until target ~= current
    
    local dir = 0
    local dist = 0
    local delta = target-current

    -- if delta > 0 then
    --     if delta > 19 then
    --         dist = math.abs((delta)-39)
    --     else
    --         dist = math.abs((delta))
    --     end
    -- elseif delta < 0 then
    --     if delta < -19 then
    --         dist = math.abs((delta)+39)
    --     else
    --         dist = math.abs((delta))
    --     end
    -- end

    dist = math.abs(target - current)
    dist = math.min(dist, 39-dist)

    if (target-current) % 38 < 19 then
        spin(dist, 1)
    else
        spin(dist, -1)
    end

    print("Target: "..target.." | Result: "..sg.getCurrentSymbol())
    sleep(1)
end
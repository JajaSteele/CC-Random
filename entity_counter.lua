local ed = peripheral.find("environment_detector")
local monitor = peripheral.find("monitor")
local completion = require "cc.completion"

local config = {}

if fs.exists(".entity_detect.config") then
    local cfg_file = io.open(".entity_detect.config","r")
    config = textutils.unserialise(cfg_file:read("*a"))
    cfg_file:close()
else
    print("Starting Config!")
    print("Scan Radius?")
    config.radius = tonumber(read()) or 8

    print("Entity Name?")
    config.entity = read()

    local def_cooldown = (ed.getConfiguration().operations.scanEntities.defaultCooldown/1000)
    print("Update Interval in seconds? (minimum "..def_cooldown..")")
    config.update = math.max(tonumber(read()) or 0, def_cooldown)

    print("Redstone Output Side?")
    config.side = read(nil, nil, function(text) return completion.side(text) end)

    print("Redstone Output Threshold?")
    config.threshold = tonumber(read()) or 1

    local cfg_file = io.open(".entity_detect.config","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

while true do
    local entities = ed.scanEntities(config.radius, config.entity)
    if entities then
        local count = 0
        for k,v in pairs(entities) do
            count = count + 1
        end
        print("Counted: "..count.." >= "..config.threshold)

        if monitor then
            monitor.clear()
            monitor.setTextScale(5)
            monitor.setCursorPos(1,1)
            monitor.setTextColor(colors.white)
            monitor.write(count)
            monitor.setCursorPos(1,2)
            monitor.setTextColor(colors.red)
            monitor.write(config.threshold)
        end

        if count >= config.threshold then
            rs.setOutput(config.side, true)
        else
            rs.setOutput(config.side, false)
        end
        sleep(config.update)
    else
        sleep(0.1)
    end
end

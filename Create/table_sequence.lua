local sticker = "right"
local gearshift = "back"
local gantry = "left"

local multiplier = 0.75

local function pulse(side, duration)
    redstone.setOutput(side, true)
    sleep(duration*multiplier)
    redstone.setOutput(side, false)
end

local function sleep(duration)
    os.sleep(duration*multiplier)
end

local set = redstone.setOutput

local side_list = {
    "back",
    "front",
    "top",
    "bottom",
    "left",
    "right"
}

local function redstoneThread()
    local redstone_status = false
    while true do
        os.pullEvent("redstone")
        local new_status = false
        for k,side in pairs(side_list) do
            local signal = redstone.getInput(side)
            if signal then
                new_status = true
                break
            end
        end

        if redstone_status == false and new_status == true then
            os.queueEvent("redstone_update", true)
        elseif redstone_status == true and new_status == false then
            os.queueEvent("redstone_update", false)
        end
        redstone_status = new_status
    end
end

local function mainThread()
    while true do
        local event, signal = os.pullEvent("redstone_update")
        if signal == true then
            print("Toggling Deployment")
            pulse(gantry, 0.75)
            set(gearshift, true)
            sleep(1)
            pulse(gantry, 0.5)
            sleep(0.2)
            pulse(sticker, 0.1)
            sleep(0.2)
            set(gearshift, false)
            pulse(gantry, 0.5)
            sleep(1)
            set(gearshift, true)
            pulse(gantry, 0.75)
            set(gearshift, false)
        end
    end
end

parallel.waitForAny(redstoneThread, mainThread)

for k,v in pairs(side_list) do
    set(v, false)
end
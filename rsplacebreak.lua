local side_list = {
    "back",
    "front",
    "top",
    "bottom",
    "left",
    "right"
}

local redstone_status = false

local new_status_start = false
for k,side in pairs(side_list) do
    local signal = redstone.getInput(side)
    if signal then
        new_status_start = true
        break
    end
end

redstone_status = new_status_start

local function redstoneThread()
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

        local count = turtle.getItemCount()
        if redstone_status == false and new_status == true then
            if count > 0 then
                turtle.place()
            end
        elseif redstone_status == true and new_status == false then 
            if count < 1 then
                turtle.dig()
            end
        end
        redstone_status = new_status
    end
end

local function digThread()
    while true do
        local count = turtle.getItemCount()
        if redstone_status then
            if count > 0 then
                turtle.place()
            end
        else
            if count < 1 then
                turtle.dig()
            end
        end
        sleep(0.35)
    end
end

parallel.waitForAll(digThread, redstoneThread)
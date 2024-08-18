local side_list = {
    "back",
    "front",
    "top",
    "bottom",
    "left",
    "right"
}

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
        turtle.digUp()
        print("Digging!")
    end
    redstone_status = new_status
end
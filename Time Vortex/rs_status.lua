local tardis = peripheral.find("tardis_console")

local status_to_side = {
    flying="front",
    parked="back",
    vortex="left",
    demat="right",
    remat="right",
}

local prev_status
local prev_side

while true do
    local data = tardis.getStatus()
    local status = data.state

    if status ~= prev_status then
        print("State changed to "..status)
        prev_status = status
        local new_side = status_to_side[status]
        if new_side then
            if prev_side ~= new_side then
                print("Now powering side "..new_side)
                if prev_side then
                    rs.setOutput(prev_side, false)
                end
                rs.setOutput(new_side, true)
                prev_side = new_side
            end
        end
    end
    sleep(0.1)
end
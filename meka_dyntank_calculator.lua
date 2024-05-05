local tank = peripheral.find("dynamicValve")

term.clear()

local old_amount = tank.getStored().amount
local new_amount = tank.getStored().amount

while true do
    old_amount = new_amount
    new_amount = tank.getStored().amount

    local delta_per_tick = (new_amount-old_amount)/10

    term.setCursorPos(1,1)
    term.write(string.format("%.1fmb/t", delta_per_tick))
    sleep(0.5)
end
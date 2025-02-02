local tank = peripheral.find("dynamicValve")

term.clear()

local old_amount = tank.getStored().amount
local new_amount = tank.getStored().amount

local function prettyTime(seconds)
    return string.format("%.0fd %.0fh %.0fm %.0fs", math.floor(seconds/86400), math.floor((seconds/3600)%24), math.floor((seconds/60)%60), math.floor((seconds)%60))
end

term.clear()
term.setCursorPos(1,1)
local args = {...}
local maybe_mode = tonumber(args[1])
local mode
if maybe_mode and maybe_mode > 0 and maybe_mode < 3 then
    mode = maybe_mode
else
    print("Select Mode: 1. Liquid - 2. Gas")
    mode = tonumber(read()) or 1
end

local win = window.create(term.current(), 1,1, term.getSize())

while true do
    old_amount = new_amount
    new_amount = tank.getStored().amount

    local delta_per_tick = (new_amount-old_amount)/10
    
    win.setVisible(false)
    win.clear()
    win.setCursorPos(1,1)
    win.write(string.format("%.1fmb/t", delta_per_tick).."    ")
    if delta_per_tick < 0 then
        local eta = (new_amount/math.abs(delta_per_tick*20))
        win.setCursorPos(1,6)
        win.write("Depleted in: ")
        win.setCursorPos(1,7)
        win.write(prettyTime(eta).."    ")
    else
        local max
        if mode == 1 then
            max = tank.getTankCapacity()
        elseif mode == 2 then
            max = tank.getChemicalTankCapacity()
        end
        local eta = ((max-new_amount)/math.abs(delta_per_tick*20))
        win.setCursorPos(1,6)
        win.write("Filled in: ")
        win.setCursorPos(1,7)
        win.write(prettyTime(eta).."    ")
    end
    win.setVisible(true)
    sleep(0.5)
end
local cube = peripheral.find("basicEnergyCube") or peripheral.find("advancedEnergyCube") or peripheral.find("eliteEnergyCube") or peripheral.find("ultimateEnergyCube")
print(cube)
sleep(1)
term.clear()

local old_amount = mekanismEnergyHelper.joulesToFE(cube.getEnergy())
local new_amount = mekanismEnergyHelper.joulesToFE(cube.getEnergy())

local function prettyEnergy(energy)
    local energy_compare = math.abs(energy)
    if energy_compare > 1000000000000 then
        return string.format("%.2f", energy/1000000000000).." TFE"
    elseif energy_compare > 1000000000 then
        return string.format("%.2f", energy/1000000000).." GFE"
    elseif energy_compare > 1000000 then
        return string.format("%.2f", energy/1000000).." MFE"
    elseif energy_compare > 1000 then
        return string.format("%.2f", energy/1000).." kFE"
    else
        return string.format("%.2f", energy).." FE"
    end
end

local min = 0
local max = 0

while true do
    old_amount = new_amount
    new_amount = mekanismEnergyHelper.joulesToFE(cube.getEnergy())

    local delta_per_tick = (new_amount-old_amount)/4

    term.setCursorPos(1,1)
    term.clearLine()
    term.write(prettyEnergy(delta_per_tick).."/t")
    if delta_per_tick < min then
        min = delta_per_tick
    end
    if delta_per_tick > max then
        max = delta_per_tick
    end
    term.setCursorPos(1,2)
    term.clearLine()
    term.write("Min Delta (max output): "..prettyEnergy(min))
    term.setCursorPos(1,3)
    term.clearLine()
    term.write("Max Delta (max input): "..prettyEnergy(max))
    sleep(0.1)
end
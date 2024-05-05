local interface_a = {peripheral.find("basic_interface")}
local interface_b = {peripheral.find("crystal_interface")}
local interface_c = {peripheral.find("advanced_crystal_interface")}

local function prettyEnergy(energy)
    if energy > 1000000000000 then
        return string.format("%.2f", energy/1000000000000).." TFE"
    elseif energy > 1000000000 then
        return string.format("%.2f", energy/1000000000).." GFE"
    elseif energy > 1000000 then
        return string.format("%.2f", energy/1000000).." MFE"
    elseif energy > 1000 then
        return string.format("%.2f", energy/1000).." kFE"
    else
        return string.format("%.2f", energy).." FE"
    end
end

print("Enter Energy Target:")
local target = tonumber(read())

if target then
    for k,v in pairs(interface_a) do
        v.setEnergyTarget(target)
        print("set "..peripheral.getName(v).." to "..prettyEnergy(target))
    end
    for k,v in pairs(interface_b) do
        v.setEnergyTarget(target)
        print("set "..peripheral.getName(v).." to "..prettyEnergy(target))
    end
    for k,v in pairs(interface_c) do
        v.setEnergyTarget(target)
        print("set "..peripheral.getName(v).." to "..prettyEnergy(target))
    end
end

print("set all connected interfaces to "..prettyEnergy(target).."!")
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

local gate_detected = false

while true do
    local stat, data = turtle.inspectUp()

    if stat and data.name:match("ring") then
        if not gate_detected then
            print("Gate inserted into charger!")
        end
        gate_detected = true
        sleep(0.1)
        local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
        print(prettyEnergy(interface.getStargateEnergy()).." / "..prettyEnergy(interface.getEnergyTarget()).." - "..string.format("%.1f%%", (interface.getStargateEnergy()/interface.getEnergyTarget())*100))
        if interface.getStargateEnergy() >= interface.getEnergyTarget() then
            turtle.digUp()
            print("Breaking gate!")
        end
    else
        if gate_detected then
            print("Gate removed from charger!")
        end
        gate_detected = false
    end
    sleep(1)
end
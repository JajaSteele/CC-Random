local source = peripheral.find("ae2:interface")
local output = peripheral.find("minecraft:barrel")

local fusion = peripheral.find("fusionReactorLogicAdapter")

local restart_threshold = 150000000

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

while true do
    local production_rate = mekanismEnergyHelper.joulesToFE(fusion.getProductionRate())
    if production_rate < restart_threshold then
        print("Fusion is too low! Restarting!")
        output.pullItems(peripheral.getName(source), 1)
        sleep(3)
        rs.setOutput("left", true)
        repeat
            sleep(2)
            production_rate = mekanismEnergyHelper.joulesToFE(fusion.getProductionRate())
            print(prettyEnergy(production_rate).." > "..prettyEnergy(restart_threshold+1000000))
        until production_rate > restart_threshold+1000000
        print("Reached acceptable production rate.")
        rs.setOutput("left", false)
    end
    if production_rate > restart_threshold then
        rs.setOutput("left", false)
        print(prettyEnergy(production_rate).." > "..prettyEnergy(restart_threshold))
        sleep(5)
    end
    sleep(1)
end
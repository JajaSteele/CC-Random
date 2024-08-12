local inv = peripheral.find("inventoryManager")

local base_energy_level = 16000000

local function checkArmorThread()
    while true do
        local current_armor = inv.getArmor()

        for k, piece in pairs(current_armor) do
            local energy = tonumber(piece.nbt.mekData.EnergyContainers[1].stored)

            local energy_units = piece.nbt.mekData.modules["mekanism:energy_unit"]
            if energy_units and energy_units.amount then
                energy_units = energy_units.amount
            else
                energy_units = 0
            end

            local max_energy = base_energy_level*(2^energy_units)

            if energy < max_energy/2 then
                print("Energy below 50% ("..energy.."/"..max_energy..")\nRecharging Item..")
                inv.removeItemFromPlayer("bottom", {name = piece.name, fromSlot = piece.slot})
                while true do
                    local charge_piece = inv.getItemsChest("bottom")[1]
                    local charge_energy = tonumber(charge_piece.nbt.mekData.EnergyContainers[1].stored)

                    if charge_energy >= max_energy-5 then
                        break
                    end
                    sleep(0.5)
                end
                print("Recharging finished! Equipping item..")
                inv.addItemToPlayer("bottom", {name=piece.name, toSlot=piece.slot})
            end
        end
        sleep(3)
    end
end

parallel.waitForAll(checkArmorThread)
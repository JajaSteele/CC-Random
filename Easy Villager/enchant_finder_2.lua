local trader = peripheral.find("easy_trader")
local speaker = peripheral.find("speaker")

print("Enter enchant name (or part of the name)")
local filter = read():lower()

while true do
    if trader.hasVillager() then
        local has_found = false
        local villager = trader.inspect()
        local offers = villager.offers
        for k, offer in pairs(offers) do
            for k, output in pairs(offer.outputs) do
                if output.enchantments then
                    for k, enchant in pairs(output.enchantments) do
                        print(enchant.name)
                        print(enchant.displayName)
                        print("")
                        if enchant.name:lower():match(filter) or enchant.displayName:lower():match(filter) then
                            speaker.playSound("minecraft:entity.player.levelup", 3, 1)
                            print("Found matching enchant:\n"..enchant.displayName.." ("..enchant.name..")")
                            print("Press any key to continue")
                            os.pullEvent("key")
                            print("Awaiting for enchant..")
                            has_found = true
                        end
                    end
                end
            end
        end
        if not has_found then
            rs.setOutput("bottom", true)
            sleep(0)
            rs.setOutput("bottom", false)
        end
    end
end
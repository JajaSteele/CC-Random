local inv_manager = peripheral.find("inventoryManager")
local player_detector = peripheral.find("playerDetector")

local function getItems(name_list, list)
    local item_list = {}
    for k,v in pairs(list) do
        for _, name in pairs(name_list) do
            if v.name == name then
                item_list[#item_list+1] = v
            end
        end
    end
    return item_list
end

local function isPlayerOnline(name)
    local player_list = player_detector.getOnlinePlayers()

    for k,v in pairs(player_list) do
        if v == name then
            return true
        end
    end
end

while true do
    if isPlayerOnline(inv_manager.getOwner()) then
        local item_list = inv_manager.getItems()
        local cans_list = getItems({"ad_astra_giselle_addon:oxygen_can", "ad_astra_giselle_addon:netherite_oxygen_can"}, item_list)

        for k,v in pairs(cans_list) do
            if (not v.nbt.BotariumData) or v.nbt.BotariumData.StoredFluids[1].Amount < 150 then
                inv_manager.removeItemFromPlayer("up", {name=v.name, fromSlot=v.slot})
                print("Refilling can from slot "..v.slot)
                repeat
                    local stat = inv_manager.addItemToPlayer("down", {name=v.name, toSlot=v.slot})
                    sleep(0.25)
                until stat > 0
                print("Done refilling!")
                if peripheral.find("chatBox") then
                    peripheral.find("chatBox").sendToastToPlayer(v.displayName.." ("..v.slot..") refilled!", "Oxygen Refiller", inv_manager.getOwner(), "!", "<>")
                end
            end
        end
    end
    sleep(60)
end
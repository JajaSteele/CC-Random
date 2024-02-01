local inv = peripheral.find("inventoryManager")
local chatbox = peripheral.find("chatBox")

local old_armor = {}
local spacesuit = {
    "ad_astra:netherite_space_boots",
    "ad_astra:netherite_space_pants",
    "ad_astra:netherite_space_suit",
    "ad_astra:netherite_space_helmet",
}

while true do
    print("Awaiting msg 'spacesuit toggle' to equip spacesuit")

    while true do
        local event = {os.pullEvent()}
        if event[1] == "key" then
            break
        elseif event[1] == "chat" and event[2] == inv.getOwner() and event[3] == "spacesuit toggle" then
            break
        end
    end
    chatbox.sendMessageToPlayer("Equipped Spacesuit!", inv.getOwner(), "Spacesuit Manager")

    for k,v in ipairs(inv.getArmor()) do
        old_armor[k] = v.name
        inv.removeItemFromPlayer("left", {name=v.name})
        print("Removing item "..v.name)
    end

    for k,v in ipairs(spacesuit) do
        inv.addItemToPlayer("left", {name=v, toSlot=(99+k)})
        print("Adding item "..v.." to slot "..(99+k))
    end

    print("Awaiting msg 'spacesuit toggle' to equip old armor")

    while true do
        local event = {os.pullEvent()}
        if event[1] == "key" then
            break
        elseif event[1] == "chat" and event[2] == inv.getOwner() and event[3] == "spacesuit toggle" then
            break
        end
    end
    chatbox.sendMessageToPlayer("Unequipped Spacesuit!", inv.getOwner(), "Spacesuit Manager")

    for k,v in ipairs(inv.getArmor()) do
        inv.removeItemFromPlayer("left", {name=v.name})
        print("Removing item "..v.name)
    end

    for k,v in ipairs(old_armor) do
        inv.addItemToPlayer("left", {name=v, toSlot=(99+k)})
        print("Adding item "..v.." to slot "..(99+k))
    end
end
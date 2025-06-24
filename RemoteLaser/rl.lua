local inv = peripheral.find("inventoryManager")
local chat = peripheral.find("chatBox")


while true do
    local event, username, msg, hidden = os.pullEvent("chat")
    if msg == "bindlaser" and username == inv.getOwner() then
        chat.sendMessage("Attempting to bind laser..")
        inv.removeItemFromPlayer("front", {name="entangled:item"})

        sleep(2)

        inv.addItemToPlayer("front", {name="entangled:item"})
    end
end
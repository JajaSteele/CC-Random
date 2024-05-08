local modular_router = peripheral.wrap("top")
local turtle_storage = peripheral.wrap("bottom")

local inv_manager = peripheral.find("inventoryManager")
local chatbox = peripheral.find("chatBox")
local player_detector = peripheral.find("playerDetector")

local function getPlayerDim(username)
    local player = player_detector.getPlayer(username)
    return player.dimension
end

local function findTurtleSlot(dim)
    for i1=1, turtle_storage.size() do
        local item = turtle_storage.getItemDetail(i1)
        if item and item.displayName == dim then
            return i1
        end
    end
end

while true do
    local event, username, message, uuid, isHidden = os.pullEvent("chat")
    if isHidden and message == "tempgate" and username == inv_manager.getOwner() then
        local player_dim = getPlayerDim(username)
        if player_dim then
            local turtle_slot = findTurtleSlot(player_dim)
            if turtle_slot then
                turtle_storage.pushItems(peripheral.getName(modular_router), turtle_slot)
                sleep(0.5)
                inv_manager.addItemToPlayer("back", {count=64})
                inv_manager.addItemToPlayer("back", {count=64})
                inv_manager.addItemToPlayer("back", {count=64})
                inv_manager.addItemToPlayer("back", {count=64})
                inv_manager.addItemToPlayer("back", {count=64})
            else
                chatbox.sendMessageToPlayer("No turtle for this dimension!", username, "TempGate")
            end
        end
    end
end
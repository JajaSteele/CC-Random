local modular_router = peripheral.wrap("top")
local turtle_storage = peripheral.wrap("bottom")

local inv_manager = peripheral.find("inventoryManager")
local chatbox = peripheral.find("chatBox")
local player_detector = peripheral.find("playerDetector")

local in_use = false
local shulker_gone = false
local chat_name = "\xA76TempGate\xA7f"

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

local function mainThread()
    while true do
        local event, username, message, uuid, isHidden = os.pullEvent("chat")
        if isHidden and message == "tempgate" and username == inv_manager.getOwner() then
            print("Received request..")
            if not in_use then
                local player_dim = getPlayerDim(username)
                if player_dim then
                    print("Location: "..player_dim)
                    local turtle_slot = findTurtleSlot(player_dim)
                    if turtle_slot then
                        print("Sending turtle and shulker to player!")
                        chatbox.sendMessageToPlayer("\xA7eSending items..", username, chat_name)
                        inv_manager.addItemToPlayer("front", {fromSlot=turtle_slot-1})
                        sleep(0.5)
                        inv_manager.addItemToPlayer("back", {})
                        in_use = true
                        shulker_gone = true
                    else
                        print("Turtle for "..player_dim.." doesn't exist!")
                        chatbox.sendMessageToPlayer("\xA7cNo turtle for this dimension!", username, chat_name)
                    end
                end
            else
                print("Denied: Already in use!")
                chatbox.sendMessageToPlayer("\xA7cTempgate is currently in use!", username, chat_name)
            end
        end
    end
end

local function checkShulkerReturn()
    while true do
        if in_use then
            local item = inv_manager.getItemsChest("back")[1]
            if item and item.name:match("shulker_box") then
                in_use = false
                shulker_gone = false
                chatbox.sendMessageToPlayer("\xA7aShulker refilled and ready to use!", inv_manager.getOwner(), chat_name)
                print("Shulker Received!")
            end
            local b = peripheral.wrap("back")
            if b and shulker_gone then
                chatbox.sendMessageToPlayer("\xA7eShulker & Turtle returned..", inv_manager.getOwner(), chat_name)
                shulker_gone = false
            end
        end
        sleep(1.5)
    end
end

parallel.waitForAll(mainThread, checkShulkerReturn)
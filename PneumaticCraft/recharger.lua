local chat = peripheral.find("chatBox")
local inv = peripheral.find("inventoryManager")
local red = peripheral.find("redstoneIntegrator")

local message_queue = {}

local function sendMessage(text, player, whisper)
    message_queue[#message_queue+1] = {
        type="plain",
        text=text,
        player=player,
        whisper=whisper
    }
end

local function sendFormattedMessage(json_text, player, whisper)
    message_queue[#message_queue+1] = {
        type="formatted",
        text=json_text,
        player=player,
        whisper=whisper
    }
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local messageThread = function()
    while true do
        local sleep_time = 0
        for k,v in ipairs(message_queue) do
            if v.type == "plain" then
                if v.whisper then
                    chat.sendMessageToPlayer(v.text, v.player, "\xA7bTP-Drone\xA7r")
                else
                    chat.sendMessage(v.text, "\xA7bTP-Drone\xA7r")
                end
            elseif v.type == "formatted" then
                if v.whisper then
                    chat.sendFormattedMessageToPlayer(v.text, v.player, "\xA7bTP-Drone\xA7r")
                else
                    chat.sendFormattedMessage(v.text, "\xA7bTP-Drone\xA7r")
                end
            end
            table.remove(message_queue, k)
            sleep_time = 1.1
            break
        end
        sleep(sleep_time)
    end
end

local mainThread = function()
    while true do
        local event, user, msg, uuid, hidden = os.pullEvent("chat")

        local args = split(msg, " ")

        if user == inv.getOwner() then
            if args[1] == "pnc" then
                if args[2] == "hand" then
                    local item_name = inv.getItemInHand().name
                    local num_out = inv.removeItemFromPlayer("bottom", {name=item_name})
                    if num_out > 0 then
                        sendMessage("\xA7eRecharging item \xA7a"..item_name.."\xA7e ..", user, true)
                        repeat
                            sleep(1)
                        until red.getInput("front") or inv.getItemsChest("bottom")[1] == nil
                        local num_in = inv.addItemToPlayer("bottom", {name=item_name})
                        if num_in > 0 then
                            sendMessage("\xA7aItem \xA7e"..item_name.."\xA7a successfully recharged!", user, true)
                        else
                            sendMessage("\xA7cError! Couldn't return item!", user, true)
                        end
                    end
                elseif args[2] == "offhand" then
                    local item_name = inv.getItemInOffHand().name
                    local num_out = inv.removeItemFromPlayer("bottom", {name=item_name})
                    if num_out > 0 then
                        sendMessage("\xA7eRecharging item \xA7a"..item_name.."\xA7e ..", user, true)
                        repeat
                            sleep(1)
                        until red.getInput("front") or inv.getItemsChest("bottom")[1] == nil
                        local num_in = inv.addItemToPlayer("bottom", {name=item_name, toSlot=36})
                        if num_in > 0 then
                            sendMessage("\xA7aItem \xA7e"..item_name.."\xA7a successfully recharged!", user, true)
                        else
                            sendMessage("\xA7cError! Couldn't return item!", user, true)
                        end
                    end
                elseif args[2] == "armor" then
                    for k,v in ipairs(inv.getArmor()) do
                        local item_name = v.name
                        local num_out = inv.removeItemFromPlayer("bottom", {name=item_name})
                        if num_out > 0 then
                            sendMessage("\xA7eRecharging item \xA7a"..item_name.."\xA7e ..", user, true)
                            repeat
                                sleep(1)
                            until red.getInput("front") or inv.getItemsChest("bottom")[1] == nil
                            local num_in = inv.addItemToPlayer("bottom", {name=item_name, toSlot=99+k})
                            if num_in > 0 then
                                sendMessage("\xA7aItem \xA7e"..item_name.."\xA7a successfully recharged!", user, true)
                            else
                                sendMessage("\xA7cError! Couldn't return item!", user, true)
                            end
                        end
                    end
                end
            end
        end
    end
end

parallel.waitForAny(mainThread, messageThread)
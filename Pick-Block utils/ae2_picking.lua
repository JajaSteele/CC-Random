local inv = peripheral.find("inventoryManager")
local me = peripheral.find("meBridge")
local chat = peripheral.find("chatBox")

local picker = peripheral.find("picker")

local chat_queue = {}

local chat_name = "AE2 Pick-Block"
local prefix_length = #chat_name+2
local chat_align = string.rep(" ", prefix_length)

local function queueMessage(msg, prefix, brackets)
    chat_queue[#chat_queue+1] = {
        type = "global",
        message = msg,
        prefix = prefix,
        brackets = brackets,
        sent = false
    }
end

local function queueToast(msg, title, player, prefix, brackets)
    chat_queue[#chat_queue+1] = {
        type = "toast",
        message = msg,
        title = title,
        player = player,
        prefix = prefix,
        brackets = brackets,
        sent = false
    }
end

local function queuePrivateMessage(msg, player, prefix, brackets)
    chat_queue[#chat_queue+1] = {
        type = "private",
        message = msg,
        player = player,
        prefix = prefix,
        brackets = brackets,
        sent = false
    }
end

local function chatManager()
    while true do
        for k, msg_to_send in ipairs(chat_queue) do
            if msg_to_send.sent then
                table.remove(chat_queue, k)
            else
                if msg_to_send.type == "private" then
                    local stat = chat.sendMessageToPlayer(msg_to_send.message, msg_to_send.player, msg_to_send.prefix, msg_to_send.brackets)
                    if stat then
                        chat_queue[k].sent = true
                    end
                    sleep(0.5)
                elseif msg_to_send.type == "global" then
                    local stat = chat.sendMessage(msg_to_send.message, msg_to_send.prefix, msg_to_send.brackets)
                    if stat then
                        chat_queue[k].sent = true
                    end
                    sleep(0.5)
                elseif msg_to_send.type == "toast" then
                    local stat = chat.sendToastToPlayer(msg_to_send.message, msg_to_send.title, msg_to_send.player, msg_to_send.prefix, msg_to_send.brackets)
                    if stat then
                        chat_queue[k].sent = true
                    end
                    sleep(0.5)
                end
            end
            sleep()
        end
        sleep(0.25)
    end
end

local awaiting_craft = ""
local crafting_queue = {}
local function queueCraft(name, count)
    if crafting_queue[name] then
        local entry = crafting_queue[name]
        if not entry.started and not entry.finished then
            entry.count = count
            entry.timer = 4
        end
        return false
    else
        crafting_queue[name] = {count=count, started=false, finished=false, timer = 4}
        return true
    end
end

local function pickListener()
    while true do
        local event, success, block_name, block_nbt = os.pullEvent("picker_pickblock")
        local owner = inv.getOwner()
        if block_name ~= awaiting_craft then
            awaiting_craft = ""
        end
        if not success then
            print("Pick-Block event!")
            local curr_item = inv.getItemInHand()
            local block_namespace, block_id = block_name:match("(.+):(.+)")
            if not curr_item.name or curr_item.name ~= block_name then
                print("Current item isn't the required block")
                local curr_slot = 1
                print("Checking inventory..")
                for k, item in pairs(inv.getItems()) do
                    if item.fingerprint == curr_item.fingerprint then
                        curr_slot = item.slot
                    end
                    if item.name == block_name then
                        print("Found in inventory!")
                        local free_slot = inv.getFreeSlot()
                        if curr_item.name then
                            print("Current item is not empty")
                            inv.removeItemFromPlayer("front", {name=curr_item.name, fromSlot=curr_slot})
                            if free_slot > 0 then
                                print("Moved current item to another slot")
                                inv.addItemToPlayer("front", {name=curr_item.name, toSlot=free_slot})
                            else
                                me.importItem({}, "front")
                                print("Moved current item to ME")
                            end

                            inv.removeItemFromPlayer("front", {name=block_name, fromSlot=item.slot})
                            inv.addItemToPlayer("front", {name=block_name, toSlot=curr_slot or free_slot})
                        else
                            print("Current item is empty")
                            inv.removeItemFromPlayer("front", {name=block_name, fromSlot=item.slot})
                            inv.addItemToPlayer("front", {name=block_name, toSlot=free_slot})
                        end
                        break
                    end
                end
                print("Checking ME System")
                local required_item = me.getItem({name=block_name})
                if required_item.amount and required_item.amount > 0 then
                    if curr_item.name then
                        print("Current item is not empty")
                        local free_slot = inv.getFreeSlot()
                        for k,v in pairs(inv.getItems()) do
                            if v.fingerprint == curr_item.fingerprint then
                                curr_slot = v.slot
                                break
                            end
                        end
                        inv.removeItemFromPlayer("front", {name=curr_item.name, fromSlot=curr_slot})
                        if free_slot > 0 then
                            print("Moved current item to another slot")
                            inv.addItemToPlayer("front", {name=curr_item.name, toSlot=free_slot})
                        else
                            me.importItem({}, "front")
                            print("Moved current item to ME")
                        end

                        free_slot = inv.getFreeSlot()
                        print("Current item found in ME, transferring")
                        me.exportItem({name=block_name}, "front")
                        inv.addItemToPlayer("front", {name=block_name, toSlot=curr_slot or free_slot})
                    else
                        print("Current item is empty")
                        local free_slot = inv.getFreeSlot()
                        print("Current item found in ME, transferring")
                        me.exportItem({name=block_name}, "front")
                        inv.addItemToPlayer("front", {name=block_name, toSlot=free_slot})
                    end
                else
                    if me.isItemCraftable({name=block_name}) then
                        if awaiting_craft == block_name then
                            if crafting_queue[block_name] then
                                local entry = crafting_queue[block_name]
                                local current_count = entry.count
                                if not entry.started and not entry.finished then
                                    if current_count == 1 then
                                        queueCraft(block_name, 64)
                                    else
                                        queueCraft(block_name, current_count+64)
                                    end
                                    print("Changed amount to "..current_count+64)
                                    entry.timer = 4
                                end
                            else
                                print("Crafting one "..block_name)
                                queueCraft(block_name, 1)
                                queuePrivateMessage("\xA7eQueuing craft: \n"..chat_align.."\xA7f[\xA7b"..block_id.."\xA7f]", owner, "AE2 Pick-Block")
                            end
                        else
                            awaiting_craft = block_name
                            queueToast("\xA7eUse pick-block once again to craft\n\xA76Or more than once to increase the amount\n\xA7o(+64 per additional click)", "AE2 Pick-Block", owner, "@")
                        end
                    else
                        queueToast("\xA7cCouldn't find item in ME!\n\xA7e"..block_id, "AE2 Pick-Block", owner, "@")
                    end
                end
            end
        end
    end
end

local function pickLink()
    while true do
        local event, username = os.pullEvent("picker_linked")
        local owner = inv.getOwner()
        if owner then
            if username == owner then
                print("Successfully linked to "..owner)
                queueToast("\xA7aSuccessfully linked to \xA7e"..owner, "AE2 Pick-Block",  owner, "@")
            else
                queueToast("\xA7cWarning! Linked to \xA7e"..username, "AE2 Pick-Block",  owner, "@")
            end
        else
            queueToast("\xA76Linked to \xA7e"..username.."\xA76\nbut inventory manager is not linked!", "AE2 Pick-Block",  username, "@")
        end
    end
end

local function craftingManager()
    while true do
        local owner = inv.getOwner()
        local to_remove = {}
        for name, craft in pairs(crafting_queue) do
            local short_name = name:match(".+:(.+)")
            if craft.timer > 0 then
                craft.timer = craft.timer-1
            end
            if not craft.started and not me.isItemCrafting({name=name}) and craft.timer <=0 then
                if me.isItemCraftable({name=name}) then
                    print("Starting craft for item:\n"..name.."\nCount: "..craft.count)
                    queuePrivateMessage("\xA7eStarting craft: \n"..chat_align.."\xA7f[\xA7b"..short_name.." x"..craft.count.."\xA7f]", owner, "AE2 Pick-Block")
                    me.craftItem({name=name, count=craft.count})
                    craft.started = true
                    sleep(0.25)
                    if not me.isItemCrafting({name=name}) then
                        to_remove[#to_remove+1] = name
                        print("Cannot craft item:\n"..name)
                        queuePrivateMessage("\xA7cUnable to start crafting of \xA7e'"..name.."'", owner, "AE2 Pick-Block")
                    end
                else
                    to_remove[#to_remove+1] = name
                    print("Cannot craft item:\n"..name)
                    queuePrivateMessage("\xA7cUnable to start crafting of \xA7e'"..name.."'", owner, "AE2 Pick-Block")
                end
            elseif craft.started and not me.isItemCrafting({name=name}) and craft.timer <=0 then
                local item = me.getItem({name=name})
                if item.name then
                    print("Crafting of item finished:\n"..item.name.."\nCount: "..item.amount)
                    queueToast("\xA7aFinished crafting!\n\xA7f[\xA7b"..short_name.." x"..item.amount.."\xA7f]", "AE2 Pick-Block",  owner, "@")
                end
                craft.finished = true
            end

            if craft.finished and craft.timer <=0 then
                local item = me.getItem({name=name})
                if item.name and item.amount > 0 then
                    print("Pushing crafted item:\n"..item.name)
                    me.exportItem({name=name}, "front")
                    local free_slot = inv.getFreeSlot()
                    inv.addItemToPlayer("front", {name=name, toSlot=free_slot})
                    to_remove[#to_remove+1] = name
                else
                    print("Cannot find crafted item:\n"..name.."\nRestarting craft!")
                    craft.finished = false
                    craft.started = false
                end
            end
        end

        for k, remove_key in pairs(to_remove) do
            crafting_queue[remove_key] = nil
            print("Removed ticket from crafting queue:\n"..remove_key)
        end
        sleep(0.5)
    end
end

parallel.waitForAll(pickListener, pickLink, chatManager, craftingManager)
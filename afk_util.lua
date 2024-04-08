local chat = peripheral.find("chatBox")
local player = peripheral.find("playerDetector")

local address_book = {}

local afk_statuses = {}
local afk_triggers = {}

local chat_queue = {}

local function queueMessage(msg, prefix, brackets)
    chat_queue[#chat_queue+1] = {
        type = "global",
        message = msg,
        prefix = prefix,
        brackets = brackets
    }
end

local function queueToast(msg, title, player, prefix, brackets)
    chat_queue[#chat_queue+1] = {
        type = "toast",
        message = msg,
        title = title,
        player = player,
        prefix = prefix,
        brackets = brackets
    }
end

local function queuePrivateMessage(msg, player, prefix, brackets)
    chat_queue[#chat_queue+1] = {
        type = "private",
        message = msg,
        player = player,
        prefix = prefix,
        brackets = brackets
    }
end

local function loadSave()
    if fs.exists("afk_save.txt") then
        local file = io.open("afk_save.txt", "r")
        afk_triggers = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open("afk_save.txt", "w")
    file:write(textutils.serialise(afk_triggers))
    file:close()
end

loadSave()

local function chatListener()
    while true do
        local event, username, msg, uuid, hidden = os.pullEvent("chat")
        if hidden then
            if msg == "afk" then
                afk_statuses[username] = not (afk_statuses[username] or false)
                print("New Status:", afk_statuses[username])

                if not afk_triggers[username] then
                    afk_triggers[username] = {
                        name=username,
                        triggers={
                            username,
                        }
                    }
                    writeSave()
                    queuePrivateMessage("\xA7e\xA7oYou have been given the default AFK trigger (your username)\n   To register custom triggers, do:\n\xA7a\xA7o$triggers trigger1,trigger2,trigger3 etc", username, "!", "<>")
                end

                if afk_statuses[username] then
                    queueMessage("\xA7a"..username.." is now AFK", "!", "<>")
                else
                    queueMessage("\xA7c"..username.." is no longer AFK", "!", "<>")
                end
            elseif msg:match("^triggers") then
                local new_triggers = {}
                for text in msg:lower():match("^%w+ (.+)"):gmatch("%w+") do
                    new_triggers[#new_triggers+1] = text
                end
                afk_triggers[username] = {
                    name=username,
                    triggers=new_triggers
                }
                writeSave()
                queuePrivateMessage("\xA7e\xA7oYour AFK triggers have been updated to:\n\xA7a\xA7o   "..table.concat(new_triggers, " "), username, "!", "<>")
            elseif msg == "help" then
                queuePrivateMessage("\xA7e\xA7oAFK-Utils Commands\n\xA77\xA7o$afk : toggle AFK mode\n$triggers a,b,c,d,etc : set which words triggers your afk message\n$status : Check whether you are AFK or not", username, "!", "<>")
            elseif msg == "status" then
                if afk_statuses[username] then
                    queueToast("\xA7aYou are currently AFK\xA7f\nUse $afk to toggle it", "AFK Status", username, "!", "<>")
                else
                    queueToast("\xA7cYou are currently not AFK\xA7f\nUse $afk to toggle it", "AFK Status", username, "!", "<>")
                end
            end
        elseif not hidden then
            for k, name in pairs(player.getOnlinePlayers()) do
                if afk_triggers[name] and afk_statuses[name] then
                    for k, trigger in pairs(afk_triggers[name].triggers) do
                        if msg:lower():match(trigger:lower()) then
                            queuePrivateMessage("\xA76\xA7o"..name.." is currently AFK!", username, "!", "<>")
                            break
                        end
                    end
                end
            end
        end
    end
end

local function joinListener()
    while true do
        local event, username = os.pullEvent("playerJoin")

        if afk_statuses[username] then
            queueToast("\xA7aYou are currently AFK\xA7f\nUse $afk to toggle it", "AFK Status", username, "!", "<>")
        else
            queueToast("\xA7cYou are currently not AFK\xA7f\nUse $afk to toggle it", "AFK Status", username, "!", "<>")
        end

        local afk_players = {}
        for k,v in pairs(player.getOnlinePlayers()) do
            if afk_statuses[v] then
                afk_players[#afk_players+1] = v
            end
        end

        if #afk_players > 0 then
            queuePrivateMessage("\xA7e\xA7oThe following player(s) are currently AFK:\n   \xA7a\xA7o"..table.concat(afk_players, "\n   \xA7a\xA7o"), username, "!", "<>")
        end
    end
end

local function chatManager()
    while true do
        local msg_to_send = chat_queue[1]

        if msg_to_send then
            if msg_to_send.type == "private" then
                repeat
                    local stat = chat.sendMessageToPlayer(msg_to_send.message, msg_to_send.player, msg_to_send.prefix, msg_to_send.brackets)
                    sleep(0.5)
                until stat
                table.remove(chat_queue, 1)
            elseif msg_to_send.type == "global" then
                repeat
                    local stat = chat.sendMessage(msg_to_send.message, msg_to_send.prefix, msg_to_send.brackets)
                    sleep(0.5)
                until stat
                table.remove(chat_queue, 1)
            elseif msg_to_send.type == "toast" then
                repeat
                    local stat = chat.sendToastToPlayer(msg_to_send.message, msg_to_send.title, msg_to_send.player, msg_to_send.prefix, msg_to_send.brackets)
                    sleep(0.5)
                until stat
                table.remove(chat_queue, 1)
            end
        end
        sleep(0.25)
    end
end

parallel.waitForAll(chatListener, chatManager, joinListener)
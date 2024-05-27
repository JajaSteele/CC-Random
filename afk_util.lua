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

local player_data = {}
local afk_positions = {}

local function chatListener()
    while true do
        local event, username, msg, uuid, hidden = os.pullEvent("chat")
        if hidden then
            if msg == "afk" then
                afk_statuses[username] = not (afk_statuses[username] or false)
                print("Manual: "..username.." is now AFK", afk_statuses[username])

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
                    local data = player.getPlayer(username)
                    local data_toadd = {
                        pos = {
                            x = data.x,
                            y = data.y,
                            z = data.z,
                            dim = data.dimension
                        }
                    }
                    player_data[username] = {
                        data_toadd,
                        data_toadd,
                        data_toadd,
                        data_toadd,
                        data_toadd
                    }
                    afk_positions[username] = data_toadd.pos
                else
                    queueMessage("\xA7c"..username.." is no longer AFK", "!", "<>")
                    print("Manual: "..username.." is no longer AFK", afk_statuses[username])
                    player_data[username] = {}
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
            elseif msg == "reboot" then
                os.reboot()
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

local save_pos_delay = (1000*60)
local save_pos_timer = os.epoch("utc") + 500

local function rangeEqual(a,b, range)
    return (a < b+range and a > b-range)
end
local function compareData(a,b, max_range)
    if a.dim == b.dim then
        return (rangeEqual(a.x, b.x, max_range) and rangeEqual(a.y, b.y, max_range) and rangeEqual(a.z, b.z, max_range))
    end
end

local function isImmobile(data, freedom)
    local immobile = true
    for k,v in pairs(data) do
        if not compareData(v.pos, data[#data].pos, freedom) then
            immobile = false
            break
        end
    end
    return immobile
end

local function autoAFK()
    while true do
        local player_list = player.getOnlinePlayers()

        for k,v in pairs(player_list) do
            local data = player.getPlayer(v)
            local data_tosave = {
                pos = {
                    x = data.x,
                    y = data.y,
                    z = data.z,
                    dim = data.dimension
                }
            }

            if os.epoch("utc") >= save_pos_timer then
                if not player_data[v] then
                    player_data[v] = {data_tosave}
                else
                    player_data[v][#(player_data[v])+1] = data_tosave
                    if #(player_data[v]) > 5 then
                        table.remove(player_data[v], 1)
                    end
                end

                if #(player_data[v]) >= 5 then
                    local last_data = player_data[v]
                    if isImmobile(last_data, 1) then
                        if not afk_statuses[v] then
                            afk_positions[v] = data_tosave.pos
                            afk_statuses[v] = true
                            print("AutoAFK: "..v.." is now AFK")
                            queueMessage("\xA7a"..v.." is now AFK", "!", "<>")
                            queueToast("\xA7cNo movement for 5min, AFK enabled automatically!", "Auto-AFK", v, "!", "<>")
                        end
                    end
                end
            end

            if not compareData(data_tosave.pos, afk_positions[v] or {}, 5) then
                if afk_statuses[v] then
                    afk_statuses[v] = false
                    print("AutoAFK: "..v.." is no longer AFK")
                    queueMessage("\xA7c"..v.." is no longer AFK", "!", "<>")
                    queueToast("\xA7aMovement detected, AFK disabled automatically!", "Auto-AFK", v, "!", "<>")
                    player_data[v] = {}
                end
            end
        end
        if os.epoch("utc") >= save_pos_timer then
            save_pos_timer = os.epoch("utc") + save_pos_delay
        end
        sleep(1)
    end
end

queueToast("AFK Manager has started!", "AFK-Util", "JajaSteele", "!", "<>")
while true do
    local stat, err = pcall(function()
        parallel.waitForAll(chatListener, chatManager, joinListener, autoAFK)
    end)
    if not stat then print(err) end
    sleep(0.25)
end
local cb = peripheral.find("chatBox")

local config = {}

if fs.exists("cfg_door_ctrl.txt") then
    local cfg_file = io.open("cfg_door_ctrl.txt","r")
    config = textutils.unserialise(cfg_file:read("*a"))
    cfg_file:close()
else
    print("Starting Config!")
    print("Redstone Side?")
    config.side_open = read()
    print("Password Player?")
    config.admin = read()
    local cfg_file = io.open("cfg_door_ctrl.txt","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

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

local messageThread = function()
    while true do
        local sleep_time = 0
        for k,v in ipairs(message_queue) do
            if v.type == "plain" then
                if v.whisper then
                    cb.sendMessageToPlayer(v.text, v.player, "\xA7bDoor-CTRL\xA7r")
                else
                    cb.sendMessage(v.text, "\xA7bDoor-CTRL\xA7r")
                end
            elseif v.type == "formatted" then
                if v.whisper then
                    cb.sendFormattedMessageToPlayer(v.text, v.player, "\xA7bDoor-CTRL\xA7r")
                else
                    cb.sendFormattedMessage(v.text, "\xA7bDoor-CTRL\xA7r")
                end
            end
            table.remove(message_queue, k)
            sleep_time = 1.1
            break
        end
        sleep(sleep_time)
    end
end

local function waitMsg(name)
    while true do
        local event, username, message = os.pullEvent("chat")
        if name and name == username then
            return message
        elseif not name then
            return message
        end
    end
end

local mainThread = function()
    while true do
        local event, username, message = os.pullEvent("chat")
        if message:lower():sub(1,8) == "jjs door" then
            local choice = message:lower():sub(10,message:len())
            os.sleep(1)
            if choice == "toggle" then
                config.pass = tostring(math.random(1000,9999))
                sendMessage("Password? \xA77(use $ prefix to hide it from other players)", username, true)
                sendMessage("Password: \xA7b"..config.pass, config.admin, true)
                local pass = waitMsg(username)
                if pass == config.pass then
                    sendMessage("\xA7aPassword Accepted!", username, true)
                    os.sleep(1)
                    rs.setOutput(config.side_open, true)
                    os.sleep(0.5)
                    rs.setOutput(config.side_open, false)
                else
                    sendMessage("\xA7cPassword Denied!", username, true)
                end
            else
                sendMessage("\xA7cIncorrect Action.", username, true)
            end
        end
    end
end

parallel.waitForAny(mainThread, messageThread)
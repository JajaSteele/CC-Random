local chat_box = peripheral.find("chatBox")

local modems = {peripheral.find("modem")}

local player_detector = peripheral.find("playerDetector")

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.broadcast({message="Chat Broadcast System has started."}, "chat_misc_broadcast")
end

local function chatThread()
    while true do
        local event, username, message, uuid, hidden = os.pullEvent("chat")
        if not hidden then
            rednet.broadcast({message=message, username=username}, "chat_event_broadcast")
            print("Broadcasted:\n"..message.."\n"..username)
        end
    end
end

local function playerThread()
    while true do
        if player_detector then
            local event, username = os.pullEvent()
            local message = ""
            if event == "playerJoin" then
                message = username.." joined the game."
                print(username.." Joined the game")
            elseif event == "playerLeave" then
                message = username.." left the game."
                print(username.." Left the game")
            elseif event == "playerClick" and username == "JajaSteele" then
                message = username.." Clicked the detector. (This is a test message)"
                print(username.." Clicked the game")
            end

            if #message > 0 then
                rednet.broadcast({message=message}, "chat_player_broadcast")
                print("Broadcasted:\n"..message)
            end
        else
            sleep(10)
        end
    end
end

parallel.waitForAll(playerThread, chatThread)
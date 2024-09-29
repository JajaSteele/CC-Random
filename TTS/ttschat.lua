local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local speaker = peripheral.find("speaker")
local chat = peripheral.find("chatBox")

local default_voice = "Microsoft Michelle Online"
local jaja_voice = "Microsoft Andrew Online"

local tts_queue = {{
    msg="TTS Chat is now enabled",
    voice=default_voice
}}

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

local args = {...}

local rednet_mode = false

if modem then
    rednet.open(peripheral.getName(modem))
    rednet_mode = true
    print("Rednet Mode enabled")
end

if args[2] then
    if args[2] == "y" or args[2] == "yes" or args[2] == "true" then
        rednet_mode = true
        print("Rednet Mode enabled by arg2")
    else
        rednet_mode = false
        print("Rednet Mode disabled by arg2")
    end
end

local volume = 1.5

if tonumber(args[1]) then
    volume = tonumber(args[1])
    print("Volume set to "..volume.." by arg1")
end

local function playAudio(link)
    local request = http.get(link,nil,true)
    while true do
        local chunk = request.read(16*1024)
        if chunk == nil then break end
        local buffer = decoder(chunk)

        while not speaker.playAudio(buffer, volume) do
            os.pullEvent("speaker_audio_empty")
        end
    end
    request.close()
end

local function ttsThread()
    while true do
        local last_queue = tts_queue[1]
        if last_queue then
            playAudio("http://jajasteele.duckdns.org:2456/?tts="..textutils.urlEncode(last_queue.msg).."&voice="..textutils.urlEncode(last_queue.voice))
            table.remove(tts_queue, 1)
            sleep(0.5)
        else
            sleep(0)
        end
    end
end

local function chatThread()
    while true do
        if not rednet_mode then
            local event, username, msg, hidden = os.pullEvent("chat")

            local voice

            if username == "JajaSteele" then
                voice = jaja_voice
            else
                voice = default_voice
            end

            if username then
                tts_queue[#tts_queue+1] = {msg=msg, voice=voice}
                print(voice.." : "..msg)
            end
        else
            sleep(10)
        end
    end
end

local function rednetThread()
    while true do
        if rednet_mode then
            local id, msg, prot = rednet.receive()

            if prot == "chat_event_broadcast" then
                if type(msg) == "table" and msg.username and msg.message then
                    local voice

                    if msg.username == "JajaSteele" then
                        voice = jaja_voice
                    else
                        voice = default_voice
                    end

                    tts_queue[#tts_queue+1] = {msg=msg.message, voice=voice}
                    print(voice.." : "..msg.message)
                end
            elseif prot == "chat_misc_broadcast" then
                local voice = default_voice
    
                tts_queue[#tts_queue+1] = {msg=msg.message, voice=voice}
                print(voice.." : "..msg.message)
            end
        else
            sleep(10)
        end
    end
end

local function playerThread()
    while true do
        if peripheral.find("playerDetector") then
            local event, username = os.pullEvent()

            if event == "playerJoin" then
                tts_queue[#tts_queue+1] = {msg=username.." Joined the game", voice=default_voice}
                print(username.." Joined the game")
            elseif event == "playerLeave" then
                tts_queue[#tts_queue+1] = {msg=username.." Left the game", voice=default_voice}
                print(username.." Left the game")
            end
        else
            if rednet_mode then
                local id, msg, prot = rednet.receive("chat_player_broadcast")
    
                if type(msg) == "table" and msg.message then
                    local voice = default_voice
    
                    tts_queue[#tts_queue+1] = {msg=msg.message, voice=voice}
                    print(voice.." : "..msg.message)
                end
            else
                sleep(10)
            end
        end
    end
end

while true do
    local stat, err = pcall(function()
        print("Starting Threads..")
        parallel.waitForAny(chatThread, rednetThread, ttsThread, playerThread)
    end)
    if not stat then
        print(err)
        sleep(0.5)
    end
    sleep()
end
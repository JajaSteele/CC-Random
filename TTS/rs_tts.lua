local stat, err = pcall(function()
    local dfpwm = require("cc.audio.dfpwm")
    local decoder = dfpwm.make_decoder()
    local speaker = peripheral.find("speaker")
    local completion = require("cc.completion")

    local config = {}

    if fs.exists("config_rs_tts.txt") then
        local config_file = io.open("config_rs_tts.txt", "r")
        config = textutils.unserialise(config_file:read("*a"))
        config_file:close()
    else
        local voice_list = {}

        local voice_req = http.get("http://jajasteele.duckdns.org:2456/?listVoices=true", nil, nil)
        if voice_req then
            voice_list = textutils.unserialiseJSON(voice_req:readAll())
            voice_req:close()
        end
        print("Select redstone side:")
        config.side = read(nil, nil, function(text) return completion.side(text) end, nil)

        print("TTS Text (ON Signal) (or 'none' to disable):")
        config.text_on = read()

        print("TTS Text (OFF Signal) (or 'none' to disable):")
        config.text_off = read()

        print("TTS Voice:")
        config.voice = read(nil, nil, function(text) return completion.choice(text, voice_list) end)

        local config_file = io.open("config_rs_tts.txt", "w")

        config_file:write(textutils.serialise(config))

        config_file:close()
    end

    local function playAudio(link)
        local request = http.get(link,nil,true)
        while true do
            local chunk = request.read(16*1024)
            if chunk == nil then break end
            local buffer = decoder(chunk)

            while not speaker.playAudio(buffer) do
                os.pullEvent("speaker_audio_empty")
            end
        end
        request.close()
    end

    local last_input = rs.getAnalogInput(config.side)
    local new_input = rs.getAnalogInput(config.side)

    while true do
        os.pullEvent("redstone")
        last_input = new_input
        new_input = rs.getAnalogInput(config.side)

        if last_input == 0 and new_input > 0 and config.text_on ~= "none" then
            print("Playing TTS for ON")
            playAudio("http://jajasteele.duckdns.org:2456/?tts="..textutils.urlEncode(config.text_on).."&voice="..textutils.urlEncode(config.voice))
        elseif last_input > 0 and new_input == 0 and config.text_off ~= "none" then
            print("Playing TTS for OFF")
            playAudio("http://jajasteele.duckdns.org:2456/?tts="..textutils.urlEncode(config.text_off).."&voice="..textutils.urlEncode(config.voice))
        end
    end
end)

if not stat then print(err) sleep(5) os.reboot() end
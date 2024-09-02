local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local speakers = {peripheral.find("speaker")}

local speaker_audio_threads = {}

local function playAudio(link)
    local request = http.get(link,nil,true)
    if request then
        while true do
            local chunk = request.read(2*1024)
            if chunk == nil then break end
            local buffer = decoder(chunk)

            speaker_audio_threads = {}
            for k,speaker in pairs(speakers) do
                speaker_audio_threads[#speaker_audio_threads+1] = function()
                    local name = peripheral.getName(speaker)
                    while not speaker.playAudio(buffer, 3) do
                        repeat 
                            local event, ev_name = os.pullEvent("speaker_audio_empty")
                        until ev_name == name
                    end
                end
            end
            parallel.waitForAll(table.unpack(speaker_audio_threads))
        end
        request.close()
    else
        print("Couldn't reach TTS Server")
    end
end

local function audioPlayer()
    while true do
        playAudio("http://jajasteele.duckdns.org:2456/?tts="..textutils.urlEncode("Testing TTS volume and syncing").."&voice="..textutils.urlEncode("Microsoft Zira Desktop"))
        sleep(10)
    end
end

local function speakerAdder()
    while true do
        local event = os.pullEvent()
        if event == "peripheral" or event == "peripheral_detach" then
            speakers = {peripheral.find("speaker")}
        end
    end
end

parallel.waitForAll(audioPlayer, speakerAdder)
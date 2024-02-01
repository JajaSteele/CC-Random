local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local speaker = peripheral.find("speaker")
local completion = require("cc.completion")

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

print("Enter Text:")
local text = read()



local voice_list = {}

local voice_req = http.get("http://172.16.143.50/?listVoices=true", nil, nil)
if voice_req then
    voice_list = textutils.unserialiseJSON(voice_req:readAll())
    voice_req:close()
end

print("Enter Voice:")
local voice = read(nil, nil, function(text) return completion.choice(text, voice_list) end)

playAudio("http://172.16.143.50/?tts="..textutils.urlEncode(text).."&voice="..textutils.urlEncode(voice))
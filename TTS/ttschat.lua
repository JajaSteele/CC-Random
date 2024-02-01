local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()
local speaker = peripheral.find("speaker")
local chat = peripheral.find("chatBox")

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

while true do
    local event, username, msg, hidden = os.pullEvent("chat")

    local voice

    if username == "JajaSteele" then
        voice = "Microsoft David Desktop"
    else
        voice = "Microsoft Zira Desktop"
    end

    if username then
        playAudio("http://172.16.143.50/?tts="..textutils.urlEncode(msg).."&voice="..voice)
    end
end
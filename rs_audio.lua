local dfpwm = require("cc.audio.dfpwm")
speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()
local config = {}

if fs.exists("cfg_rs_audio.txt") then
    local cfg_file = io.open("cfg_rs_audio.txt","r")
    config = textutils.unserialise(cfg_file:read("*a"))
    cfg_file:close()
else
    print("Starting Config!")
    print("Side?")
    config.side = read()
    print("Audio Url?")
    config.url = read()
    local cfg_file = io.open("cfg_rs_audio.txt","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

local function playAudio(link)
    request = http.get(link,nil,true)
    for i1=1, request.readAll():len()/(16*1024) do
        request.seek("set",(16*1024)*(i1-1))
        local chunk = request.read(16*1024)
        if chunk == nil then break end
        local buffer = decoder(chunk)

        if not isPlaying or isSkipping then speaker.stop() request.close() debug("loop1 exit") return end

        while not speaker.playAudio(buffer) and isPlaying and not isSkipping do
            os.pullEvent("speaker_audio_empty")
        end
    end
    request.close()
end

local old_signal = 0

while true do
    old_signal = redstone.getAnalogInput(config.side)
    local os.pullEvent("redstone")
    local new_signal = redstone.getAnalogInput(config.side)
    if new_signal > 0 and old_signal == 0 then
        print("Playing Audio!")
        playAudio(config.url)
    end
end
    
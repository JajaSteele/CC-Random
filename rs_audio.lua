local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
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

local old_signal = 0

while true do
    old_signal = redstone.getAnalogInput(config.side)
    os.pullEvent("redstone")
    local new_signal = redstone.getAnalogInput(config.side)
    if new_signal > 0 and old_signal == 0 then
        print("Playing Audio!")
        speaker.stop()
        playAudio(config.url)
    end
end
    
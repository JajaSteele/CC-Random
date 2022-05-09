local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")

local decoder = dfpwm.make_decoder()

print("Mode: audio, sound")
mode = io.read()

if mode == "audio" then
    while true do
        print("Choose music Path: (.dfpwm files)")
        path = io.read()
        os.sleep(1)
        if speaker ~= nil then
            for chunk in io.lines(path, 16 * 1024) do
                local buffer = decoder(chunk)
            
                while not speaker.playAudio(buffer,20) do
                    os.pullEvent("speaker_audio_empty")
                end
            end
        end
    end
else
    while true do
        print("Choose sound:")
        path = io.read()
        os.sleep(1)
        speaker.playSound(path)
    end
end
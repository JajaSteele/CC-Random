local dfpwm = require("cc.audio.dfpwm")
local speaker = peripheral.find("speaker")
local decoder = dfpwm.make_decoder()
local monitor = peripheral.find("monitor")
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
    print("Additional Audio Url?")
    config.url2 = read()
    print("Text to Write?")
    config.txt = read()
    print("Text writing delay?")
    config.txt_delay = tonumber(read())
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

local maxX, maxY = monitor.getSize()
for i1=1, maxX do
    for i2=1, maxY do
        monitor.setCursorPos(i1,i2)
        monitor.write(" ")
    end
    os.sleep(0.05)
end

while true do
    old_signal = redstone.getAnalogInput(config.side)
    os.pullEvent("redstone")
    local new_signal = redstone.getAnalogInput(config.side)
    if new_signal > 0 and old_signal == 0 then
        print("Playing Audio!")
        speaker.stop()
        playAudio(config.url)
        monitor.clear()
        monitor.setCursorPos(1,1)
        local maxX, maxY = monitor.getSize()
        for i1=1, config.txt:len() do
            local currX,currY = monitor.getCursorPos()
            if (config.txt:sub(i1,i1) == "\n") then
                monitor.setCursorPos(1,currY+1)
            else
                monitor.write(config.txt:sub(i1,i1))
            end
            if currX == maxX then
                monitor.setCursorPos(1,currY+1)
            end
            os.sleep(config.text_delay)
        end
        playAudio(config.url2)
        os.sleep(6)
        for i1=1, maxX do
            for i2=1, maxY do
                monitor.setCursorPos(i1,i2)
                monitor.write(" ")
            end
            os.sleep(0.05)
        end
    end
end
    
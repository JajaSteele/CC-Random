player_dt = peripheral.find("playerDetector")

rs = redstone
c = colors

bundled_bottom = 0

soundPlay = {}

function playAudio(t)
    for chunk in io.lines("/audio/"..t, 16 * 1024) do
        local buffer = decoder(chunk)
    
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function audioThread()
    while true do
        if #soundPlay > 0 then
            for k,v in pairs(soundPlay) do
                playAudio(v)
            end
        end
    end
end

function clickThread()
    while true do
        local event , username = os.pullEvent("playerClick")
        if username == "JajaSteele" then
            print("Opening")
            bundled_bottom = c.combine(bundled_bottom,c.white)
            os.sleep(5)
            print("Closing")
            bundled_bottom = c.subtract(bundled_bottom,c.white)
        end
    end
end

function rsThread()
    while true do
        rs.setBundledOutput("bottom",bundled_bottom)
        os.sleep(0.25)
    end
end

parallel.waitForAll(rsThread,clickThread,audioThread)
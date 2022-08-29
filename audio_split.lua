local dfpwm = require("cc.audio.dfpwm")
speaker = peripheral.find("speaker")

if speaker == nil then
    pocket.unequipBack()
    os.sleep(0.5)
    pocket.equipBack("speaker")
    speaker = peripheral.find("speaker")
    if speaker == nil then
        print("No Speaker Found!")
        return
    end
end

local decoder = dfpwm.make_decoder()

local function playAudio(t)
    for chunk in io.lines(t, 16 * 1024) do
        local buffer = decoder(chunk)
    
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end

function clearFolder(f)
    filelist = fs.list(f)
    for k,v in pairs(filelist) do
        fs.delete(v)
    end
    fs.delete(f)
    fs.makeDir(f)
end

if fs.exists("/audio") then
    filelist = fs.list("/audio/")
    for k,v in pairs(filelist) do
        fs.delete(v)
    end
else
    fs.makeDir("/audio")
end

function play()
    while true do
        id = curr_seg-1
        if curr_seg ~= play_seg then
            clearFolder("/audio")
            shell.run("wget "..linkbase..id..".dfpwm /audio/audio.dfpwm")
            if fs.exists("/audio/audio.dfpwm") then
                print("Playing Segment #"..id)
            else
                error("FAILED TO DL")
                return
            end
            play_seg = curr_seg
            playAudio("/audio/audio.dfpwm")
        end
        if nextSegment == true then
            curr_seg = curr_seg+1
            nextSegment = false
        end
    end
end

function timer()
    while true do
        for i1=1, length do
            os.sleep()
        end
        nextSegment = true
    end
end

while true do
    print("Hello! Please enter audio linkbase")
    linkbase = io.read()
    print("Segment Count:")
    segments = tonumber(io.read())
    print("Segment Length:")
    length = tonumber(io.read())

    curr_seg = 1
    play_seg = 0

    parallel.waitForAny(play,timer)
end

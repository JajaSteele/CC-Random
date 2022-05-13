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

c = colors

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end
local function setpos(x,y)
    term.setCursorPos(x,y)
end
local function sethome(x,y)
    term.setCursorPos(x,y)
    homeX = x
    homeY = y
end
local function down()
    currX,currY = term.getCursorPos()
    term.setCursorPos(homeX,currY+1)
end
local function w(t)
    term.write(t)
end
local function wd(t)
    term.write(t)
    down()
end
local function sc(c)
    term.setTextColor(c)
end
local function sbc(c)
    term.setBackgroundColor(c)
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

mX,mY = term.getSize()

function play()
    while true do
        id = curr_seg-1
        if curr_seg ~= play_seg and curr_seg <= segments then
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
        if nextSegment == true and curr_seg ~= segments then
            curr_seg = curr_seg+1
            nextSegment = false
        end
        os.sleep(0.75)
    end
end

function timer()
    while true do
        for i1=1, length do
            os.sleep(1)
            clear()
            sethome(1,1)
            wd("Playing")
            sethome(2,2)
            wd("Segment: "..curr_seg.."/"..segments)
            wd("Segment Time Left: "..(length-i1).."s")
            setpos(1,mY)
            w("M-Click to quit")
        end
        nextSegment = true
    end
end

function keyListener()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        if button == 3 then
            speaker.stop()
            clearFolder("/audio")
            os.reboot()
        end
        os.sleep(0.5)
    end
end

while true do
    speaker.stop()
    print("Hello! Please enter audio linkbase")
    linkbase = io.read()
    print("Segment Count:")
    segments = tonumber(io.read())
    print("Segment Length:")
    length = tonumber(io.read())

    curr_seg = 1
    play_seg = 0

    parallel.waitForAny(play,timer,keyListener)
end

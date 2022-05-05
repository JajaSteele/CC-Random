mt = peripheral.find("monitor")
tardis = peripheral.find("tardisinterface")
speaker = peripheral.find("speaker")

local dfpwm = require("cc.audio.dfpwm")
local decoder = dfpwm.make_decoder()

local function playAudio(t)
    if speaker ~= nil then
        for chunk in io.lines(t, 16 * 1024) do
            local buffer = decoder(chunk)
        
            while not speaker.playAudio(buffer,20) do
                os.pullEvent("speaker_audio_empty")
            end
        end
    end
end

if fs.exists("/soundfiles") == false then
    print("Missing Soundfiles!")
    if speaker ~= nil then
        print("Downloading..")
        fs.makeDir("/soundfiles")

        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-HELLOWORLD.dfpwm /soundfiles/helloworld.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-LANDING.dfpwm /soundfiles/landing.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-LOWFUEL.dfpwm /soundfiles/lowfuel.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-REACHED.dfpwm /soundfiles/reached.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-TAKINGOFF.dfpwm /soundfiles/takingoff.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-HELLOWORLD2.dfpwm /soundfiles/helloworld2.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-DANGERSUBSYS.dfpwm /soundfiles/dangersubsys.dfpwm")

        print("Done!")
        playAudio("/soundfiles/helloworld2.dfpwm")
    else
        print("No Speaker detected, skipping download!")
    end
else
    file1 = io.open("/soundfiles/helloworld.dfpwm","r")
    file2 = io.open("/soundfiles/landing.dfpwm","r")
    file3 = io.open("/soundfiles/lowfuel.dfpwm","r")
    file4 = io.open("/soundfiles/reached.dfpwm","r")
    file5 = io.open("/soundfiles/takingoff.dfpwm","r")
    file6 = io.open("/soundfiles/helloworld2.dfpwm","r")
    file7 = io.open("/soundfiles/dangersubsys.dfpwm","r")
    if #fs.list("/soundfiles") == 7 then
        print("All soundfiles validated!")
    else
        print("Missing soundfiles!")

        print("Downloading..")
        
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-HELLOWORLD.dfpwm /soundfiles/helloworld.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-LANDING.dfpwm /soundfiles/landing.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-LOWFUEL.dfpwm /soundfiles/lowfuel.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-REACHED.dfpwm /soundfiles/reached.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-TAKINGOFF.dfpwm /soundfiles/takingoff.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-HELLOWORLD2.dfpwm /soundfiles/helloworld2.dfpwm")
        shell.run("wget https://github.com/JJS-Laboratories/CC-Random/raw/main/Tardis%20Screen%205x3_Monitor/soundfiles/TTS-Kimberly-DANGERSUBSYS.dfpwm /soundfiles/dangersubsys.dfpwm")

        print("Done!")
        playAudio("/soundfiles/helloworld2.dfpwm")
    end
end

local function slowprint(t,d)
    length = string.len(t)
    for i1=1, length do
        mt.write(string.sub(t,i1,i1))
        os.sleep(d)
    end
end

local function setpos(x,y)
    mt.setCursorPos(x,y)
end

local function sethome(x,y)
    mt.setCursorPos(x,y)
    homeX = x
    homeY = y
end

local function down()
    currX,currY = mt.getCursorPos()
    mt.setCursorPos(homeX,currY+1)
end

local function w(t)
    mt.write(t)
end

local function wd(t)
    mt.write(t)
    down()
end

local function sc(c)
    mt.setTextColor(c)
end

local function sbc(c)
    mt.setBackgroundColor(c)
end

local function draw(c,x,y)
    oldX,oldY = mt.getCursorPos()
    mt.setCursorPos(x,y)
    mt.write(c)
    mt.setCursorPos(oldX,oldY)
end

dimlist = tardis.getDimensions()

c = colors

sc(c.white)
sbc(c.black)

sethome(1,1)
sc(c.white)

mX, mY = mt.getSize()

mt.clear()

wd("Vortex Scrap")
sc(c.lightGray)
wd("Randomiser")
wd("Ext. Facing") down()

os.sleep(0.25)
sc(c.white)
wd("Time Winds")
sc(c.lightGray)
wd("Throttle") down()

os.sleep(0.25)
sc(c.white)
wd("Spatial Drift")
sc(c.lightGray)
wd("X/Y/Z Ctrl") down()

os.sleep(0.25)
sc(c.white)
wd("Low Art. Flow")
sc(c.lightGray)
wd("Refueler Ctrl") down()

for i1=1, mY-7 do
    setpos(15,i1)
    w("|")
end

sethome(17,1)
os.sleep(0.25)
sc(c.white)

wd("Ext. Bulkhead")
sc(c.lightGray)
wd("Door Control") down()

os.sleep(0.25)
sc(c.white)
wd("Dim. Drift")
sc(c.lightGray)
wd("Dim. Control") down()

os.sleep(0.25)
sc(c.white)
wd("Vert. Disp.")
sc(c.lightGray)
wd("Vert. Land Type Ctrl") down()

os.sleep(0.25)
sc(c.white)
wd("Artron Pocket")
sc(c.lightGray)
wd("Ext. Facing") 
wd("Refueler Ctrl") down()

dimDisplay = 1

safeModeEngaged = 0

audioLoop = false
audioLoopN = 0

longDangersys = {}

playAudio("/soundfiles/helloworld.dfpwm")

function mainUI()
    while true do
        currArtron = tardis.getArtronBank()
        maxArtron = 2560
        percentage = currArtron / maxArtron
        setpos(2,14)
        sc(c.white)
        sbc(c.black)
        mt.clearLine()
        mt.write(string.format("%.1f%%",percentage*100))
        if tardis.isRefueling() then
            sc(c.green)
        else
            sc(c.white)
        end
        draw("[",9,14) 
        draw("] "..string.format("%.0f",currArtron).."/"..maxArtron.."AU",10+(mX*0.5),14)
        setpos(10,14)
        sbc(c.red)
        sc(c.black)
        mt.write(string.rep(string.char(0x7F),mX*0.5))
        setpos(10,14)
        sbc(c.lime)
        sc(c.white)
        mt.write(string.rep(string.char(0x7F),percentage*(mX*0.5)))

        sc(c.white)
        sbc(c.black)

        subsys = tardis.getSubSystems()

        damagedsys = {}
        dangeroussys = {}

        for k,v in pairs(subsys) do
            health = tardis.getSubSystemHealth(v)
            if health < 0.30 and health > 0.165 then
                table.insert(damagedsys,v)
            end
            if health < 0.165 then
                table.insert(dangeroussys,v)
            end
        end

        sethome(2,16) mt.clearLine()

        if #damagedsys ~= 0 or #dangeroussys ~= 0 or audioLoop == true then
            sc(c.red)
            if #damagedsys == 1 then
                wd("WARNING | Damaged Subsystem:")
            else
                wd("WARNING | "..#damagedsys.." Damaged Subsystems:")
            end
            sc(c.orange)
            mt.clearLine()
            w(table.concat(damagedsys,", "))
            if #dangeroussys ~= 0 then
                longDangersys = dangeroussys
                if #damagedsys ~= 0 then
                    w(", ")
                end
                sc(c.red)
                w(table.concat(dangeroussys,", "))
                if tardis.getAlarm() == false then
                    tardis.setAlarm(true)
                    audioLoop = true
                end
            else
                stopAlarm = true
                for k,v in pairs(longDangersys) do
                    health = tardis.getSubSystemHealth(v)
                    if health ~= health or health < 0.165 then
                        stopAlarm = false
                    end
                end
                if stopAlarm or tardis.getAlarm() == false then
                    tardis.setAlarm(false)
                    audioLoop = false
                end
            end
        else
            sc(c.white)
            wd("No Damaged Subsystems")
            mt.clearLine()
        end

        if safeModeEngaged == 0 then
            sc(c.white)
        end
        if safeModeEngaged == 1 then
            sc(c.orange)
        end
        if safeModeEngaged == 2 then
            sc(c.red)
        end

        if safeModeEngaged < 2 then
            draw("[SAFEZONE]",mX-10,16)
        else
            draw(">SAFEZONE<",mX-10,16)
        end

        if timeleft2 ~= nil then
            draw("ETA:"..timeleft2.."s",mX-10,16)
        end

        if audioLoop == true then
            if audioLoopN == 0 then
                playAudio("/soundfiles/dangersubsys.dfpwm")
                audioLoopN = 10
            else
                audioLoopN = audioLoopN-1
            end
        end

        sc(c.white)
        
        draw("[TRAVEL]",mX-18,16)

        setpos(mX-18,15) mt.clearLine()

        if flightEta ~= nil then
            draw("ETA: "..flightEta.."s",mX-18,15)
        end

        sethome(2,18)
        posX,posY,posZ = tardis.getLocation()
        posDim,posDimName = tardis.getCurrentDimension()
        tarX,tarY,tarZ = tardis.getDestination()
        tarDim,tarDimName = tardis.getDestinationDimension()
        sc(c.white)
        mt.clearLine()
        w("Current Pos:") 
        sc(c.red)
        w(" X"..posX)
        sc(c.green)
        w(" Y"..posY)
        sc(c.blue)
        w(" Z"..posZ)
        sc(c.magenta)

        if dimDisplay == 1 then
            wd(" D: "..posDim)
        end
        if dimDisplay == 2 then
            wd(" D: "..posDimName)
        end

        sc(c.white)
        mt.clearLine()
        w("Target Pos:") 
        sc(c.red)
        w(" X"..tarX)
        sc(c.green)
        w(" Y"..tarY)
        sc(c.blue)
        w(" Z"..tarZ)
        sc(c.magenta)

        if dimDisplay == 1 then
            w(" D: "..tarDim)
        end
        if dimDisplay == 2 then
            wd(" D: "..tarDimName)
        end

        os.sleep(0.75)
    end
end

function clickListener()
    while true do
        local _, _, tx, ty = os.pullEvent("monitor_touch")

        if ty > 17 then
            if dimDisplay == 1 then
                dimDisplay = 2
            else
                dimDisplay = 1
            end
        end

        if ty == 14 then
            if tardis.isRefueling() then
                tardis.setRefuel(false)
            else
                tardis.setRefuel(true)
            end
        end

        if ty == 16 and tx > mX-11 and safeModeEngaged ~= 2 then
            safeModeEngaged = safeModeEngaged+1
            if safeModeEngaged == 2 then
                tardis.setDoors("CLOSED")
                tardis.setAlarm(true)
                tardis.setHandbrake(false)
                local currX1,currY1,currZ1 = tardis.getLocation()
                tardis.setDestinationAndDimension(currX1, currY1, currZ1, 4)
                tardis.setFlight(1)
                os.sleep(2)
                timeleft2 = tardis.getTimeLeft()
                repeat
                    os.sleep(1)
                    timeleft2 = tardis.getTimeLeft()
                until tardis.getTimeLeft() == 0
                for i1=1, 15 do
                    timeleft2 = 15-i1
                    os.sleep(1)
                end
                tardis.setHandbrake(true)
                tardis.setAlarm(false)
                timeleft2 = nil
                safeModeEngaged = 0
            end
        end

        if ty == 16 and tx < mX-11 and tx > mX-18 then
            tardis.setHandbrake(true)
            os.sleep(1)
            tardis.setHandbrake(false)
            tardis.setDoors("CLOSED")
            os.sleep(1)
            playAudio("/soundfiles/takingoff.dfpwm")
            os.sleep(2)
            if tardis.getArtronBank() < 125 then
                playAudio("/soundfiles/lowfuel.dfpwm")
                os.sleep(3)
            end
            tardis.setFlight(1)
            os.sleep(1)
            flightTime = tardis.getTimeLeft()
            flightTime_r = flightTime+15
            repeat
                flightEta = tardis.getTimeLeft()
                os.sleep(1)
            until flightEta == 0
            playAudio("/soundfiles/landing.dfpwm")
            tardis.setHandbrake(true)
            flightEta = nil
        end
        os.sleep(0.5)
    end
end

parallel.waitForAny(clickListener,mainUI)
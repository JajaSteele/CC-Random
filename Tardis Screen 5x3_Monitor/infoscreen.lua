mt = peripheral.find("monitor")
tardis = peripheral.find("tardisinterface")

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
            if health < 0.30 and health > 0.10 then
                table.insert(damagedsys,v)
            end
            if health < 0.10 then
                table.insert(dangeroussys,v)
            end
        end

        sethome(2,16) mt.clearLine()

        if #damagedsys ~= 0 or #dangeroussys ~= 0 then
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
                if #damagedsys ~= 0 then
                    w(", ")
                end
                sc(c.red)
                w(table.concat(dangeroussys,", "))
                if tardis.getAlarm() ~= false then
                    tardis.setAlarm(true)
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
            tardis.setFlight(1)
            os.sleep(1)
            flightTime = tardis.getTimeLeft()
            flightTime_r = flightTime+15
            for i1=1, flightTime_r do
                flightEta = flightTime_r-i1
                os.sleep(1)
            end
            tardis.setHandbrake(true)
            flightEta = nil
        end
        os.sleep(0.5)
    end
end

parallel.waitForAny(clickListener,mainUI)
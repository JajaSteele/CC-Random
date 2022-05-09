ply_detector = peripheral.find("playerDetector")

completion = require "cc.completion"

if ply_detector == nil then
    pocket.equipBack("playerDetector")
    ply_detector = peripheral.find("playerDetector")
    if ply_detector == nil then
        print("No Player Detector Found!")
        return
    end
end

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

c = colors

local function randomc(c1,c2,percent)
    random = math.random(0,100)
    if percent == nil then
        if random < 50 then
            return c2
        else
            return c1
        end
    else
        if random < percent then
            return c2
        else
            return c1
        end
    end
end



loopMain = 2

function main()
    sbc(c.black)
    sc(c.white)
    while true do
        sbc(c.black)
        sc(c.white)
        clear()
        print("Enter Player Name:")
        name = read(nil, nil, function(text) return completion.choice(text, ply_detector.getOnlinePlayers()) end)
        os.sleep(0.5)
        loopMain = 2
        lastX = 0
        lastY = 0
        lastZ = 0
        lastDim = "none"
        while true do
            data = ply_detector.getPlayerPos(name)
            if data ~= nil then
                sbc(c.black)
                sc(c.lime)
                clear()
                print("Tracking: "..name)
                print(" ")
                print("X: "..data["x"])
                print("Y: "..data["y"])
                print("Z: "..data["z"])
                lastX = data["x"]
                lastY = data["y"]
                lastZ = data["z"]
                print(" ")
                print("Dim: "..data["dimension"])
                lastDim = data["dimension"]
                print(" ")
                print("Pitch: "..string.format("%.1f",data["pitch"]).."°")
                print("Yaw: "..string.format("%.1f",data["yaw"]).."°")
                print(" ")
                print("R-Click to select another player")
                print("M-Click to quit")
            else
                sbc(c.black)
                sc(c.orange)
                clear()
                print("Tracking: "..name)
                print(" ")
                print("X: # Last: "..lastX)
                print("Y: # Last: "..lastY)
                print("Z: # Last: "..lastZ)
                print(" ")
                print("Dim: # Last: "..lastDim)
                print(" ")
                print("Pitch: !NO DATA!")
                print("Yaw: !NO DATA!")
                print(" ")
                print("R-Click to select another player")
                print("M-Click to quit")
            end
            os.sleep(0.25)
            if loopMain < 2 then
                break
            end
        end
        if loopMain < 1 then
            os.reboot()
            break
        end
    end
end

function touch()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        if button == 3 then
            loopMain = 0
        end
        if button == 2 then
            loopMain = 1
        end
        os.sleep(0.5)
        button = nil
    end
end

parallel.waitForAny(touch,main)
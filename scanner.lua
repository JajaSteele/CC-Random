env = peripheral.find("environmentDetector")

if env == nil then
    pocket.equipBack("environmentDetector")
    env = peripheral.find("environmentDetector")
    if env == nil then
        print("No Player Detector Found!")
        return
    end
end

mX, mY = term.getSize()

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

local function getweather()
    if not env.isSunny() then
        if env.isRaining() then
            if env.isThunder() then
                return "Thunder"
            else
                return "Raining"
            end
        end
    else
        return "Sunny"
    end
end

local function clearline()
    term.write(string.rep(" ",mX))
end

local function tobool(b)
    if b then
        return "true"
    else
        return "false"
    end
end

local function wdc(t)
    term.write(t)
    clearline()
    down()
end

local function getmoon()
    moon = env.getMoonName()
    if moon == "Moon.exe not found..." then
        return "Not Night"
    else
        return moon
    end
end

c = colors

sethome(1,1)

clear()

while true do
    setpos(1,1)
    wdc("Environment Scanner:")
    wdc("Time: "..env.getTime())
    wdc("Weather: "..getweather())
    wdc("Biome: "..env.getBiome())
    wdc("Dimension: "..env.getDimensionName())
    wdc("Rads: "..table.concat(env.getRadiation(),"\n"))
    wdc("Light Level: "..env.getBlockLightLevel().." ("..env.getSkyLightLevel()..")")
    wdc("Slime Chunk: "..tobool(env.isSlimeChunk()))
    wdc("Moon Phase: "..getmoon())
    os.sleep(0.25)
end


local cursorX = 1
local cursorY = 1

local function setCursor(x,y)
    cursorX = x
    cursorY = y
    term.setCursorPos(cursorX, cursorY)
end

local function goDown()
    local posX, posY= term.getCursorPos()
    term.setCursorPos(cursorX, posY+1)
end

local function move(x,y)
    local posX, posY= term.getCursorPos()
    term.setCursorPos(posX+x, posY+y)
end

local function clearLine(y)
    local posX, posY= term.getCursorPos()
    local sizeX, _ = term.getSize()
    if type(y) == "table" then
        for k,v in pairs(y) do
            term.setCursorPos(1,v)
            term.write(string.rep(" ",sizeX))
        end
    else
        term.setCursorPos(1,y)
        term.write(string.rep(" ",sizeX))
    end
    term.setCursorPos(posX,posY)
end

term.clear()
setCursor(1,1)

print("Select a Mode:")
print("  1. Single Measurement,\n  2. Constant")

local res = tonumber(io.read())

term.clear()
setCursor(1,1)

local x1,y1,z1 = gps.locate()
term.setTextColor(colors.white)
print("1st Coords:")
term.setTextColor(colors.red)
print("X: "..x1)
term.setTextColor(colors.lime)
print("Y: "..y1)
term.setTextColor(colors.blue)
print("Z: "..z1)

if res == 1 then
    term.setTextColor(colors.white)
    print("\nPress Enter to select 2nd point")
    io.read()

    local x2,y2,z2 = gps.locate()

    setCursor(14,1)

    term.setTextColor(colors.white)
    term.write("2nd Coords:")
    goDown()

    term.setTextColor(colors.red)
    term.write("X2: "..x2)
    goDown()

    term.setTextColor(colors.lime)
    term.write("Y2: "..y2)
    goDown()

    term.setTextColor(colors.blue)
    term.write("Z2: "..z2)
    goDown()

    clearLine({6,7})

    setCursor(1,8)

    term.setTextColor(colors.white)
    print("Distance:")
    term.setTextColor(colors.red)
    print("X: "..string.format("%.2f", x2-x1))
    term.setTextColor(colors.lime)
    print("Y: "..string.format("%.2f", y2-y1))
    term.setTextColor(colors.blue)
    print("Z: "..string.format("%.2f", z2-z1))
    term.setTextColor(colors.white)
    print("All: "..string.format("%.2f", math.abs(x2-x1)+math.abs(y2-y1)+math.abs(z2-z1)))
elseif res == 2 then
    local exit_loop = false
    repeat
        local x2,y2,z2 = gps.locate()
        setCursor(14,1)

        term.setTextColor(colors.white)
        term.write("2nd Coords:")
        goDown()

        term.setTextColor(colors.red)
        term.write("X2: "..x2)
        goDown()

        term.setTextColor(colors.lime)
        term.write("Y2: "..y2)
        goDown()

        term.setTextColor(colors.blue)
        term.write("Z2: "..z2)
        goDown()

        clearLine({6,7})

        setCursor(1,8)

        term.setTextColor(colors.white)
        print("Distance:")
        term.setTextColor(colors.red)
        print("X: "..string.format("%.2f", x2-x1))
        term.setTextColor(colors.lime)
        print("Y: "..string.format("%.2f", y2-y1))
        term.setTextColor(colors.blue)
        print("Z: "..string.format("%.2f", z2-z1))
        term.setTextColor(colors.white)
        print("All: "..string.format("%.2f", math.abs(x2-x1)+math.abs(y2-y1)+math.abs(z2-z1)))

        print("\n\nPress \"Backspace\" to stop.")
        os.startTimer(0.1)
        while true do
            local event, key = os.pullEvent()
            if event == "timer" then
                break
            elseif event == "key" and key == keys.backspace then
                exit_loop = true
                break
            end
        end
    until exit_loop
end

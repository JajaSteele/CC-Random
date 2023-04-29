local file = http.get("https://raw.githubusercontent.com/JJS-Laboratories/CC-Random/main/scrt/alongtimeago.lua")
local cb = peripheral.find("chatBox")

local filmText = [[
    local function clearLine(y)
        local oldX,oldY = term.getCursorPos()
        local sizeX,sizeY = term.getSize()
        term.setCursorPos(1, y)
        term.write(string.rep(" ", sizeX))
        term.setCursorPos(oldX,oldY)
    end
    
    local count = 0
    local length = 0
    term.clear()
    
    for line in string.gmatch( filmText, "([^\n]*)\n") do
        length = length+1
        coroutine.yield()
    end

    local monitor = peripheral.find('monitor')
    
    local function iterator()
        local w,h = monitor.getSize()
        return coroutine.wrap( function()
            for line in string.gmatch( filmText, "([^\n]*)\n") do
                count = count+1
                coroutine.yield(line)
                clearLine(h)
                monitor.setCursorPos(2, h)
                monitor.write("["..string.rep("#", (w-2)*(count/length)))
                monitor.setCursorPos(w, h)
                monitor.write("]")
            end
            return false
        end )
    end\n
]]

filmText = filmText..file.readAll()

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.75)

local stat, err = pcall(load(filmText))

if not stat then print(err) end

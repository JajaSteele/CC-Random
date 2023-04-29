local file = http.get("https://raw.githubusercontent.com/JJS-Laboratories/CC-Random/main/scrt/alongtimeago.lua")
local cb = peripheral.find("chatBox")

local filmText = [[
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

pcall(load(filmText))
    
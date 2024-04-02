rednet.open(peripheral.getName(peripheral.find("modem")))

local last_pos = {}

local function loadSave()
    if fs.exists("digi_lastpos.txt") then
        local file = io.open("digi_lastpos.txt", "r")
        last_pos = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open("digi_lastpos.txt", "w")
    file:write(textutils.serialise(last_pos))
    file:close()
end

loadSave()

term.clear()
term.setCursorPos(1,1)

for k,v in pairs(last_pos) do
    term.setTextColor(colors.yellow)
    print("["..k.."] ("..(v.label or "unknown")..") Last Pos:")
    term.setTextColor(colors.lightGray)
    print("   x:"..(v.x or "?").." y:"..(v.y or "?").." z:"..(v.z or "?"))
    print("   Fuel Level: "..string.format("%.1f%%", ((v.fuel or 0) / (v.fuel_max or 0))*100))
end

local function receiveThread()
    while true do
        local id, msg, protocol = rednet.receive()
        if protocol == "jjs_turtle_newpos" then
            term.setTextColor(colors.yellow)
            print("["..id.."] ("..(msg.label or "unknown")..") New Pos:")
            term.setTextColor(colors.lightGray)
            print("   x:"..(msg.x or "?").." y:"..(msg.y or "?").." z:"..(msg.z or "?"))
            print("   Fuel Level: "..string.format("%.1f%%", ((msg.fuel or 0) / (msg.fuel_max or 0))*100))
            term.setTextColor(colors.yellow)

            if msg.x and msg.y and msg.z then
                last_pos[id] = msg
            end
            writeSave()
        elseif protocol == "jjs_turtle_nofuel" then
            term.setTextColor(colors.red)
            print("["..id.."] ("..(msg.label or "unknown")..") New Pos: [!NO FUEL!]")
            term.setTextColor(colors.orange)
            print("   x:"..(msg.x or "?").." y:"..(msg.y or "?").." z:"..(msg.z or "?"))
            print("   Fuel Level: "..string.format("%.1f%%", ((msg.fuel or 0) / (msg.fuel_max or 0))*100))

            if msg.x and msg.y and msg.z then
                last_pos[id] = msg
            end
            writeSave()
            term.setTextColor(colors.white)
        end
    end
end

local function keyThread()
    while true do
        local event, char = os.pullEvent("char")
        if char == "c" then
            local text = ""
            for k,v in pairs(last_pos) do
                text = text.."\nID: "..k.." Label: "..v.label.." \n "..string.format('  [name:"%d (%s) Position", x:%d, y:%d, z:%d]', k, v.label, v.x, v.y, v.z)
            end
            local cb = peripheral.find("chatBox")
            cb.sendMessageToPlayer(text, "JajaSteele")
        end
    end
end

parallel.waitForAny(receiveThread, keyThread)
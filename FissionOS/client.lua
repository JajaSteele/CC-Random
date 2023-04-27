local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

local args = {...}

local config = {}

if not fs.exists("/FissionOS_clientconfig.txt") then
    local file = io.open("/FissionOS_clientconfig.txt","w")
    file:write(textutils.serialise({saved_id = -1}))
    file:close()
end

local configfile = io.open("/FissionOS_clientconfig.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

rednet.open(peripheral.getName(modem))

local serverID = -1

if config.saved_id >= 0 then
    serverID = config.saved_id
else
    term.clear()
    term.setCursorPos(1,1)

    term.write("Searching servers..")

    local reac_list = {rednet.lookup("FissionOS_Server")}
    for k,v in ipairs(reac_list) do
        term.setCursorPos(1,2)
        term.write("Checking server "..k)
        if v then
            rednet.send(v, "", "serverNameRequest")
            local id, msg, protocol = rednet.receive("serverNameReply",1)
            reac_list[k] = {
                id=v,
                name=msg or "UNKNOWN"
            }
        end
    end

    term.clear()
    term.setCursorPos(1,1)

    print("Reactor List:")

    for k,v in ipairs(reac_list) do
        print("["..v.id.."] - "..v.name)
        os.sleep(0.05)
    end

    print("\nSelect ID: ")

    serverID = tonumber(read())
end

rednet.send(serverID,"","requestNewClient")

local id, msg, protocol = rednet.receive("newClientConfirm",3)

local serverName = msg

if id == nil then
    print("Failed!")
    return
else
    print("Successfully connected!")
end

local last_sent_data = {}

local exit_reason = ""

local function clearLine(y)
    local oldX,oldY = term.getCursorPos()
    local sizeX,sizeY = term.getSize()
    term.setCursorPos(1, y)
    term.write(string.rep(" ", sizeX))
    term.setCursorPos(oldX,oldY)
end
local function writeColor(t,f,b)
    local oldF = term.getTextColor()
    local oldB = term.getBackgroundColor()

    term.setTextColor(f or oldF)
    term.setBackgroundColor(b or oldB)

    term.write(t)

    term.setTextColor(oldF)
    term.setBackgroundColor(oldB)
end

local function clamp(v,min,max)
    if v > max then
        return max
    elseif v < min then
        return min
    else
        return v
    end
end

local function drawAtCoord(t,x,y,f,b)
    local oldF = term.getTextColor()
    local oldB = term.getBackgroundColor()

    local oldX,oldY = term.getCursorPos()

    term.setTextColor(f or oldF)
    term.setBackgroundColor(b or oldB)

    term.setCursorPos(x,y)

    term.write(t)

    term.setCursorPos(oldX,oldY)
    term.setTextColor(oldF)
    term.setBackgroundColor(oldB)
end

local function drawData(data)
    local sizeX,sizeY = term.getSize()

    local temp_bar = clamp((data.temp/2000),0,1)
    local coolant_bar = clamp((data.coolant.amount/data.coolant.capacity),0,1)
    local fuel_bar = clamp((data.fuel.amount/data.fuel.capacity),0,1)
    local waste_bar = clamp((data.waste.amount/data.waste.capacity),0,1)

    term.clear()

    term.setCursorPos(1,1)
    writeColor(string.rep(" ",sizeX), nil, colors.gray)
    term.setCursorPos(1,1)
    writeColor(string.char(0x07), colors.lime, colors.gray)
    writeColor(" Fission", colors.lightGray, colors.gray)
    writeColor("OS", colors.green, colors.gray)
    writeColor(" by ", colors.white, colors.gray)
    writeColor("JJS", colors.lightBlue, colors.gray)

    drawAtCoord("X",sizeX,1,colors.red,colors.gray)

    term.setCursorPos(1,3)
    term.write("Status: ")
    if data.status then
        writeColor("Online",colors.lime)
    else
        writeColor("Offline",colors.red)
    end

    local damage_color = colors.lime
    if data.damage >= 25 then
        damage_color = colors.yellow
        if data.damage >= 50 then
            damage_color = colors.orange
            if data.damage >= 50 then
                damage_color = colors.red
            end
        end
    end

    local temp_color = colors.lime
    if data.temp >= 1000 then
        temp_color = colors.yellow
        if data.temp >= 1350 then
            temp_color = colors.orange
            if data.temp >= 1500 then
                temp_color = colors.red
            end
        end
    end

    term.setCursorPos(sizeX-6,3)
    term.write("D: ")
    writeColor(tostring(data.damage).."%", damage_color)

    term.setCursorPos(1,4)
    term.write("N/ID: ")
    writeColor(serverName.." ",colors.lightGray)
    writeColor("[",colors.gray)
    writeColor(tostring(serverID),colors.green)
    writeColor("]",colors.gray)

    term.setCursorPos(1,6)
    term.write(string.format("Temperature: [%.0fK]", data.temp))
    term.setCursorPos(1,7)
    term.write("[")
    writeColor(string.rep("#",(sizeX-1)*temp_bar), temp_color)
    drawAtCoord("]",sizeX,6)

    term.setCursorPos(1,8)
    term.write(string.format("Coolant: [%.0f mB]", data.coolant.amount))
    term.setCursorPos(1,9)
    term.write("[")
    writeColor(string.rep("#",(sizeX-2)*coolant_bar), colors.blue)
    drawAtCoord("]",sizeX,9)

    term.setCursorPos(1,11)
    term.write(string.format("Fuel: [%.0f mB]", data.fuel.amount))
    term.setCursorPos(1,12)
    term.write("[")
    writeColor(string.rep("#",(sizeX-2)*fuel_bar), colors.green)
    drawAtCoord("]",sizeX,12)

    term.setCursorPos(1,13)
    term.write(string.format("Waste: [%.0f mB]", data.waste.amount))
    term.setCursorPos(1,14)
    term.write("[")
    writeColor(string.rep("#",(sizeX-2)*waste_bar), colors.brown)
    drawAtCoord("]",sizeX,14)

    term.setCursorPos(1,16)
    term.write("Burn Rate: "..data.burn_rate.." mB/t")
    term.setCursorPos(1,17)
    term.write("Boiling Rate: "..data.heating_rate.." mB/t")
    term.setCursorPos(1,18)
    term.write("Rads: ")
    writeColor(data.rads, colors.green)
end

local function clickHandler()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")

        local sizeX,sizeY = term.getSize()
        if y == 3 then
            if last_sent_data.status then
                rednet.send(serverID, "off", "reactorActivate")
            else
                rednet.send(serverID, "on", "reactorActivate")
            end
        elseif y == 1 and x == sizeX then
            exit_reason = "Reason: Closed by user"
            return
        end
    end
end

local function keyHandler()
    while true do
        local event, key, held = os.pullEvent("key")

        local sizeX,sizeY = term.getSize()
        if key == keys.f then
            if config.saved_id >= 0 then
                config.saved_id = -1
                term.setCursorPos(1,sizeY)
                writeColor("Removed Favorite", colors.orange)
            else
                config.saved_id = serverID
                local configfile = io.open("/FissionOS_clientconfig.txt","w")
                configfile:write(textutils.serialise(config))
                configfile:close()
                term.setCursorPos(1,sizeY)
                writeColor("Set Favorite to "..serverID, colors.orange)
            end
        elseif key == keys.r then
            if config.autostart then
                config.autostart = false
                local configfile = io.open("/FissionOS_clientconfig.txt","w")
                configfile:write(textutils.serialise(config))
                configfile:close()

                fs.delete("/startup")
                term.setCursorPos(1,sizeY)
                writeColor("Auto Startup removed", colors.orange)
            else
                config.autostart = true
                local configfile = io.open("/FissionOS_clientconfig.txt","w")
                configfile:write(textutils.serialise(config))
                configfile:close()
                local startupfile = io.open("/startup","a")
                startupfile:write([[ shell.execute("/client.lua")]])
                startupfile:close()
                term.setCursorPos(1,sizeY)
                writeColor("Auto Startup enabled", colors.orange)
            end
        end
    end
end


local function receiveData()
    while true do
        local id, msg, protocol = rednet.receive("dataReceive")

        if id == serverID then
            last_sent_data = textutils.unserialise(msg)
            drawData(last_sent_data)
        end
    end
end

local function pingClient()
    while true do
        local id, msg, protocol = rednet.receive("pingClient_Request")
        rednet.send(id, "", "pingClient_Confirm")
    end
end

local function pingServer()
    while true do
        rednet.send(serverID, "", "pingServer_Request")
        local id, msg, protocol = rednet.receive("pingServer_Confirm",1)
        if id == nil then
            exit_reason = "Reason: Lost connection to FissionOS Server "..serverName.." ("..serverID..")"
            return
        end
        os.sleep(5)
    end
end

parallel.waitForAny(receiveData, pingClient, pingServer, clickHandler, keyHandler)

term.clear()
term.setCursorPos(1,1)

print("FissionOS Closed!\n"..exit_reason)
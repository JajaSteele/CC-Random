local pld = peripheral.find("playerDetector")

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

local args = {...}

local config = {}


if args[1] == "config" or not fs.exists("/hotel_serverconfig.txt") then
    print("Welcome to the configuration wizard!")
    print("Door Name?")
    config.name = read()
    print("RS Side?")
    config.side = read()
    print("Open Time? (in 10th of seconds)")
    config.delay = tonumber(read())
    print("Startup with computer? (y/n)")
    config.autostart = read():lower()
    if config.autostart == "y" then
        config.autostart = true
        local startupfile = io.open("/startup","a")
        startupfile:write([[ shell.execute("/door_server.lua")]])
        startupfile:close()
    else
        config.autostart = false
        fs.delete("/startup")
    end
    print("Owner Name?")
    config.owner = read()

    config.username = "No User"

    print("id_pass?")
    config.id_pass = read()

    config.date = "Never"

    local configfile = io.open("/hotel_serverconfig.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
    
    term.clear(1,1)
    term.setCursorPos(1,1)
end

local configfile = io.open("/hotel_serverconfig.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

local door_timer = 0

-- Config Check
config.name = config.name or "Default Name"
config.side = config.side or "bottom"
config.delay = config.delay or 30
config.autostart = config.autostart or false
config.owner = config.owner or "none"
config.username = config.username or "No User"
config.date = config.date or "Never"
-- End of Config Check


modem.closeAll()
os.sleep(0.1)
rednet.open(peripheral.getName(modem))

rednet.host("hotel_server_"..config.id_pass,config.name)

local function getDate(mode)
    if mode == "shortdate" then
        return os.date("%d/%m %H.%M.%S")
    elseif mode == "shorttime" then
        return os.date("%H.%M.%S")
    end
end

local function nameRequest()
    while true do
        local id, msg, protocol = rednet.receive("serverNameRequest")
        rednet.send(id, config.name, "serverNameReply")
    end
end

local function userRequest()
    while true do
        local id, msg, protocol = rednet.receive("hotelUserRequest")
        if msg == config.id_pass then
            rednet.send(id, config.username, "hotelUserReply")
        else
            rednet.send(id, "DENIED", "hotelUserReply")
        end
    end
end

local function dateRequest()
    while true do
        local id, msg, protocol = rednet.receive("hotelDateRequest")
        if msg == config.id_pass then
            rednet.send(id, config.date, "hotelDateReply")
        else
            rednet.send(id, "DENIED", "hotelDateReply")
        end
    end
end

local function detectPlayer()
    while true do
        local _, player = os.pullEvent("playerClick")
        if player == config.username or player == config.owner then
            door_timer = 30

            if player == config.username then
                config.date = getDate("shortdate")
                local configfile = io.open("/hotel_serverconfig.txt","w")
                configfile:write(textutils.serialise(config))
                configfile:close()
            end
        end
    end
end

local function changeUser()
    while true do
        local auth_id, msg, protocol = rednet.receive("changeHotelUser_Auth")
        if msg == config.id_pass then
            rednet.send(auth_id, "ALLOWED", "changeHotelUser_Auth_Reply")

            local id, msg, protocol = rednet.receive("changeHotelUser_NewUser", 1)
            if msg then
                config.username = msg
                config.date = "Never"

                local configfile = io.open("/hotel_serverconfig.txt","w")
                configfile:write(textutils.serialise(config))
                configfile:close()
            end
        else
            rednet.send(auth_id, "DENIED", "changeHotelUser_Auth_Reply")
        end
    end
end

local function drawMonitor()
    while true do
        local monitor = peripheral.find("monitor")
        if monitor then
            local sizeX, sizeY = monitor.getSize()
            monitor.setBackgroundColor(colors.white)
            monitor.setTextColor(colors.black)
            monitor.clear()
            monitor.setTextScale(0.5)
            monitor.setCursorPos(1,1)
            monitor.write(config.name)
            monitor.setCursorPos(1,3)
            monitor.write(config.username)
            monitor.setCursorPos(1,4)
            monitor.write(config.date)
            if door_timer > 0 then
                monitor.setCursorPos(1,sizeY)
                monitor.write(string.rep("#", sizeX*(door_timer/config.delay)))
            end
        end
        os.sleep(0.5)
    end
end

local function doorTimer()
    while true do
        if door_timer > 0 then
            rs.setOutput(config.side, true)
            door_timer = door_timer-1
        else
            rs.setOutput(config.side, false)
        end
        os.sleep(0.1)
    end
end
            


parallel.waitForAny(nameRequest, detectPlayer, changeUser, userRequest, dateRequest, drawMonitor, doorTimer)
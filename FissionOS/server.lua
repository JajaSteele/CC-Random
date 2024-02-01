local reactor = peripheral.find("fissionReactorLogicAdapter")

repeat
    reactor = peripheral.find("fissionReactorLogicAdapter")
    sleep(1)
until reactor.getStatus ~= nil

local activeClients = {}

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

local args = {...}

local config = {}

if args[1] == "config" or not fs.exists("/FissionOS_serverconfig.txt") then
    print("Welcome to the configuration wizard!")
    print("Reactor Name?")
    config.name = read()
    print("Startup with computer? (y/n)")
    config.autostart = read():lower()
    if config.autostart == "y" then
        config.autostart = true
        local startupfile = io.open("/startup","w")
        startupfile:write([[ shell.execute("/server.lua")]])
        startupfile:close()
    else
        config.autostart = false
        fs.delete("/startup")
    end
    print("Global Chat? (y/n)")
    config.isGlobal = read():lower()
    if config.isGlobal == "y" then
        config.isGlobal = true
    else
        config.isGlobal = false
        print("Owner Name? (for chat)")
        config.owner = read()
    end
    print("Chat Logging Level? (1-3)")
    config.chatLoggingLevel = tonumber(read())

    print("Discord Integration? (y/n)")
    config.isDiscord = read():lower()
    if config.isDiscord == "y" then
        config.isDiscord = true
        print("Discord Logging Level?")
        config.discordLevel = tonumber(read())
        print("Discord Webhook URL")
        config.discordWebhook = read()
    else
        config.isDiscord = false
    end

    local configfile = io.open("/FissionOS_serverconfig.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end

local configfile = io.open("/FissionOS_serverconfig.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

local discord
local discord_hook
local success
local use_discord = false

if config.isDiscord then
    if not fs.exists("/DiscordHook.lua") then
        local file = http.get("https://raw.githubusercontent.com/Wendelstein7/DiscordHook-CC/master/DiscordHook.lua")
        local file2 = io.open("/DiscordHook.lua", "w")
        file2:write(file.readAll())
        file2:close()
        file.close()
    end
    discord = require("DiscordHook")
    success, discord_hook = discord.createWebhook(config.discordWebhook)
    if not success then
        print("Discord failed to connect!")
        use_discord = false
    else
        use_discord = true
    end
end

local loggingLevels = {
    "\xA77[\xA74ERROR\xA77]\xA7c",
    "\xA77[\xA76WARN\xA77]\xA7e",
    "\xA77[\xA7fINFO\xA77]\xA7f",
    "\xA77[\xA7aFORCE-INFO\xA77]\xA7f"
}

local loggingLevels_file = {
    "[ERROR]",
    "[WARN]",
    "[INFO]",
    "[FORCE-INFO]"
}

local loggingLevels_emojis = {
    ":octagonal_sign:",
    ":warning:",
    ":information_source:",
    ":mega:"
}

local logFileName = os.date("%d-%m-%Y_%H.%M.%S")..".log"

local function getDate(mode)
    if mode == "shortdate" then
        return os.date("%d/%m %H.%M.%S")
    elseif mode == "shorttime" then
        return os.date("%H.%M.%S")
    end
end

-- local function chatLog(txt,level)
--     local chatBox = peripheral.find("chatBox")
--     if (level <= config.chatLoggingLevel or level == 4) and chatBox then
--         if config.isGlobal then
--             chatBox.sendMessage("["..getDate("shorttime").."] "..loggingLevels[level]..txt, "FissionOS | "..config.name)
--         else
--             chatBox.sendMessageToPlayer("["..getDate("shorttime").."] "..loggingLevels[level]..txt, config.owner, "FissionOS | "..config.name)
--         end
--     end
-- end
-- 
-- local function fileLog(text,level)
--     if not fs.isDir("/FissionOS_logs") then
--         fs.makeDir("/FissionOS_logs")
--     end
--     if (level <= config.chatLoggingLevel or level == 4) then
--         local logFileRead = io.open("/FissionOS_logs/"..logFileName,"r")
--         local txt
--         if logFileRead then
--             txt = logFileRead:read("*a").."\n".."["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text
--             logFileRead:close()
--         else
--             txt = "["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text
--         end
-- 
--         local logFile = io.open("/FissionOS_logs/"..logFileName,"w")
--         logFile:write(txt)
--         logFile:close()
--     end
-- end

local chatQueue = {}

local function fullLog(text,level)
    if not fs.isDir("/FissionOS_logs") then
        fs.makeDir("/FissionOS_logs")
    end
    if (level <= config.chatLoggingLevel or level == 4) then
        local logFileRead = io.open("/FissionOS_logs/"..logFileName,"r")
        local txt
        if logFileRead then
            txt = logFileRead:read("*a").."\n".."["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text
            logFileRead:close()
        else
            txt = "["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text
        end

        local logFile = io.open("/FissionOS_logs/"..logFileName,"w")
        logFile:write(txt)
        logFile:close()
    end
    local chatBox = peripheral.find("chatBox")
    if (level <= config.chatLoggingLevel or level == 4) and chatBox then
        local new_id = math.random(1000000,9999999)
        if config.isGlobal then
            chatQueue[tostring(new_id)] = {
                text = "["..getDate("shorttime").."] "..loggingLevels[level].." "..text, 
                name = "FissionOS | "..config.name,
                isglobal = true,
                target = ""
            }
        else
            chatQueue[tostring(new_id)] = {
                text = "["..getDate("shorttime").."] "..loggingLevels[level].." "..text, 
                name = "FissionOS | "..config.name,
                isglobal = false,
                target = config.owner
            }
        end
    end
    if config.isDiscord and (level <= config.discordLevel or level == 4) and use_discord then
        discord_hook.send(loggingLevels_emojis[level].." **"..loggingLevels_file[level].."** - "..text, "FissionOS | "..config.name)
    end
        
    print("["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text)
end

modem.closeAll()
os.sleep(0.1)
rednet.open(peripheral.getName(modem))

rednet.host("FissionOS_Server",config.name)

fullLog("Server is now online",4)
os.sleep(1.1)

local function newClient()
    while true do
        local id, msg, protocol = rednet.receive("requestNewClient")
        fullLog("Client ["..id.."] connected.",3)
        local new_id = math.random(1000000,9999999)
        activeClients[tostring(new_id)] = {
            id=id
        }
        rednet.send(id, config.name, "newClientConfirm")
    end
end

local function sendReactorData()
    while true do
        local content = {
            status = reactor.getStatus(),
            temp = reactor.getTemperature(),
            burn_rate = reactor.getBurnRate(),
            fuel = {
                amount = reactor.getFuel().amount,
                type = reactor.getFuel().name,
                capacity = reactor.getFuelCapacity(),
            },
            coolant = {
                amount = reactor.getCoolant().amount,
                type = reactor.getCoolant().name,
                capacity = reactor.getCoolantCapacity()
            },
            waste = {
                amount = reactor.getWaste().amount,
                capacity = reactor.getWasteCapacity()
            },
            heating_rate = reactor.getHeatingRate(),
            damage = reactor.getDamagePercent()

        }
        local envDec = peripheral.find("environmentDetector")
        if envDec then
            local rads = envDec.getRadiation()
            content.rads = string.format("%.2f", rads.radiation).." "..rads.unit
        else
            content.rads = "Unknown"
        end
        for k,v in pairs(activeClients) do
            rednet.send(v.id, textutils.serialise(content), "dataReceive")
        end
        os.sleep(0.1)
    end
end

local function pingClient()
    while true do
        for k,v in pairs(activeClients) do
            rednet.send(v.id, "", "pingClient_Request")
            local id, msg, protocol = rednet.receive("pingClient_Confirm",1)
            if id == nil then
                activeClients[k] = nil
                fullLog("Client ["..v.id.."] disconnected.",3)
            end
        end
        os.sleep(5)
    end
end

local function nameRequest()
    while true do
        local id, msg, protocol = rednet.receive("serverNameRequest")
        rednet.send(id, config.name, "serverNameReply")
        fullLog("Computer ["..id.."] requested server name.",3)
    end
end

local function pingServer()
    while true do
        local id, msg, protocol = rednet.receive("pingServer_Request")
        rednet.send(id, "", "pingServer_Confirm")
    end
end

local function reactorControl()
    while true do
        local id, msg, protocol = rednet.receive()
        if protocol == "reactorActivate" then
            if msg == "on" and not reactor.getStatus() then
                reactor.activate()
            elseif msg == "off" and reactor.getStatus() then
                reactor.scram()
            end
            fullLog("Reactor status changed to ["..msg.."]",2)
        end
    end
end

local function reactorChecks()
    local fuel_warn = false
    while true do
        if reactor.getStatus() then
            if reactor.getTemperature() > 1200 then
                reactor.scram()
                fullLog("High temperature detected! SCRAM",1)
            end
            if reactor.getWaste().amount >= reactor.getWasteCapacity() then
                reactor.scram()
                fullLog("Waste overfilling detected! SCRAM",1)
            end
            if reactor.getDamagePercent() > 90 then
                reactor.scram()
                fullLog("Critical Damages! SCRAM",1)
            end
            if reactor.getFuel().amount < reactor.getFuelCapacity()*0.1 and reactor.getFuel().amount > 10 then
                if not fuel_warn then
                    fuel_warn = true
                    fullLog("Low Fuel",2)
                end
            else
                fuel_warn = false
            end
            if reactor.getFuel().amount <= 10 then
                reactor.scram()
                fullLog("No Fuel!",1)
            end
        end
        coroutine.yield()
    end
end

local function chatManager()
    while true do
        local to_delete = {}
        local chatBox = peripheral.find("chatBox")
        for k,v in pairs(chatQueue) do
            if v.isglobal then
                if chatBox.sendMessage(v.text, v.name) then
                    to_delete[#to_delete+1] = k
                end
            else
                if chatBox.sendMessageToPlayer(v.text, v.target, v.name) then
                    to_delete[#to_delete+1] = k
                end
            end
            os.sleep(1.1)
        end
        for k,v in pairs(to_delete) do
            chatQueue[v] = nil
            to_delete[k] = nil
        end
        coroutine.yield()
    end
end

local stat, err = pcall(function()
    parallel.waitForAny(newClient,sendReactorData,pingClient,pingServer,reactorControl,nameRequest,reactorChecks,chatManager)
end)
if not stat then fullLog("Program Errored: "..err, 2) sleep(1) os.reboot() end
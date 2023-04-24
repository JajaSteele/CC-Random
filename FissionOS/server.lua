local reactor = peripheral.find("fissionReactorLogicAdapter")

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
    print("Global Chat? (Y/N)")
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

    local configfile = io.open("/FissionOS_serverconfig.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end

local configfile = io.open("/FissionOS_serverconfig.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

local loggingLevels = {
    "§7[§6ERROR§7]§c",
    "§7[§eWARN§7]§f",
    "§7[§fINFO§7]§f",
    "§7[§aFORCE-INFO§7]§f"
}

local loggingLevels_file = {
    "[ERROR]",
    "[WARN]",
    "[INFO]",
    "[FORCE-INFO]"
}

local logFileName = "FissionOS_Server-"..os.date("%d-%m-%Y_%H.%M.%S")..".log"

local function chatLog(txt,level)
    local chatBox = peripheral.find("chatBox")
    if (level <= config.chatLoggingLevel or level == 4) and chatBox then
        if config.isGlobal then
            chatBox.sendMessage(loggingLevels[level].." "..txt, "FissionOS | "..config.name)
        else
            chatBox.sendMessageToPlayer(loggingLevels[level].." "..txt, config.owner, "FissionOS | "..config.name)
        end
    end
end

local function fileLog(text,level)
    local chatBox = peripheral.find("chatBox")
    if (level <= config.chatLoggingLevel or level == 4) then
        local logFileRead = io.open("/logs/"..logFileName,"r")
        local txt = logFileRead:read("*a").."\n"..loggingLevels_file[level].." "..text
        logFileRead:close()

        local logFile = io.open("/logs/"..logFileName,"w")
        logFile:write(txt)
        logFile:close()
    end
end
    


modem.closeAll()
os.sleep(0.1)
rednet.open(peripheral.getName(modem))

rednet.host("FissionOS_Server",config.name)

print("FissionOS Starting.. Computer ID: "..os.computerID())
chatLog("Server is now online",4)
fileLog("Server is now online",4)

local function newClient()
    while true do
        local id, msg, protocol = rednet.receive("requestNewClient")
        print("Client ["..id.."] connected.")
        chatLog("Client ["..id.."] connected.",3)
        fileLog("Client ["..id.."] connected.",3)
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
                print("Client ["..v.id.."] disconnected.")
                chatLog("Client ["..v.id.."] disconnected.",3)
                fileLog("Client ["..v.id.."] disconnected.",3)
            end
        end
        os.sleep(5)
    end
end

local function nameRequest()
    while true do
        local id, msg, protocol = rednet.receive("serverNameRequest")
        rednet.send(id, config.name, "serverNameReply")
        fileLog("Computer ["..id.."] requested server name.",3)
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
            if msg == "on" then
                reactor.activate()
            elseif msg == "off" then
                reactor.scram()
            end
            print("Reactor Status set to "..msg)
            chatLog("Reactor status changed to §l"..msg,2)
            fileLog("Reactor status changed to ["..msg.."]",2)
        end
    end
end

local function reactorChecks()
    while true do
        if reactor.getTemperature() > 1200 then
            reactor.scram()
            print("High temperature detected! Shutting down reactor")
            chatLog("High temperature detected! Shutting down reactor",1)
            fileLog("High temperature detected! Shutting down reactor",1)
        end
        if reactor.getWaste().amount >= reactor.getWasteCapacity() then
            reactor.scram()
            print("Waste overfilling detected! Shutting down reactor")
            chatLog("Waste overfilling detected! Shutting down reactor",1)
            fileLog("Waste overfilling detected! Shutting down reactor",1)
        end
        if reactor.getDamagePercent() > 90 then
            reactor.scram()
            print("Critical Damages! Shutting down reactor")
            chatLog("Critical Damages! Shutting down reactor",1)
            fileLog("Critical Damages! Shutting down reactor",1)
        end
        if reactor.getFuel().amount < reactor.getFuelCapacity()*0.1 then
            print("Low Fuel")
            chatLog("Low Fuel",2)
            fileLog("Low Fuel",2)
        end
        if reactor.getFuel().amount <= 10 then
            print("No Fuel!")
            chatLog("No Fuel!",1)
            fileLog("No Fuel!",1)
        end
        coroutine.yield()
    end
end


parallel.waitForAny(newClient,sendReactorData,pingClient,pingServer,reactorControl,nameRequest,reactorChecks)
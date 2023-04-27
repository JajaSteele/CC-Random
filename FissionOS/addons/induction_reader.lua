local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local loggingLevels_file = {
    "[ERROR]",
    "[WARN]",
    "[INFO]",
    "[FORCE-INFO]"
}

local logFileName = os.date("%d-%m-%Y_%H.%M.%S")..".log"

local function getDate(mode)
    if mode == "shortdate" then
        return os.date("%d/%m %H.%M.%S")
    elseif mode == "shorttime" then
        return os.date("%H.%M.%S")
    end
end

local function fileLog(text,level)
    if not fs.isDir("/logs_induction_reader") then
        fs.makeDir("/logs_induction_reader")
    end
    local logFileRead = io.open("/logs_induction_reader/"..logFileName,"r")
    local txt
    if logFileRead then
        txt = logFileRead:read("*a").."\n".."["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text
        logFileRead:close()
    else
        txt = "["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text
    end

    local logFile = io.open("/logs_induction_reader/"..logFileName,"w")
    logFile:write(txt)
    logFile:close()
end

local induc = peripheral.find("inductionPort")

rednet.open(peripheral.getName(modem))

term.clear()
term.setCursorPos(1,1)

local config = {}

local args = {...}

if args[1] == "config" or not fs.exists("/config_induction_reader.txt") then
    print("Welcome to the configuration wizard!")
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

    print("\nSelect ID(s) to control: \n(Use spaces to separate them)")

    local serverIDs = split(read(), " ")

    for k,v in pairs(serverIDs) do
        serverIDs[k] = tonumber(v)
    end

    config.serverIDs = serverIDs

    term.clear()
    term.setCursorPos(1,1)

    print("Charge Percentage Thresholds:")

    print("Activation Threshold? (1-100)")
    config.enableThreshold = tonumber(read())
    print("SCRAM Threshold? (1-100)")
    config.disableThreshold = tonumber(read())

    local configfile = io.open("/config_induction_reader.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end

local configfile = io.open("/config_induction_reader.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

print("Start program. Reactors: ["..table.concat(config.serverIDs,", ").."]",3)
fileLog("Start program. Reactors: ["..table.concat(config.serverIDs,", ").."]",3)

local enabledReactor = false
local disabledReactor = false

local function display()
    while true do
        local energy = mekanismEnergyHelper.joulesToFE(induc.getEnergy())
        local max_energy = mekanismEnergyHelper.joulesToFE(induc.getMaxEnergy())
        term.clear()
        term.setCursorPos(1,1)
        term.write(string.format("%.2f",energy/1000000).."/"..(max_energy/1000000).."MFE ("..string.format("%.1f%%", (energy/max_energy)*100)..")")

        os.sleep(0.5)
    end
end

local function checkCharge()
    while true do
        local energy = mekanismEnergyHelper.joulesToFE(induc.getEnergy())
        local max_energy = mekanismEnergyHelper.joulesToFE(induc.getMaxEnergy())

        local percentage = (energy/max_energy)*100

        if percentage <= config.enableThreshold then -- Enables the reactors
            if not enabledReactor then
                for k,v in pairs(config.serverIDs) do
                    rednet.send(v, "on", "reactorActivate")
                end
                print("Enabled the reactors: ["..table.concat(config.serverIDs,", ").."]",2)
                fileLog("Enabled the reactors: ["..table.concat(config.serverIDs,", ").."]",2)
                enabledReactor = true
            end
        else
            enabledReactor = false
        end

        if percentage >= config.disableThreshold then -- Enables the reactors
            if not disabledReactor then
                for k,v in pairs(config.serverIDs) do
                    rednet.send(v, "off", "reactorActivate")
                end
                print("Disabled the reactors: ["..table.concat(config.serverIDs,", ").."]",2)
                fileLog("Disabled the reactors: ["..table.concat(config.serverIDs,", ").."]",2)
                disabledReactor = true
            end
        else
            disabledReactor = false
        end

        os.sleep(0.5)
    end
end

parallel.waitForAny(display, checkCharge)

term.clear()
term.setCursorPos(1,1)

print("Program Exited",1)
fileLog("Program Exited",1)
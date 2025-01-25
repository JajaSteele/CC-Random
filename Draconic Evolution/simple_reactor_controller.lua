local reactor = peripheral.find("draconic_reactor")
local completion = require "cc.completion"

if not reactor then
    print("Waiting for reactor..")
    repeat
        reactor = peripheral.find("draconic_reactor")
        sleep(0.2)
    until reactor
end

local args = {...}

local config = {}

if args[1] == "config" or not fs.exists("/.draconic_config.txt") then
    print("Welcome to the configuration wizard!")
    print("Reactor Name?")
    config.name = read()

    print("Select the output gate:")
    config.output_gate = read(nil, nil, function(text) return completion.peripheral(text) end, "")

    print("Select the input gate:")
    config.input_gate = read(nil, nil, function(text) return completion.peripheral(text) end, "")

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

    local configfile = io.open("/.draconic_config.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end

local configfile = io.open("/.draconic_config.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

local function loadConfig()
    if fs.exists(".draconic_config.txt") then
        local file = io.open(".draconic_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open(".draconic_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

local input_valve = peripheral.wrap(config.input_gate)
local output_valve = peripheral.wrap(config.output_gate)

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

local chatQueue = {}

local function fullLog(text,level)
    if not fs.isDir("/draconic_logs") then
        fs.makeDir("/draconic_logs")
    end
    if not text then text = "" end
    if (level <= config.chatLoggingLevel or level == 4) then
        local logFileRead = io.open("/draconic_logs/"..logFileName,"r")
        local txt
        if logFileRead then
            txt = logFileRead:read("*a").."\n".."["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text
            logFileRead:close()
        else
            txt = "["..getDate("shortdate").."] "..loggingLevels_file[level].." "..text
        end

        local logFile = io.open("/draconic_logs/"..logFileName,"w")
        logFile:write(txt)
        logFile:close()
    end
    local chatBox = peripheral.find("chatBox")
    if (level <= config.chatLoggingLevel or level == 4) and chatBox then
        local new_id = math.random(1000000,9999999)
        if config.isGlobal then
            chatQueue[tostring(new_id)] = {
                text = "["..getDate("shorttime").."] "..loggingLevels[level].." "..text, 
                name = "Draconic | "..config.name,
                isglobal = true,
                target = ""
            }
        else
            chatQueue[tostring(new_id)] = {
                text = "["..getDate("shorttime").."] "..loggingLevels[level].." "..text, 
                name = "Draconic | "..config.name,
                isglobal = false,
                target = config.owner
            }
        end
    end
    if config.isDiscord and (level <= config.discordLevel or level == 4) and use_discord then
        discord_hook.send(loggingLevels_emojis[level].." **"..loggingLevels_file[level].."** - "..text, "Draconic | "..config.name)
    end
end

fullLog("Server is now online",4)
os.sleep(1.1)

local function prettyEnergy(energy)
    if energy > 1000000000000000 then
        return string.format("%.2f", energy/1000000000000000).." PFE"
    elseif energy > 1000000000000 then
        return string.format("%.2f", energy/1000000000000).." TFE"
    elseif energy > 1000000000 then
        return string.format("%.2f", energy/1000000000).." GFE"
    elseif energy > 1000000 then
        return string.format("%.2f", energy/1000000).." MFE"
    elseif energy > 1000 then
        return string.format("%.2f", energy/1000).." kFE"
    else
        return string.format("%.2f", energy).." FE"
    end
end

local function prettyETA(time)
    local seconds = time%60
    local minutes = math.floor(time/60)%60
    local hours = math.floor(time/3600)%24
    local days = math.floor(time/86400)%30
    local months = math.floor(time/2635200)%12
    local years = math.floor(time/31622400)

    local output = ""

    if years >= 1 then
        output = string.format("%dy %dM %dd %dh %dm %ds", years, months, days, hours, minutes, seconds)
    elseif months >= 1 then
        output = string.format("%dM %dd %dh %dm %ds", months, days, hours, minutes, seconds)
    elseif days >= 1 then
        output = string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)
    elseif hours >= 1 then
        output = string.format("%dh %dm %ds", hours, minutes, seconds)
    elseif minutes >=1 then
        output = string.format("%dm %ds", minutes, seconds)
    else
        output = string.format("%ds", seconds)
    end

    return output
end

local function fill(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            term.setCursorPos(x+i1-1,y+i2-1)
            term.write(char or " ")
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                term.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    term.write()
                else
                    term.write(char or " ")
                end
            end
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function write(x,y,text,bg,fg, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_posx,old_posy = term.getCursorPos()
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()

    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    term.setCursorPos(x,y)
    term.write(text)

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

config.saturation_target = config.saturation_target or 50
local width, height = term.getSize()

local function writeStatus(text, color)
    fill(1, height, width, height, colors.black, colors.white)
    write(1, height, text, colors.black, color or colors.red)
end

local min_injection = 3500000
local var_injection = config.last_injection or min_injection
local save_injection_timer = 50

local field_target = 50

local data = reactor.getReactorInfo()
local current_saturation
local current_field
local current_fuel
local flow_delta
local new_flow
local fuel_eta

local ignore_failsafe_timer = 10

local emergency_shutdown = false

local function reactorThread()
    while true do
        data = reactor.getReactorInfo()
        current_saturation = (data.energySaturation / data.maxEnergySaturation)*100
        current_field = (data.fieldStrength/data.maxFieldStrength)*100

        current_fuel = (data.fuelConversion/data.maxFuelConversion)*100
        local fuel_rate = (data.fuelConversionRate/1000000)*20
        local left_fuel = data.maxFuelConversion-data.fuelConversion

        fuel_eta = left_fuel/fuel_rate
        if fuel_rate <= 0.1 then
            fuel_eta = 0
        end

        flow_delta = clamp((current_saturation-config.saturation_target)*100000, -8000000, 8000000)
        new_flow = data.generationRate+flow_delta
        output_valve.setSignalLowFlow(new_flow)

        local field_delta = clamp((field_target-current_field)*200000, -10000000, 10000000)
        if data.status == "running" then
            var_injection = clamp(var_injection+field_delta, min_injection, 150000000)
        else
            var_injection = clamp(var_injection-8000000, min_injection, 150000000)
        end
        input_valve.setSignalLowFlow(var_injection)

        save_injection_timer = save_injection_timer-1

        if save_injection_timer <= 0 then
            save_injection_timer = 50
            config.last_injection = var_injection
            writeConfig()
        end

        if ignore_failsafe_timer == 0 and data.status == "running" then
            if current_fuel > 99 then
                reactor.stopReactor()
                writeStatus("Ran out of fuel!", colors.red)
                fullLog("Ran out of fuel, turning off..\n("..100-current_fuel.."%)", 2)
            end
            if current_saturation < 5 or current_saturation > 95 then
                reactor.stopReactor()
                writeStatus("Unsafe energy saturation!", colors.red)
                fullLog("Unsafe saturation levels, turning off..\n("..current_saturation.."%)", 1)
            end
            if current_field < 5 then
                reactor.stopReactor()
                writeStatus("Containment field too low!", colors.red)
                fullLog("Too low containment, turning off..\n("..current_field.."%)", 1)
            end
        elseif ignore_failsafe_timer > 0 then
            ignore_failsafe_timer = ignore_failsafe_timer-1
        end
        if data.status == "beyond_hope" then
            reactor.stopReactor()
            fullLog("!WARNING! Reactor in final cooldown, engaging cardboard box..", 1)
            emergency_shutdown = true
            error("FINAL HOPE")
        end
        os.queueEvent("drawUpdate")
        sleep(0.1)
    end
end

local function drawThread()
    while true do
        os.pullEvent("drawUpdate")

        fill(1,1, width,1, colors.lightGray, colors.black)
        fill(1,2, width,16, colors.black, colors.white)
        local top_text = "Draconic Reactor Monitor"

        write((width/2)-(#top_text/2)+1,1, top_text, colors.lightGray, colors.black)

        if ignore_failsafe_timer > 0 then
            write(1,1, tostring(ignore_failsafe_timer),colors.lightGray, colors.red)
        end

        write(3, 2, "\x1E", colors.black, colors.orange)
        write(5, 2, "\x10", colors.black, colors.green)
        write(7, 2, "\x04", colors.black, colors.red)

        write(2,3, "Status: "..data.status, colors.black, colors.lightGray)
        write(2,4, "Temperature: "..data.temperature.."C", colors.black, colors.red)
        write(2,5, "Generation: "..prettyEnergy(data.generationRate).."/t", colors.black, colors.lightBlue)

        write(2,6, "Containment Field: "..string.format("%.1f%%", current_field), colors.black, colors.yellow)
        write(2,7, "[", colors.black, colors.lightGray) write(width-1,7, "]", colors.black, colors.lightGray)
        fill(3,7, 3+(width-4)*(current_field/100),7, colors.black, colors.blue, "#")
        write(3,8, "Rate: "..data.fieldDrainRate, colors.black, colors.gray)

        local injection_text = "Injection: "..prettyEnergy(var_injection).."/t"
        write(width-#injection_text-1,8, injection_text, colors.black, colors.gray)
        
        local targ_saturation_text = string.format("Target: %.1f%%", config.saturation_target)

        write(2,9, "Energy Saturation: "..string.format("%.1f%%", current_saturation), colors.black, colors.lime)
        write(width-#targ_saturation_text, 9, targ_saturation_text, colors.black, colors.orange)
        write(2,11, "[", colors.black, colors.lightGray) write(width-1,11, "]", colors.black, colors.lightGray)
        fill(3,11, 3+(width-4)*(current_saturation/100),11, colors.black, colors.red, "#")
        write(2+((width-4)*(config.saturation_target/100)), 10, "-\x1F-", colors.black, colors.orange)

        write(3,12, "Flow Gate: "..prettyEnergy(new_flow).."/t", colors.black, colors.gray)
        write(3,13, "Flow Diff: "..prettyEnergy(flow_delta).."/t", colors.black, colors.gray)

        write(2,15, "Fuel: "..string.format("%.2f%%", (100-current_fuel)), colors.black, colors.yellow)
        if fuel_eta > 0 then
            local fuel_eta_text = "ETA: "..prettyETA(fuel_eta)
            write(width-#fuel_eta_text,15, fuel_eta_text, colors.black, colors.yellow)
        end
        write(2,16, "[", colors.black, colors.lightGray) write(width-1,16, "]", colors.black, colors.lightGray)
        fill(3,16, 3+(width-4)*((100-current_fuel)/100),16, colors.black, colors.orange, "#")
    end
end

local function inputThread()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        if y == 2 then
            if x == 3 then
                ignore_failsafe_timer = 10
                reactor.chargeReactor()
                writeStatus("Charging Reactor", colors.lightGray)
                fullLog("Charging Reactor", 3)
            elseif x == 5 then
                ignore_failsafe_timer = 10
                reactor.activateReactor()
                writeStatus("Activating Reactor", colors.lightGray)
                fullLog("Activating Reactor", 3)
            elseif x == 7 then
                reactor.stopReactor()
                writeStatus("Stopping Reactor", colors.lightGray)
                fullLog("Stopping Reactor", 3)
            end
        elseif y == 9 then
            fill(1,height-2, width, height-1, colors.black, colors.white)
            write(1, height-2, "Saturation Target: (Percentage)", colors.black, colors.lightGray)
            term.setCursorPos(1, height-1)
            term.write("> ")
            local new_target = tonumber(read())
            if new_target and new_target <= 99 and new_target >= 1 then
                fill(1,height-2, width, height-1, colors.black, colors.white)
                write(1, height-2, "Confirm "..new_target.."%? (y/n)", colors.black, colors.lightGray)
                term.setCursorPos(1, height-1)
                term.write("> ")
                local input = read():lower()
                if input == "y" or input == "yes" or input == "true" then
                    config.saturation_target = new_target
                    writeConfig()
                end
            end
        end
        fill(1,height-2, width, height-1, colors.black, colors.white)
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
        sleep(0.1)
    end
end

term.clear()
local error_count = 0

redstone.setOutput("bottom", false)

while true do
    local stat, err = pcall(function()
        parallel.waitForAny(reactorThread, drawThread, inputThread, chatManager)
    end)
    if not stat then
        chatQueue = {}
        if err == "Terminated" then
            term.clear()
            term.setCursorPos(1,1)
            print("Reactor program terminated")
            return
        end
        error_count = error_count+1
        writeStatus(err, colors.red)
        fullLog("("..error_count.."/6) REACTOR ERROR: \n"..err, 1)
        if error_count == 6 then
            fullLog("**Too many errors! Attempting shutdown..**", 1)
        end
        sleep(0.5)
        if error_count >= 6 or emergency_shutdown then
            term.clear()
            term.setCursorPos(1,1)
            print("Reactor program terminated from error count or emergency, attempting shutdown..")
            if not reactor.stopReactor() or emergency_shutdown then
                print("Couldn't shutdown reactor or emergency! Engaging cardboard box..")
                redstone.setOutput("bottom", true)
            end
            print("Successfully shutdown reactor")
            return
        end
    end
end
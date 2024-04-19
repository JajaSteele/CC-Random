local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local modems = {peripheral.find("modem")}
local modem
portNum = 1204
for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host("aspect_addressbook", tostring(os.getComputerID()))
    modem.open(portNum)
end

addresses = require("addresses")
addressToView = nil
page = 1
computers = {
    {inputName = "main", compId = 40},
    {inputName = "rf", compId = 106},
    {inputName = "destiny",compId = 129},
    {inputName = "test",compId = 61},
    {inputName = "factory",compId = 87},
    {inputName = "sgc",compId = 207},
    {inputName = "glacio",compId = 208}
}
local address_display_table = {} -- Creates a new table, the one you're gonna use to display stuff
for k,v in pairs(addresses.addressDatabase) do -- Loops through every entries in addressesDatabase
    address_display_table[#address_display_table+1] = {name=v.name, input_name=v.inputName, page = v.page} -- Adds the name of the address to address_display_table
end
table.sort(address_display_table, function(a,b) return (a.name < b.name) end) --Sorts the table by the name of each address, normally it should be alphabetically sorted

targetAddress = nil

local completion = require "cc.completion"

local autoComp = {"dial", "fastdial","target", "quickdial", "close", "view", "dhd", "cmds", "term", "reboot", "last", "lastfast"}

num = 2
listNum = 2
scroll = 0

local settings = {
    dialer = "dialer",
    database = "database",
    dhd = "dhd",
    list = "list"
}
dialType = 1
sendId = 40
local mode = settings.dialer
rednet.open("back")
target = nil

local w, h = term.getSize()
term.clear()
inputMenu = window.create(term.current(), 1, 18, w, h)
inputMenu.setVisible(true)
mainMenu = window.create(term.current(), 1, 1, w, 17)
mainMenu.setVisible(true)

local function getNearestGate()
    modem.transmit(portNum, portNum, {protocol="aspect_sg_ping", message="request_ping"})

    local temp_gates = {}

    local failed_attempts = 0
    while true do
        local timeout_timer = os.startTimer(0.075)
        local event = {os.pullEvent()}

        if event[1] == "modem_message" then
            if type(event[5]) == "table" and event[5].protocol == "aspect_sg_ping" and event[5].message == "response_ping" then
                failed_attempts = 0
                os.cancelTimer(timeout_timer)
                if event[6] and event[6] < 200 then  
                    temp_gates[#temp_gates+1] = {
                        id = event[5].id,
                        distance = event[6] or math.huge
                    }
                end
            end
        elseif event[1] == "timer" then
            if event[2] == timeout_timer then
                failed_attempts = failed_attempts+1
            else
                os.cancelTimer(timeout_timer)
            end
        end

        if failed_attempts > 4 then
            break
        end
    end

    table.sort(temp_gates, function(a,b) return (a.distance < b.distance) end)

    if temp_gates[1] then
        return temp_gates[1]
    else
        return nil
    end
end

local function centerPad(text, width)
    local text = tostring(text)
    local pad = (width - string.len(text)) / 2
    if pad <= 0 then
        return text
    end
    return string.rep(" ", math.floor(pad))
        .. text
        .. string.rep(' ', math.ceil(pad))
end

function fastDialHandler()
    while true do
        id, message = rednet.receive()
        if id == sendId then
            if message == "fastdialOnConfirm" then
                dialType = 2
                fastDialOn = true
                createTermDisplay()
            elseif message == "fastdialOffConfirm" then
                dialType = 1
                fastDialOn = false
                createTermDisplay()
            end
        end
    end
end

function updateHandler()
    while true do
        id, message = rednet.receive()
        if id == sendId then
            if message == "stopped" then
                target = nil
                createTermDisplay()
            end
        end
    end
end

function createInputDisplay()
    inputMenu.setCursorPos(1,1)
    inputMenu.setTextColor(colors.gray)
    inputMenu.write(string.rep("=", w))
    inputMenu.setCursorPos(1,3)
    inputMenu.setTextColor(colors.gray)
    inputMenu.write(string.rep("=", w))
end

function createMainMenu()
    local old_pos_x, old_pos_y = term.getCursorPos()
    if mode == settings.dialer then
        num = 2
        mainMenu.clear()
        mainMenu.setCursorPos(1,1)
        mainMenu.setTextColor(colors.blue)
        mainMenu.write(centerPad("--==[APEX-OS]==--",w))
        mainMenu.setCursorPos(1,2)
        mainMenu.setTextColor(colors.gray)
        mainMenu.write(string.rep("=", w))
        mainMenu.setCursorPos(1,3)
        --if mode == settings.dialer then
            for i1=1, #address_display_table do --Loops for a certain number of times, in this case it loops #(length of address_display_table) times
                local entry = address_display_table[i1+scroll] -- This sets an "entry" variable , which is gonna be the same as "v" in the old loop, except now "scroll" can offset it
                if entry then
                    mainMenu.setCursorPos(1, num+1)
                    if target == entry.input_name then --For the rest i just changed "v" to "entry" lol
                        mainMenu.setTextColor(colors.lime)
                    else
                        mainMenu.setTextColor(colors.lightBlue)
                    end
                    mainMenu.write("> "..entry.name)
                    num = num+1
                end
            end
        --end
    elseif mode == settings.dhd then
        mainMenu.clear()
        mainMenu.setCursorPos(1,1)
        mainMenu.setTextColor(colors.blue)
        mainMenu.write(centerPad("--==[APEX-OS]==--",w))
        mainMenu.setCursorPos(1,2)
        mainMenu.setTextColor(colors.gray)
        mainMenu.write(string.rep("=", w))
        mainMenu.redraw()
        mainMenu.setCursorPos(1,10)
        mainMenu.setTextColor(colors.lightBlue)
        mainMenu.write(centerPad("AWAITING INPUT",w))
    elseif mode == settings.database then
        mainMenu.clear()
        mainMenu.setCursorPos(1,1)
        mainMenu.setTextColor(colors.blue)
        mainMenu.write(centerPad("--==[APEX-OS]==--",w))
        mainMenu.setCursorPos(1,2)
        mainMenu.setTextColor(colors.gray)
        mainMenu.write(string.rep("=", w))
        mainMenu.redraw()
        mainMenu.setCursorPos(1,10)
        mainMenu.setTextColor(colors.lightBlue)
        if addressToView ~= nil then
            mainMenu.write(centerPad(addressToView,w))
        else
            mainMenu.write(centerPad("AWAITING INPUT",w))
        end
    elseif mode == settings.list then
        listNum = 2
        mainMenu.clear()
        mainMenu.setCursorPos(1,1)
        mainMenu.setTextColor(colors.blue)
        mainMenu.write(centerPad("--==[APEX-OS]==--",w))
        mainMenu.setCursorPos(1,2)
        mainMenu.setTextColor(colors.gray)
        mainMenu.write(string.rep("=", w))
        mainMenu.setCursorPos(1,3)
        for i1=1, #address_display_table do --Loops for a certain number of times, in this case it loops #(length of address_display_table) times
            local entry = address_display_table[i1+scroll] -- This sets an "entry" variable , which is gonna be the same as "v" in the old loop, except now "scroll" can offset it
            if entry then
                mainMenu.setCursorPos(1, listNum+1)
                mainMenu.setTextColor(colors.lightBlue)
                mainMenu.write("- ")
                mainMenu.write(entry.input_name)
                listNum = listNum+1
            end
        end
    end
    term.setCursorPos(old_pos_x, old_pos_y)
end

function awaitInput()
    while true do
        inputMenu.setCursorPos(1,2)
        inputMenu.setTextColor(colors.lightGray)
        local input = read(nil, nil, function(text) return completion.choice(text, autoComp) end, nil)
        for k,v in pairs(addresses.addressDatabase) do
            if input == "dial "..v.inputName then
                inputMenu.setCursorPos(1,2)
                inputMenu.clearLine()

                local gate_to_dial = getNearestGate()
                if gate_to_dial then
                    rednet.send(gate_to_dial.id, {type="dial", data=v})
                    target = v.inputName
                    inputMenu.setCursorPos(1,1)
                    createMainMenu()
                end
            elseif input == "fastdial "..v.inputName then
                inputMenu.setCursorPos(1,2)
                inputMenu.clearLine()

                local gate_to_dial = getNearestGate()
                if gate_to_dial then
                    rednet.send(gate_to_dial.id, {type="dialfast", data=v})
                    target = v.inputName
                    createMainMenu()
                end
            elseif input == "quickdial "..v.inputName then
                inputMenu.setCursorPos(1,2)
                inputMenu.clearLine()
                rednet.send(sendId,{type="quickdial", data=v})
                target = v.inputName
                createMainMenu()
            elseif input == "view "..v.inputName then
                target = v.inputName.."View"
                mode = settings.database
                addressToView = v.displayCode
                createMainMenu()
                inputMenu.setCursorPos(1,2)
                inputMenu.clearLine()
            end
        end
        for k,v in pairs(computers)do
            if input == "target "..v.inputName then
                sendId = v.compId
                inputMenu.setCursorPos(1,2)
                inputMenu.clearLine()
                createMainMenu()
            end
        end
        if input == "dial" then
            mode = settings.dialer
            inputMenu.setCursorPos(1,2)
            inputMenu.clearLine()
            createMainMenu()
        elseif input == "list" then
            mode = settings.list
            inputMenu.setCursorPos(1,2)
            inputMenu.clearLine()
            createMainMenu()
        elseif input == "view" then
            mode = settings.database
            createMainMenu()
            mainMenu.setCursorPos(1,10)
            mainMenu.setTextColor(colors.lightBlue)
            mainMenu.write(centerPad("AWAITING SELECTION",w))
            inputMenu.setCursorPos(1,2)
            inputMenu.clearLine()
        elseif input == "dhd" then
            mode = settings.dhd
            inputMenu.setCursorPos(1,2)
            inputMenu.clearLine()
            createMainMenu()
        elseif input == "last" then
            rednet.send(sendId,"lastAddress")
            inputMenu.setCursorPos(1,2)
            inputMenu.clearLine()
        elseif input == "lastfast" then
            rednet.send(sendId,"lastAddressFast")
            inputMenu.setCursorPos(1,2)
            inputMenu.clearLine()
        elseif input == "term" then
            os.shutdown()
        elseif input == "reboot" then
            os.reboot()
        elseif input == "close" then
            inputMenu.setCursorPos(1,2)
            inputMenu.clearLine()
            target = nil
            local gate_to_close = getNearestGate()
            if gate_to_close then
                rednet.send(gate_to_close.id,"close")
            end
            createMainMenu()
        elseif input ~= "" and mode == settings.dhd then
            local temp_address = split(input, ",")
            local newaddress= {}
            for k,v in ipairs(temp_address) do
                if tonumber(v) then
                    newaddress[#newaddress+1] = tonumber(v)
                end
            end
            if newaddress[#newaddress] ~= 0 then
                newaddress[#newaddress+1] = 0
            end
            if newaddress then
                rednet.send(sendId,{type="dial", data={code=newaddress}})
                inputMenu.setCursorPos(1,2)
                inputMenu.clearLine()
                createMainMenu()
            end
        else
            inputMenu.setCursorPos(1,2)
            inputMenu.clearLine()
            createMainMenu()
        end
    end
end




createMainMenu()
createInputDisplay()

local function scrollThread()
    while true do
        if (mode == settings.dialer or mode == settings.list) then
            local old_x, old_y = term.getCursorPos()
            local event, direction = os.pullEvent("mouse_scroll") --This waits for a mouse scroll event
            scroll = math.min(math.max(scroll+direction, 0), #address_display_table) -- THis makes sure scroll can't go below 0 , or can't go above the number of entries
            createMainMenu()
            term.setCursorPos(old_x, old_y)
        end
        sleep(0.05)
    end
end

parallel.waitForAll(awaitInput,scrollThread)

local script_version = "1.25"

local sg = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local env_detector = peripheral.find("environmentDetector")
local uni_scanner = peripheral.find("universal_scanner")

local sgmsg = {}
sgmsg.send = function(protocol, message)
    sg.sendStargateMessage(textutils.serialize({protocol=protocol, message=message}))
end

local function log_to_file(txt)
    local data = ""
    local old_io = io.open(".debug.log", "r")
    if old_io then
        data = old_io:read("*a")
        old_io:close()
    end
    data = data .. os.date("\n[%H.%M.%S] > ") .. txt
    local new_io = io.open(".debug.log", "w")
    new_io:write(data)
    new_io:close()
end

local function checkWarns()
    if env_detector then
        local rads = env_detector.getRadiationRaw()
        if rads*100000 > 1 then
            sgmsg.send("jjs_sg_warn", "radiation")
        end
    end
    if uni_scanner then
        local entity_scan = uni_scanner.scan("entity")
        local monster_count = 0
        for k,v in pairs(entity_scan) do
            if v.category == "MONSTER" then
                monster_count = monster_count+1
            end
        end
        if monster_count > 4 then
            sgmsg.send("jjs_sg_warn", "monster")
        end
    end
end

local config = {}
local function loadConfig()
    if fs.exists("saved_config_easydial.txt") then
        local file = io.open("saved_config_easydial.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open("saved_config_easydial.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()

if config.label == nil then config.label = "Dialer "..os.getComputerID() end
if config.monitor == nil then config.monitor = true end
if config.address_book_id == nil then config.address_book_id = nil end
if config.iris_control == nil then config.iris_control = false end
if config.iris_anti_kawoosh == nil then config.iris_anti_kawoosh = false end

print("Checking for iris..")
if sg.isStargateConnected() and sg.getChevronsEngaged() < 3 and sg.closeIris then
    checkWarns()
    if (config.iris_control and not sg.isStargateDialingOut()) or config.iris_anti_kawoosh then
        print("Closing iris")
        sg.closeIris()
    end
end
local anti_kawoosh_check = false
if sg.isStargateConnected() and config.iris_anti_kawoosh then
    anti_kawoosh_check = true
    os.queueEvent("anti_kawoosh_await")
end

-- AUTO UPDATE STUFF
local curr_script = shell.getRunningProgram()
local script_io = io.open(curr_script, "r")
local local_version_line = script_io:read()
script_io:close()

local function getVersionNumbers(first_line)
    local major, minor, patch = first_line:match("local script_version = \"(%d+)%.(%d+)\"")
    return {tonumber(major) or 0, tonumber(minor) or 0}
end

local local_version = getVersionNumbers(local_version_line)

print("Local Version: "..string.format("%d.%d", table.unpack(local_version)))

local update_source = "https://raw.githubusercontent.com/JajaSteele/CC-Random/main/SGJourney/easydial.lua"
local update_request = http.get(update_source)
if update_request then
    local script_version_line = update_request.readLine()
    update_request:close()
    local script_version = getVersionNumbers(script_version_line)
    print("Remote Version: "..string.format("%d.%d", table.unpack(script_version)))

    if script_version[1] > local_version[1] or (script_version[1] == local_version[1] and script_version[2] > local_version[2]) then
        print("Remote version is newer, updating local")
        sleep(0.5)
        local full_update_request = http.get(update_source)
        if full_update_request then
            local full_script = full_update_request.readAll()
            full_update_request:close()
            local local_io = io.open(curr_script, "w")
            local_io:write(full_script)
            local_io:close()
            print("Updated local script!")
            sleep(0.5)
            print("REBOOTING")
            sleep(0.5)
            os.reboot()
        else
            print("Full update request failed")
        end
    end
else
    print("Update request failed")
end
-- END OF AUTO UPDATE

local completion = require("cc.completion")
local is_dialing = false

settings.load()

settings.define("sg.slowdial", {
    description = "Forces the gate to use slow dial (for MW only)",
    default = false,
    type = "boolean"
})
settings.save()

local function debugLog(str)
    local debug_data = ""
    if fs.exists("debug.txt") then
        local debug_file = io.open("debug.txt", "r")
        debug_data = debug_file:read("*a")
        debug_file:close()
    end

    debug_data = debug_data.."\n"..str
    local debug_file2 = io.open("debug.txt", "w")
    debug_file2:write(debug_data)
    debug_file2:close()
end

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
    rednet.host("jjs_sg_remotedial", "jjs_sg_remotedial_home_"..os.getComputerID())
    
    modem.open(2707)
end

local dl = peripheral.find("Create_DisplayLink")

local dp_line1 = {txt="", center=false}
local dp_line2 = {txt="", center=false}

local function writeToDisplayLink(line1, line2, center1, center2, instant_update)
    local stat, err = pcall(function()
        dp_line1 = {
            txt = line1 or "",
            center = center1 or false
        }
        dp_line2 = {
            txt = line2 or "",
            center = center2 or false
        }
        if dl then
            local dl_height, dl_width = dl.getSize()
            dl.clear()
            if center1 then
                dl.setCursorPos(math.ceil(dl_width/2)-math.floor(#(line1 or "")/2), 1)
            else
                dl.setCursorPos(1,1)
            end
            dl.write(line1 or "")
            if center2 then
                dl.setCursorPos(math.ceil(dl_width/2)-math.floor(#(line2 or "")/2), 2)
            else
                dl.setCursorPos(1,2)
            end
            dl.write(line2 or "")
            if instant_update then
                dl.update()
            end
        end
    end)
end

local function write(x,y,text,bg,fg)
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
end

local last_address = {}

local function loadSave()
    if fs.exists("last_address.txt") then
        local file = io.open("last_address.txt", "r")
        last_address = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open("last_address.txt", "w")
    file:write(textutils.serialise(last_address))
    file:close()
end

loadSave()

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local address = {}
local display_address = {}

local input_text = ""

local auto_address_call = {}

local monitor = peripheral.find("monitor")
if monitor and config.monitor then
    local mw, mh = monitor.getSize()
    monitor.setTextScale(1)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setPaletteColor(colors.white, 0xFFFFFF)
    monitor.setPaletteColor(colors.black, 0x000000)
end
writeToDisplayLink("Starting up!", "Starting up!", true, true)

local address_cache = {}
local function addressLookupCached(lookup_value)
    if not lookup_value then
        return {name="Unknown Address"}
    end

    local id_to_send = config.address_book_id or 0
    if type(lookup_value) == "string" then
        if address_cache[lookup_value] then
            return address_cache[lookup_value]
        end
        rednet.send(id_to_send, lookup_value, "jjs_sg_lookup_name")
    elseif type(lookup_value) == "table" then
        if address_cache[(table.concat(lookup_value, "-"))] then
            return address_cache[(table.concat(lookup_value, "-"))]
        end
        rednet.send(id_to_send, lookup_value, "jjs_sg_lookup_address")
    end

    for i1=1, 5 do
        local id, msg, protocol = rednet.receive(nil, 0.075)
        if id == id_to_send then
            if protocol == "jjs_sg_lookup_return" then
                if type(lookup_value) == "string" then
                    address_cache[lookup_value] = msg
                elseif type(lookup_value) == "table" then
                    address_cache[(table.concat(lookup_value, "-"))] = msg
                end
                return msg
            else
                return {name="Unknown Address"}
            end
        end
    end
    return {name="Unknown Address"}
end

local function fancyReboot()
    if monitor and config.monitor then
        monitor.setPaletteColor(colors.black, 0x110000)
        local width, height = monitor.getSize()
        width = width or 1
        height = height or 1
        local monitor_text = "Rebooting.."
        writeToDisplayLink("Rebooting..", "-=-=-=-=-=-", true, true, true)
        monitor.clear()
        monitor.setCursorPos(math.ceil(width/2)-math.floor(#monitor_text/2), 3)
        monitor.clearLine()
        monitor.setTextColor(colors.red)
        monitor.write(monitor_text)
    end
    os.reboot()
end

local function wait_for_key(pattern, key, mode)
    while true do
        local event = {os.pullEvent()}
        if event[1] == "char" and mode ~= "key" then
            if event[2]:match(pattern) then
                return event[2]
            end
        elseif event[1] == "key" and mode ~= "char" then
            if event[2] == key then
                return event[2]
            end
        end
    end
end

local function addressLookup(lookup_value)
    if not lookup_value then
        return {name="Unknown Address"}
    end

    local id_to_send = config.address_book_id or 0
    if type(lookup_value) == "string" then
        rednet.send(id_to_send, lookup_value, "jjs_sg_lookup_name")
    elseif type(lookup_value) == "table" then
        rednet.send(id_to_send, lookup_value, "jjs_sg_lookup_address")
    end

    for i1=1, 5 do
        local id, msg, protocol = rednet.receive(nil, 0.075)
        if id == id_to_send then
            if protocol == "jjs_sg_lookup_return" then
                return msg
            else
                return {name="Unknown Address"}
            end
        end
    end
end

local function clearGate()
    if sg.isStargateConnected() or sg.getChevronsEngaged() > 0 or (sg.isChevronOpen and sg.isChevronOpen()) then
        sg.disconnectStargate()
        if not sg.engageSymbol and sg.rotateClockwise then
            if sg.isChevronOpen and sg.isChevronOpen() then
                sg.closeChevron()
            end
    
            if (0-sg.getCurrentSymbol()) % 39 < 19 then
                sg.rotateAntiClockwise(0)
            else
                sg.rotateClockwise(0)
            end
    
            repeat
                sleep()
            until sg.getCurrentSymbol() == 0
            sleep(0.25)
        end
    end
end

local function displayLinkUpdater()
    while true do
        if dl then
            local stat, err = pcall(function()
                local dl_height, dl_width = dl.getSize()
                dl.clear()
                if dp_line1.center then
                    dl.setCursorPos(math.ceil(dl_width/2)-math.floor(#(dp_line1.txt or "")/2), 1)
                else
                    dl.setCursorPos(1,1)
                end
                dl.write(dp_line1.txt)

                if dp_line2.center then
                    dl.setCursorPos(math.ceil(dl_width/2)-math.floor(#(dp_line2.txt or "")/2), 2)
                else
                    dl.setCursorPos(1,2)
                end
                dl.write(dp_line2.txt)
                dl.update()
            end)
        else
            dl = peripheral.find("Create_DisplayLink")
            sleep(4)
        end
        sleep(1)
    end
end

local address_txt = ""
local function inputThread()
    while true do
        term.clear()
        term.setCursorPos(1,1)
        term.setTextColor(colors.white)
        print("Address:")
        for k,v in ipairs(address) do
            term.setTextColor(colors.white)
            term.write("-")
            if v.dialed then
                term.setTextColor(colors.orange)
            elseif v.dialing then
                term.setTextColor(colors.lightGray)
            else
                term.setTextColor(colors.gray)
            end
            term.write(v.num)
            address_txt = address_txt..tostring(v.num)
        end
        term.setTextColor(colors.white)
        term.write("-")
        term.setTextColor(colors.lightGray)
        term.write(input_text)
        if monitor and config.monitor then
            monitor.setPaletteColor(colors.white, 0xFFDEAA)
            monitor.setPaletteColor(colors.black, 0x100500)
            monitor.setBackgroundColor(colors.black)
            local mw, mh = monitor.getSize()
            monitor.clear()
            monitor.setCursorPos(1,1)
            monitor.setTextColor(colors.white)
            monitor.write("Address:")
            monitor.setCursorPos(1,2)
            for k,v in ipairs(address) do
                monitor.setTextColor(colors.white)
                monitor.write("-")
                if v.dialed then
                    monitor.setTextColor(colors.orange)
                elseif v.dialing then
                    monitor.setTextColor(colors.lightGray)
                else
                    monitor.setTextColor(colors.gray)
                end
                monitor.write(v.num)
            end
            monitor.setTextColor(colors.white)
            monitor.write("-")
            monitor.setTextColor(colors.lightGray)
            monitor.write(input_text)
        end

        local event = {os.pullEvent()}

        if event[1] == "char" then
            if event[2]:match("%d") then
                input_text = input_text..event[2]
            end
        end
        if event[1] == "key" then
            if event[2] == keys.backspace then
                input_text = input_text:sub(1, #input_text-1)
                if #input_text == 0 then
                    input_text = tostring(address[#address].num)

                    table.remove(address, #address)
                    table.remove(display_address, #display_address)
                end
            elseif event[2] == keys.enter or event[2] == keys.numPadEnter then
                if #input_text > 0 then
                    address[#address+1] = {
                        num=tonumber(input_text),
                        dialed=false
                    }
                    display_address[#display_address+1] = tonumber(input_text)
                    input_text = ""
                end
                address[#address+1] = {
                    num=0,
                    dialed=false,
                    dialing=false
                }
                display_address[#display_address+1] = 0
                while true do
                    term.clear()
                    term.setCursorPos(1,1)
                    term.setTextColor(colors.white)
                    print("Address:")
                    local display_text = ""
                    for k,v in ipairs(address) do
                        if v.num ~= 0 then
                            term.setTextColor(colors.white)
                            term.write("-")
                            display_text = display_text.."-"
                            if v.dialed then
                                term.setTextColor(colors.orange)
                            elseif v.dialing then
                                term.setTextColor(colors.lightGray)
                            else
                                term.setTextColor(colors.gray)
                            end
                            term.write(v.num)
                            display_text = display_text..v.num
                        elseif v.num == 0 and (v.dialing or v.dialed) then
                            term.setTextColor(colors.white)
                            term.write("-")
                            display_text = display_text.."-"
                            if v.dialed then
                                term.setTextColor(colors.yellow)
                            else
                                term.setTextColor(colors.red)
                            end
                            term.write(v.num)
                            display_text = display_text..v.num
                        end
                    end
                    term.setTextColor(colors.white)
                    term.write("-")
                    
                    if monitor and config.monitor then
                        local mw, mh = monitor.getSize()

                        monitor.setCursorPos(1,1)
                        monitor.clearLine()
                        monitor.setTextColor(colors.white)
                        monitor.write("Address:")
                        monitor.setCursorPos(1,2)
                        monitor.clearLine()

                        local display_text = ""
                        for k,v in ipairs(address) do
                            if v.num ~= 0 then
                                monitor.setTextColor(colors.white)
                                monitor.write("-")
                                display_text = display_text.."-"
                                if v.dialed then
                                    monitor.setTextColor(colors.orange)
                                elseif v.dialing then
                                    monitor.setTextColor(colors.lightGray)
                                else
                                    monitor.setTextColor(colors.gray)
                                end
                                monitor.write(v.num)
                                display_text = display_text..v.num
                                if config.address_book_id and k == #address then
                                    local address_to_lookup = {}
                                    for k, v in ipairs(address) do
                                        if v.num ~= 0 then
                                            address_to_lookup[k] = v.num
                                        end
                                    end
                                    local address_name = addressLookupCached(address_to_lookup)

                                    if address_name then
                                        local old_pos_x, old_pos_y = monitor.getCursorPos()
                                        monitor.setCursorPos(math.ceil(mw/2)-math.floor(#(address_name.name)/2), mh)
                                        monitor.setTextColor(colors.orange)
                                        monitor.clearLine()
                                        monitor.write(address_name.name)
                                        monitor.setCursorPos(old_pos_x, old_pos_y)
                                    end
                                end
                            elseif v.num == 0 and (v.dialing or v.dialed) then
                                monitor.setTextColor(colors.white)
                                monitor.write("-")

                                monitor.setTextColor(colors.orange)
                                monitor.setCursorPos(1,3)
                                monitor.clearLine()
                                monitor.write("[["..string.rep(" ", mw-4).."]]")
                                local text = "!STAND BACK!"
                                monitor.setCursorPos(math.ceil(mw/2)-math.floor(#text/2), 3)
                                monitor.setTextColor(colors.red)
                                monitor.clearLine()
                                monitor.write(text)

                                if config.address_book_id then
                                    local address_to_lookup = {}
                                    for k, v in ipairs(address) do
                                        if v.num ~= 0 then
                                            address_to_lookup[k] = v.num
                                        end
                                    end
                                    local address_name = addressLookupCached(address_to_lookup) or {name="Unknown Address"}

                                    local old_pos_x, old_pos_y = monitor.getCursorPos()
                                    monitor.setCursorPos(math.ceil(mw/2)-math.floor(#(address_name.name)/2), mh)
                                    monitor.setTextColor(colors.yellow)
                                    monitor.clearLine()
                                    monitor.write(address_name.name)
                                    monitor.setCursorPos(old_pos_x, old_pos_y)
                                end
                            end
                        end
                        if not (address[#address].dialing or address[#address].dialed) then
                            monitor.setTextColor(colors.white)
                            monitor.write("-")    
                        end
                    end
                    if config.address_book_id and dl then
                        local address_to_lookup = {}
                        for k, v in ipairs(address) do
                            if v.num ~= 0 then
                                address_to_lookup[k] = v.num
                            end
                        end
                        local address_name = addressLookupCached(address_to_lookup)

                        writeToDisplayLink(table.concat(display_address, "-"), address_name.name, true, true, false)
                    else
                        writeToDisplayLink(table.concat(display_address, "-"), "Unknown Address", true, true, false)
                    end

                    local attempts = 0
                    repeat
                        sleep(0.1)
                        attempts = attempts+1
                    until sg.getChevronsEngaged() > 0 or attempts >= 20

                    if (address[#address].dialed and sg.isStargateConnected() and sg.isWormholeOpen()) or sg.getChevronsEngaged() == 0 then
                        if monitor and config.monitor then
                            local mw, mh = monitor.getSize()
                            monitor.setTextColor(colors.green)
                            monitor.setCursorPos(1,3)
                            monitor.write("[["..string.rep(" ", mw-4).."]]")
                            local text = "!READY!"
                            monitor.setCursorPos(math.ceil(mw/2)-math.floor(#text/2), 3)
                            monitor.setTextColor(colors.lime)
                            monitor.write(text)
                        end

                        term.setTextColor(colors.orange)
                        term.setCursorPos(1,4)
                        term.write("Dialing Successful!")
                        term.setCursorPos(1,8)

                        repeat
                            local event = os.pullEvent()
                        until event == "stargate_disconnected" or event == "stargate_reset" or sg.getChevronsEngaged() == 0

                        if monitor and config.monitor then
                            monitor.clear()
                        end

                        fancyReboot()
                        return
                    end
                    
                    sleep(0)
                end
            elseif event[2] == keys.space then
                address[#address+1] = {
                    num=tonumber(input_text),
                    dialed=false
                }
                display_address[#display_address+1] = tonumber(input_text)
                input_text = ""
            end
        end
    end
end

local function dialThread()
    while true do
        for k,v in ipairs(address) do
            if not v.dialed then
                address[k].dialing = true
                if sg.engageSymbol and not (sg.rotateClockwise and settings.get("sg.slowdial")) then
                    sg.engageSymbol(v.num)
                else
                    if (v.num-sg.getCurrentSymbol()) % 39 < 19 then
                        sg.rotateAntiClockwise(v.num)
                    else
                        sg.rotateClockwise(v.num)
                    end
                    
                    repeat
                        sleep()
                    until sg.getCurrentSymbol() == v.num
                    sleep(0.25)
                    if sg.openChevron then
                        sg.openChevron()
                        sleep(0.1)
                        sg.encodeChevron()
                        sleep(0.1)
                        sg.closeChevron()
                    else
                        sg.encodeChevron()
                    end
                end
                address[k].dialing = false
                address[k].dialed = true
            end
            sleep(0)
        end
        sleep()
    end
end

local function autoInputThread()
    sleep(1)
    for k,v in ipairs(auto_address_call) do
        local symbol_string = tostring(v)
        for i1=1, #symbol_string do
            os.queueEvent("char", tostring(symbol_string:sub(i1,i1)))
            os.sleep()
        end
        os.sleep()
        os.queueEvent("key", keys.space, false)
    end
    os.queueEvent("key", keys.enter, false)
    
    repeat 
        sleep(0.25)
    until sg.isStargateConnected() or sg.getChevronsEngaged() == 0
end

local function autoDialbackThread()
    sleep(1)
    for k,v in ipairs(last_address) do
        local symbol_string = tostring(v)
        for i1=1, #symbol_string do
            os.queueEvent("char", tostring(symbol_string:sub(i1,i1)))
            os.sleep()
        end
        os.sleep()
        os.queueEvent("key", keys.space, false)
    end
    os.queueEvent("key", keys.enter, false)
    
    repeat 
        sleep(0.25)
    until sg.isStargateConnected() or sg.getChevronsEngaged() == 0
end

local dial_book = {
    {name="Earth", address={31,21,11,1,16,14,18,12}},
    {name="Nether", address={27,23,4,34,12,28}},
    {name="The End", address={13,24,2,19,3,30}},
    {name="Abydos", address={26,6,14,31,11,29}},
    {name="Chulak", address={8,1,22,14,36,19}},
    {name="Black Hole", address={18,7,3,36,25,15}},
    {name="Lantea", address={29,5,17,34,6,12}},
}


local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function lastAddressSaverThread()
    if sg.getConnectedAddress and sg.isStargateConnected() then
        if #sg.getConnectedAddress() < 6 then
            repeat
                sleep(0.5)
            until sg.getOpenTime() > 6 or not sg.isStargateConnected()
        end
        last_address = sg.getConnectedAddress()
        writeSave()
    end
    while true do
        local event = {os.pullEvent()}
        if (event[1] == "stargate_incoming_wormhole" and (event[3] and event[3] ~= {})) or (event[1] == "stargate_outgoing_wormhole") then
            local old_last_address = table.concat(last_address, " ")
            last_address = event[3]
            if event[1] == "stargate_incoming_wormhole" then
                repeat
                    sleep(0.5)
                until sg.getOpenTime() > 6 or not sg.isStargateConnected()
                if sg.getConnectedAddress then
                    last_address = sg.getConnectedAddress()
                end
            end
            if sg.isStargateConnected() and sg.getChevronsEngaged() >= 6 and last_address and #last_address >= 6 then
                writeSave()
            else
                local old_address = split(old_last_address, " ")
                last_address = {}
                for k,v in ipairs(old_address) do
                    if tonumber(v) then
                        last_address[#last_address+1] = tonumber(v)
                    end
                end
            end
        end
    end
end

local function disconnectListener()
    local id, msg, protocol = rednet.receive("jjs_sg_rawcommand")
    rednet.send(id, "", "jjs_sg_rawcommand_confirm")
    if msg == "gate_disconnect" then
        clearGate()
        fancyReboot()
    end
end

local function mainThread()
    while true do
        local w, h = term.getSize()

        term.clear()
        term.setCursorPos(1,1)
        print("Select Mode:")
        print("1. Manual Dial")
        print("2. Dial Book")
        print("3. Clipboard")
        print("4. Set Label")
        print("5. Set Energy Target")
        print("6. Toggle Monitor ("..tostring(config.monitor)..")")
        print("7. Set Addressbook ID ("..tostring(config.address_book_id)..")")
        print("8. Dial-Back")
        print("9. Toggle Iris")
        print("10. Toggle Iris Control ("..tostring(config.iris_control)..")")
        print("11. Kawoosh-Protection Iris ("..tostring(config.iris_anti_kawoosh)..")")
        print("12. Reset Stargate")

        write(3, h, "Label: "..config.label, colors.black, colors.yellow)

        term.setCursorPos(14,1)
        local mode = tonumber(read())

        if is_dialing then
            return
        end

        if mode == 1 then
            clearGate()
            parallel.waitForAny(inputThread, dialThread, lastAddressSaverThread)
            is_dialing = true
        elseif mode == 2 then
            term.clear()
            term.setCursorPos(1,1)
            print("Select Destination:")
            for k,v in ipairs(dial_book) do
                print(k..". "..v.name)
            end
            
            term.setCursorPos(1,h)
            local selected = tonumber(wait_for_key("%d"))

            if dial_book[selected] then
                is_dialing = true
                auto_address_call = dial_book[selected].address
                clearGate()
                parallel.waitForAll(inputThread, dialThread, autoInputThread, lastAddressSaverThread)
            end
        elseif mode == 3 then
            term.clear()
            term.setCursorPos(1,1)
            print("Waiting for Clipboard (Press CTRL+V)")
            local name, clipboard = os.pullEvent("paste")

            local temp_address = split(clipboard, "-")
            auto_address_call = {}

            for k,v in ipairs(temp_address) do
                if tonumber(v) then
                    auto_address_call[#auto_address_call+1] = tonumber(v)
                    print(tonumber(v))
                end
            end
            
            is_dialing = true
            clearGate()
            parallel.waitForAll(inputThread, dialThread, autoInputThread, lastAddressSaverThread)
        elseif mode == 4 then
            term.clear()
            term.setCursorPos(1,1)
            print("New Label:")
            local new_label = read(nil, nil, nil, config.label)
            config.label = new_label
            writeConfig()
            fancyReboot()
            return
        elseif mode == 5 then
            term.clear()
            term.setCursorPos(1,1)
            print("New Energy Target:")
            local new_target = tonumber(read(nil, nil, nil, tostring(sg.getEnergyTarget())))
            sg.setEnergyTarget(new_target or sg.getEnergyTarget())
        elseif mode == 6 then
            term.clear()
            term.setCursorPos(1,1)
            config.monitor = (not config.monitor)
            print("Set to: "..tostring(config.monitor))
            sleep(1)
            writeConfig()
            fancyReboot()
            return
        elseif mode == 7 then
            term.clear()
            term.setCursorPos(1,1)
            local list_of_books = {rednet.lookup("jjs_sg_addressbook")}
            
            for k,v in pairs(list_of_books) do
                list_of_books[k] = tostring(v)
            end
            print("Address Book ID:")
            local new_address_book = read(nil, nil, function(text) return completion.choice(text, list_of_books) end, tostring(config.address_book_id))
            if tonumber(new_address_book) then
                config.address_book_id = tonumber(new_address_book)
                writeConfig()
            end
        elseif mode == 8 then
            if sg.isStargateConnected() or sg.getChevronsEngaged() > 0 then
                sg.disconnectStargate()
            end
            is_dialing = true
            parallel.waitForAll(inputThread, dialThread, autoDialbackThread, disconnectListener, lastAddressSaverThread)
        elseif mode == 9 then
            if sg.getIrisProgressPercentage() > 50 then
                sg.openIris()
            else
                sg.closeIris()
            end
        elseif mode == 10 then
            term.clear()
            term.setCursorPos(1,1)
            config.iris_control = (not config.iris_control)
            print("Set to: "..tostring(config.iris_control))
            sleep(1)
            writeConfig()
        elseif mode == 11 then
            term.clear()
            term.setCursorPos(1,1)
            config.iris_anti_kawoosh = (not config.iris_anti_kawoosh)
            print("Set to: "..tostring(config.iris_anti_kawoosh))
            sleep(1)
            writeConfig()
        elseif mode == 12 then
            if sg.rotateClockwise then
                sg.endRotation()
            end
            clearGate()
        end
    end
end

local function mainRemote()
    while true do
        local id, msg, protocol = rednet.receive()

        if is_dialing then
            return
        end

        if protocol == "jjs_sg_startdial" then
            local temp_address = split(msg, "-")
            auto_address_call = {}

            for k,v in ipairs(temp_address) do
                if tonumber(v) then
                    auto_address_call[#auto_address_call+1] = tonumber(v)
                    print(tonumber(v))
                end
            end
            
            clearGate()
            is_dialing = true
            parallel.waitForAll(inputThread, dialThread, autoInputThread, lastAddressSaverThread)
        elseif protocol == "jjs_sg_getlabel" then
            rednet.send(id, config.label, "jjs_sg_sendlabel")
        end
    end
end


local function mainRemoteCommands()
    while true do
        local id, msg, protocol = rednet.receive()
        if protocol == "jjs_sg_disconnect" then
            clearGate()
            fancyReboot()
        elseif protocol == "jjs_sg_getlabel" then
            rednet.send(id, config.label, "jjs_sg_sendlabel")
        end
    end
end

local function mainRemoteDistance()
    while true do
        local event, side, channel, reply_channel, message, distance = os.pullEvent("modem_message")
        if type(message) == "table" then
            if message.protocol == "jjs_sg_dialer_ping" and message.message == "request_ping" then
                modem.transmit(reply_channel, 2707, {protocol="jjs_sg_dialer_ping", message="response_ping", id=os.getComputerID(), label=config.label})
            end
        end
    end
end
local function mainFailsafe()
    while true do
        local event, int, code, msg = os.pullEvent("stargate_reset")
        if event == "stargate_reset" and code < 0 and msg ~= "interrupted_by_incoming_connection" then
            fancyReboot()
            return
        end
    end
end

local screensaver_text = "  Stargate Idle  "
local screensaver_color = colors.gray

local status_color = colors.lightGray
local status_text = ""

local function screenSaverMonitor()
    writeToDisplayLink("Stargate Idle", config.label, true, true, false)
    if config.monitor then
        local width, height
        local scroll
        if not monitor then
            repeat
                sleep(0.5)
            until peripheral.find("monitor")
        end
        if monitor then
            width, height = monitor.getSize()
            width = width or 1
            height = height or 1
            scroll = 0
            monitor.setPaletteColor(colors.gray, 0x222222)
            if not sg.isStargateConnected() then
                status_text = config.label or "No Label"

                monitor.setCursorPos(math.ceil(width/2)-math.floor(#status_text/2), 3)
                monitor.clearLine()
                status_color = colors.lightGray
                monitor.setTextColor(status_color)
                monitor.write(status_text)
            end
        end
        while true do
            if is_dialing then
                break
            end
            pcall(function()
                if monitor then
                    local old_x, old_y = monitor.getCursorPos()
                    width, height = monitor.getSize()
                    
                    monitor.setCursorPos(1-(#screensaver_text) + scroll, 2)
                    monitor.clearLine()
                    monitor.setTextColor(screensaver_color)
                    monitor.write(string.rep(screensaver_text.."-", math.ceil(width/#screensaver_text)+2))

                    monitor.setCursorPos(1-(#screensaver_text) - scroll, 4)
                    monitor.clearLine()
                    monitor.setTextColor(screensaver_color)
                    monitor.write(string.rep(screensaver_text.."-", math.ceil(width/#screensaver_text)+2))

                    monitor.setCursorPos(old_x, old_y)
                    scroll = scroll+1
                    if scroll > #screensaver_text then
                        scroll = 0
                    end
                end
            end)
            sleep(0.5)
        end
        monitor.setPaletteColor(colors.gray, term.nativePaletteColor(colors.gray))
    end
end

local function monitorConnectThread()
    while true do
        local event, side = os.pullEvent("peripheral")
        if peripheral.getType(side) == "monitor" then
            monitor = peripheral.wrap(side)
            if monitor then
                monitor.setTextScale(1)
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                monitor.setPaletteColor(colors.white, 0xFFFFFF)
                monitor.setPaletteColor(colors.black, 0x000000)
                local width, height = monitor.getSize()
                monitor.setCursorPos(math.ceil(width/2)-math.floor(#status_text/2), 3)
                monitor.clearLine()
                monitor.setTextColor(status_color)
                monitor.write(status_text)
            end
        end
    end
end

local function gateMonitor()
    while true do
        local width, height
        local old_x, old_y
        if monitor and config.monitor then
            width, height = monitor.getSize()
            width = width or 1
            height = height or 1
            old_x, old_y = monitor.getCursorPos()
        end
        local event = {os.pullEvent()}

        pcall(function()
            if event[1] == "stargate_incoming_wormhole" then
                screensaver_text = "  Incoming Wormhole  "
                screensaver_color = colors.orange
                if event[3] then
                    local address_incoming = addressLookupCached(event[3])
                    if address_incoming then
                        status_text = address_incoming.name or table.concat(event[3], "-")
                    else
                        status_text = table.concat(event[3], "-")
                    end
                    status_color = colors.yellow
                    if monitor and config.monitor then
                        monitor.setCursorPos(math.ceil(width/2)-math.floor(#status_text/2), 3)
                        monitor.clearLine()
                        monitor.setTextColor(status_color)
                        monitor.write(status_text)
                    end
                    writeToDisplayLink("Incoming Wormhole", status_text, true, true, false)
                else
                    writeToDisplayLink("Incoming Wormhole", "Unknown Origin", true, true, false)
                end
            elseif event[1] == "stargate_outgoing_wormhole" and not is_dialing then
                screensaver_text = "  Outgoing Wormhole  "
                screensaver_color = colors.green
                if event[3] then
                    local address_outgoing = addressLookupCached(event[3])
                    if address_outgoing then
                        status_text = address_outgoing.name or table.concat(event[3], "-")
                    else
                        status_text = table.concat(event[3], "-")
                    end
                    status_color = colors.yellow
                    if monitor and config.monitor then
                        monitor.setCursorPos(math.ceil(width/2)-math.floor(#status_text/2), 3)
                        monitor.clearLine()
                        monitor.setTextColor(status_color)
                        monitor.write(status_text)
                    end
                    if not is_dialing then
                        writeToDisplayLink("Outgoing Wormhole", status_text, true, true, false)
                    end
                else
                    writeToDisplayLink("Outgoing Wormhole", "Unknown Destination", true, true, false)
                end
            end
        end)
        if monitor and config.monitor then
            monitor.setCursorPos(old_x or 0, old_y or 0)
        end
    end
end

local function gateClosingMonitor()
        while true do
        local width, height
        local old_x, old_y
            local event = {os.pullEvent("stargate_disconnected")}

            status_color = colors.lightGray
            status_text = config.label or "No Label"
            if monitor and config.monitor then
                old_x, old_y = monitor.getCursorPos()
                width, height = monitor.getSize()
                width = width or 1
                height = height or 1
                screensaver_text = "  Stargate Idle  "
                screensaver_color = colors.gray
                monitor.setCursorPos(1, 3)
                monitor.clearLine()

                monitor.setCursorPos(math.ceil(width/2)-math.floor(#status_text/2), 3)
                monitor.clearLine()
                monitor.setTextColor(status_color)
                monitor.write(status_text)
                monitor.setCursorPos(old_x, old_y)
            end

            writeToDisplayLink("Stargate Idle", config.label, true, true, false)
    end
end

local gate_target_symbol = 0
if sg.rotateClockwise then
    gate_target_symbol = sg.getCurrentSymbol()
end
local update_timer = 0
local has_updated = true
local awaiting_encode = false
 
local absolute_buffer
local function rawAbsoluteListener()
    sleep(0.25)
    while true do
        local id, msg, protocol
        if not absolute_buffer then
            id, msg, protocol = rednet.receive("jjs_sg_rawcommand")
            rednet.send(id, "", "jjs_sg_rawcommand_confirm")

            if msg == "gate_disconnect" then
                clearGate()
                fancyReboot()
            end
        else
            msg = absolute_buffer
            absolute_buffer = nil
        end

        --debugLog("Received: "..msg)

        if tonumber(msg) and tonumber(msg) < 39 then
            local symbol = tonumber(msg)
            if symbol == 0 then
                if sg.isStargateConnected() then
                    clearGate()
                    fancyReboot()
                else
                    os.queueEvent("key", keys.enter, false)
                end
                --debugLog("Pressed Enter")
            elseif symbol > 0 and symbol < 39 then
                local symbol_string = tostring(symbol)
                for i1=1, #symbol_string do
                    os.queueEvent("char", tostring(symbol_string:sub(i1,i1)))
                    os.sleep()
                end
                os.sleep()
                os.queueEvent("key", keys.space, false)
                --debugLog("Pressed Space")
            end
        end
    end
end

local slow_engaging = {
    ["sgjourney:pegasus_stargate"] = true,
    ["sgjourney:universe_stargate"] = true
}

local function rawCommandListener()
    while true do
        local id, msg, protocol = rednet.receive("jjs_sg_rawcommand")
        rednet.send(id, "", "jjs_sg_rawcommand_confirm")
        if not sg.engageSymbol and sg.rotateClockwise then
            if msg == "left" then
                local current_symbol = sg.getCurrentSymbol()
                gate_target_symbol = (gate_target_symbol+1)%39
                update_timer = 10
                has_updated = false
            elseif msg == "right" then
                local current_symbol = sg.getCurrentSymbol()
                gate_target_symbol = (gate_target_symbol-1)%39
                update_timer = 10
                has_updated = false
            elseif msg == "click" then
                if sg.getCurrentSymbol() == gate_target_symbol then
                    sleep(0.25)
                    if sg.openChevron then
                        sg.openChevron()
                        sleep(0.1)
                        sg.encodeChevron()
                        sleep(0.1)
                        sg.closeChevron()
                    else
                        sg.encodeChevron()
                    end
                else
                    awaiting_encode = true
                end
            end
        end
        if tonumber(msg) then
            local symbol = tonumber(msg)
            if symbol == 0 and (sg.isStargateConnected()) then
                clearGate()
            else
                is_dialing = true
                absolute_buffer = msg
                parallel.waitForAny(inputThread, dialThread, rawAbsoluteListener, lastAddressSaverThread)
            end
        end
        if msg == "gate_disconnect" then
            clearGate()
            fancyReboot()
        end
        if msg == "gate_dialback" then
            if sg.isStargateConnected() or sg.getChevronsEngaged() > 0 then
                sg.disconnectStargate()
            end
            is_dialing = true
            parallel.waitForAll(inputThread, dialThread, autoDialbackThread, disconnectListener, lastAddressSaverThread)
        end
    end
end

local function rawCommandSpinner()
    while true do
        if sg.getCurrentSymbol then
            if not has_updated and sg.getCurrentSymbol() ~= gate_target_symbol and update_timer <= 0 then
                has_updated = true
                if (gate_target_symbol-sg.getCurrentSymbol()) % 39 < 19 then
                    sg.rotateAntiClockwise(gate_target_symbol)
                else
                    sg.rotateClockwise(gate_target_symbol)
                end
            end
            if update_timer > 0 then
                update_timer = update_timer-1
            end
            if awaiting_encode and sg.getCurrentSymbol() == gate_target_symbol then
                awaiting_encode = false
                sleep(0.5)
                if sg.openChevron then
                    sg.openChevron()
                    sleep(0.1)
                    sg.encodeChevron()
                    sleep(0.1)
                    sg.closeChevron()
                else
                    sg.encodeChevron()
                end
            end
        sleep()
        else
            sleep(10)
        end
    end
end

local function checkAliveThread()
    if modem then
    modem.open(os.getComputerID())
    while true do
        local event, side, channel, reply_channel, message, distance = os.pullEvent("modem_message")
        if type(message) == "table" then
            if message.protocol == "jjs_checkalive" and message.message == "ask_alive" then
                modem.transmit(reply_channel, os.getComputerID(), {protocol="jjs_checkalive", message="confirm_alive"})
                end
            end
        end
    end
end

local function irisControlThread()
    while true do
        local data = {os.pullEvent()}
        if config.iris_control then
            if data[1] == "transceiver_transmission_received" then
                local event, int, freq, code, correct = table.unpack(data)
                if correct and (sg.isWormholeOpen() or not sg.isStargateConnected()) then
                    sg.openIris()
                end
            elseif data[1] == "stargate_incoming_connection" then
                sg.closeIris()
            elseif (data[1] == "stargate_chevron_engaged" and data[6] == 0 and not data[5] and sg.isStargateConnected()) then
                sg.openIris()
            elseif data[1] == "stargate_disconnected" then
                sg.openIris()
            end
        end
    end
end

local function irisAntiKawooshThread()
    if anti_kawoosh_check then
        anti_kawoosh_check = false
        os.queueEvent("anti_kawoosh_await")
    end
    while true do
        local data = {os.pullEvent()}
        if config.iris_anti_kawoosh then
            if data[1] == "stargate_incoming_connection" or data[1] == "anti_kawoosh_await" or (data[1] == "stargate_chevron_engaged" and data[6] == 0 and not data[5] and sg.isStargateConnected()) then
                sg.closeIris()
                if not config.iris_control or data[1] == "stargate_chevron_engaged" or data[1] == "anti_kawoosh_await"  then
                    repeat
                        sleep(0.25)
                    until sg.isWormholeOpen() or not sg.isStargateConnected()
                    sg.openIris()
                end
            elseif data[1] == "stargate_disconnected" then
                sg.openIris()
            end
        end
    end
end

local function warnSystem()
    while true do
        os.pullEvent("stargate_incoming_connection")
        checkWarns()
    end
end

-- local function debugChar()
--     while true do
--         local event = {os.pullEvent()}
--         if event[1] == "char" then
--             local debug_data = ""
--             if fs.exists("char_debug.txt") then
--                 local debug_file = io.open("char_debug.txt", "r")
--                 debug_data = debug_file:read("*a")
--                 debug_file:close()
--             end
--         
--             debug_data = debug_data.."\n".."Char: "..event[2]
--             local debug_file2 = io.open("char_debug.txt", "w")
--             debug_file2:write(debug_data)
--             debug_file2:close()
--         elseif event[1] == "key" then
--             local debug_data = ""
--             if fs.exists("char_debug.txt") then
--                 local debug_file = io.open("char_debug.txt", "r")
--                 debug_data = debug_file:read("*a")
--                 debug_file:close()
--             end
--         
--             debug_data = debug_data.."\n".."Key: "..keys.getName(event[2])
--             local debug_file2 = io.open("char_debug.txt", "w")
--             debug_file2:write(debug_data)
--             debug_file2:close()
--         end
--     end
-- end

if sg.isStargateConnected() then
    if sg.isStargateDialingOut() then
        if sg.getConnectedAddress then
            os.queueEvent("stargate_outgoing_wormhole", peripheral.getName(sg), sg.getConnectedAddress())
        else
            os.queueEvent("stargate_outgoing_wormhole", nil)
        end
    else
    if sg.getConnectedAddress then
        os.queueEvent("stargate_incoming_wormhole", peripheral.getName(sg), sg.getConnectedAddress())
    else
        os.queueEvent("stargate_incoming_wormhole", nil)
        end
    end
end

local stat, err = pcall(function()
    parallel.waitForAll(mainThread, irisControlThread, mainRemote, mainFailsafe, mainRemoteCommands, mainRemoteDistance, screenSaverMonitor, gateMonitor, gateClosingMonitor, displayLinkUpdater, rawCommandListener, rawCommandSpinner, checkAliveThread, lastAddressSaverThread, irisAntiKawooshThread, monitorConnectThread, warnSystem)
end)

if not stat then
    if err == "Terminated" then
        fancyReboot()
    else
        log_to_file(err)
        error(err)
    end
end
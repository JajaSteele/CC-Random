local script_version = "1.2"

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

local update_source = "https://raw.githubusercontent.com/JajaSteele/CC-Random/main/SGJourney/barebone_remote_dial.lua"
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

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))

    modem.open(2707)
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

settings.define("sg.slowdial", {
    description = "Forces the gate to use slow dial (for MW only)",
    default = false,
    type = "boolean"
})

local slow_engaging = {
    ["sgjourney:pegasus_stargate"] = true,
    ["sgjourney:universe_stargate"] = true
}

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

local function engageChevron(number)
    if interface.engageSymbol and not (interface.rotateClockwise and settings.get("sg.slowdial")) then
        interface.engageSymbol(number)
        sleep(0.25)
    elseif interface.rotateClockwise then
        if interface.isChevronOpen(number) then
            interface.closeChevron()
        end

        if (number-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(number)
        else
            interface.rotateClockwise(number)
        end
        
        repeat
            sleep(0.1)
        until interface.getCurrentSymbol() == number

        sleep(0.1)
        interface.openChevron()
        sleep(0.1)
        interface.encodeChevron()
        sleep(0.1)
        interface.closeChevron()
    else
        print("Couldn't dial number!")
    end
end

local function mainRemote()
    while true do
        local id, msg, protocol = rednet.receive()
        if protocol == "jjs_sg_startdial" then
            print("Received dial request!")
            local temp_address = split(msg, "-")
            local address = {}

            for k,v in ipairs(temp_address) do
                if tonumber(v) then
                    address[#address+1] = tonumber(v)
                end
            end

            address[#address+1] = 0
            
            if (interface.isStargateConnected() and interface.isWormholeOpen()) or interface.getChevronsEngaged() > 0 then
                print("Disconnected gate")
                interface.disconnectStargate()
                sleep(0.25)
            end

            for k,v in ipairs(address) do
                engageChevron(v)
            end
            print(table.concat(address, "-"))
        end
    end
end


local function mainRemoteCommands()
    while true do
        local id, msg, protocol = rednet.receive()
        if protocol == "jjs_sg_disconnect" then
            print("Received disconnect request!")
            if (interface.isStargateConnected() and interface.isWormholeOpen()) or interface.getChevronsEngaged() > 0 then
                print("Disconnected gate")
                interface.disconnectStargate()
            end
        elseif protocol == "jjs_sg_getlabel" then
            rednet.send(id, (os.getComputerLabel() or ("Gate "..os.getComputerID())), "jjs_sg_sendlabel")
        end
    end
end

local function mainRemotePing()
    while true do
        local event, side, channel, reply_channel, message, distance = os.pullEvent("modem_message")
        if type(message) == "table" then
            if message.protocol == "jjs_sg_dialer_ping" and message.message == "request_ping" then
                modem.transmit(reply_channel, 2707, {protocol="jjs_sg_dialer_ping", message="response_ping", id=os.getComputerID(), label=(os.getComputerLabel() or ("Gate "..os.getComputerID()))})
            end
        end
    end
end

local gate_target_symbol = 0
local update_timer = 0
local has_updated = true
local awaiting_encode = false

local engage_queue = {}

local function rawCommandListener()
    while true do
        local id, msg, protocol = rednet.receive("jjs_sg_rawcommand")
        rednet.send(id, "", "jjs_sg_rawcommand_confirm")
        if interface.rotateClockwise then
            if msg == "left" then
                local current_symbol = interface.getCurrentSymbol()
                gate_target_symbol = (gate_target_symbol+1)%39
                update_timer = 10
                has_updated = false
            elseif msg == "right" then
                local current_symbol = interface.getCurrentSymbol()
                gate_target_symbol = (gate_target_symbol-1)%39
                update_timer = 10
                has_updated = false
            elseif msg == "click" then
                if interface.getCurrentSymbol() == gate_target_symbol then
                    interface.openChevron()
                    sleep(0.25)
                    interface.encodeChevron()
                    sleep(0.25)
                    interface.closeChevron()
                else
                    awaiting_encode = true
                end
            end
        end
        if tonumber(msg) then
            local symbol = tonumber(msg)
            if symbol == 0 and (interface.isStargateConnected())then
                interface.disconnectStargate()
                print("SGW: Disconnecting Gate")
            elseif symbol >= 0 and symbol < 39 then
                if engage_queue[#engage_queue] ~= symbol then
                    engage_queue[#engage_queue+1] = symbol
                    print("SGW: Queuing "..symbol)
                end
            end
        end
        if msg == "gate_disconnect" then
            engage_queue = {}
            interface.disconnectStargate()
            print("SGW: Disconnecting Gate")
        end
        if msg == "gate_dialback" then
            if interface.isStargateConnected() or interface.getChevronsEngaged() > 0 then
                interface.disconnectStargate()
            end
            for k,v in ipairs(last_address) do
                engage_queue[#engage_queue+1] = v
            end
            engage_queue[#engage_queue+1] = 0
        end
    end
end

local function rawCommandSpinner()
    while true do
        if not has_updated and update_timer <= 0 then
            has_updated = true
            if (gate_target_symbol-interface.getCurrentSymbol()) % 39 < 19 then
                interface.rotateAntiClockwise(gate_target_symbol)
            else
                interface.rotateClockwise(gate_target_symbol)
            end
            print("Rotating to "..gate_target_symbol)
        end
        if update_timer > 0 then
            update_timer = update_timer-1
        end
        if awaiting_encode and interface.getCurrentSymbol() == gate_target_symbol then
            awaiting_encode = false
            sleep(0.5)
            interface.openChevron()
            sleep(0.25)
            interface.encodeChevron()
            sleep(0.25)
            interface.closeChevron()
        end
        sleep()
    end
end

local function engageQueueManager()
    while true do
        local last_engage = engage_queue[1]
        if last_engage then
            engageChevron(last_engage)
            print("SGW: Engaging "..last_engage)
            table.remove(engage_queue, 1)
        end
        sleep()
    end
end

local function checkAliveThread()
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

local function lastAddressSaverThread()
    if interface.getConnectedAddress and interface.isStargateConnected() then
        last_address = interface.getConnectedAddress()
        writeSave()
        print("Set last address to: "..table.concat(interface.getConnectedAddress(), " "))
    end
    while true do
        local event = {os.pullEvent()}
        if (event[1] == "stargate_incoming_wormhole" and (event[2] and event[2] ~= {})) or (event[1] == "stargate_outgoing_wormhole") then
            local old_last_address = table.concat(last_address, " ")
            last_address = event[2]
            if event[1] == "stargate_incoming_wormhole" then
                repeat
                    sleep(0.5)
                until interface.getOpenTime() > 6 or not interface.isStargateConnected()
                last_address = interface.getConnectedAddress()
            end
            if interface.isStargateConnected() and interface.getChevronsEngaged() >= 6 and #last_address >= 6 then
                writeSave()
                print("Set last address to: "..table.concat(last_address, " "))
            else
                local old_address = split(old_last_address, " ")
                last_address = {}
                for k,v in ipairs(old_address) do
                    if tonumber(v) then
                        last_address[#last_address+1] = tonumber(v)
                    end
                end
                print("Reverted last address to: "..table.concat(last_address, " "))
            end
        end
    end
end

while true do
    local stat, err = pcall(function()
        print("Starting threads")
        parallel.waitForAll(mainRemote, mainRemoteCommands, mainRemotePing, checkAliveThread, rawCommandSpinner, rawCommandListener, engageQueueManager, lastAddressSaverThread)
    end)
    if not stat then
        if err == "Terminated" then
            return
        else
            term.setTextColor(colors.red)
            print(err)
            term.setTextColor(colors.white)
        end
    end
end
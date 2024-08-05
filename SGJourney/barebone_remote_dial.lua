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
                engageChevron(symbol)
                print("SGW: Engaging "..symbol)
            end
        end
        if msg == "gate_disconnect" then
            interface.disconnectStargate()
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

while true do
    local stat, err = pcall(function()
        print("Starting threads")
        parallel.waitForAll(mainRemote, mainRemoteCommands, mainRemotePing, checkAliveThread, rawCommandSpinner, rawCommandListener)
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
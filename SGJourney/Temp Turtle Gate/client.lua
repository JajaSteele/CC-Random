local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function getStargateItem()
    for i1=1, 16 do
        turtle.select(i1)
        local item = turtle.getItemDetail()
        if item then
            if item.name:match("stargate") and not item.name:match("block") then
                return i1
            end
        end
    end
end

local function getInterfaceItem()
    for i1=1, 16 do
        turtle.select(i1)
        local item = turtle.getItemDetail()
        if item then
            if item.name:match("interface") and item.name:match("sgjourney") then
                return i1
            end
        end
    end
end

local function getShulkerItem()
    for i1=1, 16 do
        turtle.select(i1)
        local item = turtle.getItemDetail()
        if item then
            if item.name:match("shulker") then
                return i1
            end
        end
    end
end

local function findEquip(name)
    turtle.equipRight()
    local curr_item = turtle.getItemDetail()
    turtle.equipRight()

    if curr_item and curr_item.name:match(name) then
        return peripheral.wrap("right")
    else
        for i1=1, 16 do
            turtle.select(i1)
            local item = turtle.getItemDetail()
            if item then
                if item.name:match(name) then
                    turtle.equipRight()
                    return peripheral.wrap("right")
                end
            end
        end
    end
end

term.clear()
term.setCursorPos(1, 1)

print("Turtle Fuel Level:")
print(turtle.getFuelLevel().." / "..turtle.getFuelLimit().." - "..string.format("%.1f%%", (turtle.getFuelLevel()/turtle.getFuelLimit())*100))

local stargate_slot
local interface_slot
local shulker_slot

if (peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")) then
    stargate_slot = 1
    interface_slot = 2
    shulker_slot = 3
else
    print("Please put shulker in inventory..")

    repeat
        shulker_slot = getShulkerItem()
    until shulker_slot

    print("Shulker detected!")

    turtle.select(shulker_slot)
    turtle.place()

    sleep(0.25)

    print("Pulling out items..")
    repeat
        local stat = turtle.suck()
    until not stat

    repeat
        stargate_slot = getStargateItem()
        interface_slot = getInterfaceItem()
    until stargate_slot and interface_slot

    print("Setting up gate..")
    turtle.back()
    turtle.select(stargate_slot)
    turtle.place()
    turtle.back()
    turtle.select(interface_slot)
    turtle.place()
end

local modem = findEquip("wireless_modem")
rednet.open(peripheral.getName(modem))
modem.open(2707)

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local function engageChevron(number)
    if interface.engageSymbol then
        interface.engageSymbol(number)
        sleep(0.075)
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
            return
        elseif protocol == "jjs_sg_getlabel" then
            rednet.send(id, (os.getComputerLabel() or ("Gate "..os.getComputerID())), "jjs_sg_sendlabel")
        end
    end
end

local function quitOnDisconnect()
    while true do
        local event = {os.pullEvent()}
        if event[1] == "stargate_disconnected" then
            return
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
                return
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
            return
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

print("Gate Dialer ready!")
parallel.waitForAny(mainRemote, mainRemoteCommands, mainRemotePing, quitOnDisconnect, rawCommandListener, rawCommandSpinner, engageQueueManager, checkAliveThread)

sleep(1)

print("Starting return to home..")
findEquip("diamond_pickaxe")

turtle.select(interface_slot)
turtle.dig()
turtle.forward()
turtle.select(stargate_slot)
turtle.dig()
turtle.forward()

print("Storing items in shulker..")
for i1=1, 16 do
    turtle.select(i1)
    local item = turtle.getItemDetail()
    if item and not item.name:match("end_automata") then
        turtle.drop()
    end
end

turtle.select(shulker_slot)
turtle.dig()

print("Going home!")
local automata = findEquip("end_automata")

automata.savePoint("last_location")
automata.warpToPoint("home")
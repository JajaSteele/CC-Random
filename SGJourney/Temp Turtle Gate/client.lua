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

local function getSlabItem()
    for i1=1, 16 do
        turtle.select(i1)
        local item = turtle.getItemDetail()
        if item then
            if item.name:match("slab") then
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

local stargate_slot
local interface_slot
local slab_slot

if (peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")) then
    stargate_slot = 1
    interface_slot = 2
    slab_slot = 3
else
    print("Please put stargate, an interface, and a stair in inventory..")

    repeat
        stargate_slot = getStargateItem()
        interface_slot = getInterfaceItem()
        slab_slot = getSlabItem()
    until stargate_slot and interface_slot and slab_slot

    turtle.select(slab_slot)
    turtle.place()
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

parallel.waitForAny(mainRemote, mainRemoteCommands, mainRemotePing)

sleep(1)

findEquip("diamond_pickaxe")

turtle.select(interface_slot)
turtle.dig()
turtle.forward()
turtle.select(stargate_slot)
turtle.dig()
turtle.forward()
turtle.select(slab_slot)
turtle.dig()

local automata = findEquip("end_automata")

automata.savePoint("last_location")
automata.warpToPoint("home")
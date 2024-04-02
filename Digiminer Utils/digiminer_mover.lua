local data_save = {
    turn_count = 0,
    forward_count = 0,
    turn_threshold = 1
}

local pos_json_string = '["",{"text":"<","color":"gray"},{"text":"%d","color":"green"},{"text":">(","color":"gray"},{"text":"%s","color":"aqua"},{"text":")","color":"gray"},{"text":" Started at: "},{"text":"[$POS_X, $POS_Y, $POS_Z]","color":"gold","clickEvent":{"action":"copy_to_clipboard","value":"$POS_X $POS_Y $POS_Z"},"hoverEvent":{"action":"show_text","contents":"Click to copy"}},{"text":"\n   Fuel Level: "},{"text":"[%d%%]","color":"light_purple"}]'
local nofuel_json_string = '["",{"text":"<","color":"gray"},{"text":"%d","color":"green"},{"text":">(","color":"gray"},{"text":"%s","color":"aqua"},{"text":")","color":"gray"},{"text":" "},{"text":"NO FUEL!","bold":true,"underlined":true,"color":"red"},{"text":" New Pos: "},{"text":"[$POS_X, $POS_Y, $POS_Z]","color":"gold","clickEvent":{"action":"copy_to_clipboard","value":"$POS_X $POS_Y $POS_Z"},"hoverEvent":{"action":"show_text","contents":"Click to copy"}}]'

local function sendPosMsg(x,y,z)
    local cb = peripheral.find("chatBox")
    if cb then
        local msg_to_send = string.format(pos_json_string, os.getComputerID(), os.getComputerLabel(), (turtle.getFuelLevel()/turtle.getFuelLimit())*100)
        msg_to_send = msg_to_send:gsub("$POS_X", tostring(x))
        msg_to_send = msg_to_send:gsub("$POS_Y", tostring(y))
        msg_to_send = msg_to_send:gsub("$POS_Z", tostring(z))
        cb.sendFormattedMessageToPlayer(msg_to_send, "JajaSteele")
    end
end     

local function sendFuelMsg(x,y,z)
    local cb = peripheral.find("chatBox")
    if cb then
        local msg_to_send = string.format(nofuel_json_string, os.getComputerID(), os.getComputerLabel())
        local locate_msg = string.format('[name:"Turtle (%d) Position", x:%d, y:%d, z:%d]', os.getComputerID(), x, y, z)
        msg_to_send = msg_to_send:gsub("$POS_X", tostring(x))
        msg_to_send = msg_to_send:gsub("$POS_Y", tostring(y))
        msg_to_send = msg_to_send:gsub("$POS_Z", tostring(z))
        local stat = cb.sendFormattedMessageToPlayer(msg_to_send, "JajaSteele")
        sleep(1.1)
        local stat = cb.sendMessageToPlayer(locate_msg, "JajaSteele")
    else
        print("No Chatbox")
    end
end     

local function loadSave()
    if fs.exists("data_digi_mover.txt") then
        local file = io.open("data_digi_mover.txt", "r")
        data_save = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open("data_digi_mover.txt", "w")
    file:write(textutils.serialise(data_save))
    file:close()
end

loadSave()

turtle.select(16)
turtle.equipLeft()

rednet.open(peripheral.getName(peripheral.find("modem")))

local turtle_x, turtle_y, turtle_z = gps.locate()
rednet.broadcast({x=turtle_x, y=turtle_y, z=turtle_z, label=os.getComputerLabel()}, "jjs_turtle_newpos")

turtle.equipLeft()
turtle.select(15)

turtle.equipLeft()
sendPosMsg(turtle_x, turtle_y, turtle_z)

turtle.equipLeft()

while true do
    if turtle.getFuelLevel() == 0 then
        turtle.select(16)
        turtle.equipLeft()

        rednet.open(peripheral.getName(peripheral.find("modem")))

        local turtle_x, turtle_y, turtle_z = gps.locate()
        rednet.broadcast({x=turtle_x, y=turtle_y, z=turtle_z, label=os.getComputerLabel(), fuel=turtle.getFuelLevel(), fuel_max=turtle.getFuelLimit()}, "jjs_turtle_nofuel")

        turtle.equipLeft()
        turtle.select(15)

        turtle.equipLeft()
        sendFuelMsg(turtle_x, turtle_y, turtle_z)

        turtle.equipLeft()
        error("NO FUEL")
    end
    if not peripheral.find("digitalMiner") then
        turtle.select(1)
        turtle.placeUp()

        turtle.turnLeft()
        turtle.turnLeft()
        turtle.back()

        turtle.select(2)
        turtle.place()

        turtle.back()
        turtle.up()
        turtle.up()
        turtle.up()

        turtle.select(3)
        turtle.placeDown()

        turtle.forward()
        turtle.forward()
    else
        print("digiminer already placed, skipping placement..")
    end
    local digi = peripheral.wrap("bottom")
    digi.start()
    digi.setAutoEject(true)

    repeat
        sleep(2)
        term.clear()
        term.setCursorPos(1,1)
        print("Ores left: "..digi.getToMine())
        print("Data:")
        print("turn_count: "..data_save.turn_count)
        print("forward_count: "..data_save.forward_count)
        print("turn_threshold: "..data_save.turn_threshold)
    until digi.getToMine() == 0

    print("Changing Position!")
    
    digi.setAutoEject(false)
    digi.stop()

    turtle.back()
    turtle.back()

    turtle.select(3)
    turtle.digDown()

    turtle.down()
    turtle.down()
    turtle.down()
    turtle.forward()

    turtle.select(2)
    turtle.dig()

    turtle.forward()

    turtle.select(1)
    turtle.digUp()

    turtle.turnLeft()
    turtle.turnLeft()

    for i1=1, 64 do
        turtle.forward()
        turtle.dig()
        term.setCursorPos(1,1)
        term.write("Moving: "..i1.."/64")
    end

    data_save.forward_count = data_save.forward_count + 1
    if data_save.forward_count >= data_save.turn_threshold then
        turtle.turnRight()
        data_save.forward_count = 0
        data_save.turn_count = data_save.turn_count + 1
        if data_save.turn_count >= 2 then
            data_save.turn_threshold = data_save.turn_threshold+1
            data_save.turn_count = 0
        end
    end
    writeSave()

    turtle.select(16)
    turtle.equipLeft()

    rednet.open(peripheral.getName(peripheral.find("modem")))

    local turtle_x, turtle_y, turtle_z = gps.locate()
    rednet.broadcast({x=turtle_x, y=turtle_y, z=turtle_z, label=os.getComputerLabel(), fuel=turtle.getFuelLevel(), fuel_max=turtle.getFuelLimit()}, "jjs_turtle_newpos")

    turtle.equipLeft()
end
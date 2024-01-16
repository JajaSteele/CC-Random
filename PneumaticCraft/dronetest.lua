local drone = peripheral.find("drone_interface")
local ply = peripheral.find("playerDetector")
local chatbox = peripheral.find("chatBox")

local help_message = '["",{"text":"TP-Drone is a system that can teleport a player anywhere almost instantly (Only in overworld for now).","color":"green"},{"text":"\n\n"},{"text":"There are two different modes, to activate them, you simply need to send the following commands (without a /) into chat:","color":"yellow"},{"text":"\n\n"},{"text":"tpdrone absolute <x> <y> <z>","bold":true,"color":"light_purple","clickEvent":{"action":"suggest_command","value":"tpdrone absolute 0 0 0"},"hoverEvent":{"action":"show_text","contents":"Click to quickly copy the command"}},{"text":" ","color":"light_purple","clickEvent":{"action":"suggest_command","value":"tpdrone absolute 0 0 0"},"hoverEvent":{"action":"show_text","contents":"Click to quickly copy the command"}},{"text":"\n"},{"text":"Which teleports you to the XYZ coordinates given","color":"yellow"},{"text":"\n\n"},{"text":"tpdrone player <username>","bold":true,"color":"light_purple","clickEvent":{"action":"suggest_command","value":"tpdrone player username_here"},"hoverEvent":{"action":"show_text","contents":"Click to quickly copy the command"}},{"text":" ","color":"light_purple","clickEvent":{"action":"suggest_command","value":"tpdrone player username_here"},"hoverEvent":{"action":"show_text","contents":"Click to quickly copy the command"}},{"text":"\n"},{"text":"Which teleports you to the given player","color":"yellow"},{"text":"\n\n"},{"text":"tpdrone relative <distance> <y>","bold":true,"color":"light_purple","clickEvent":{"action":"suggest_command","value":"tpdrone relative 0 0"},"hoverEvent":{"action":"show_text","contents":"Click to quickly copy the command"}},{"text":"\n"},{"text":"Which teleports you <distance> blocks toward where you\'re currently looking, at <y> altitude (useful if you\'re using a structure/nature\'s compass for example)","color":"yellow"}]'

local message_queue = {}

local drone_needed = {
    help=false,
    absolute=true,
    relative=true,
    player=true
}

local function sendMessage(text, player, whisper)
    message_queue[#message_queue+1] = {
        type="plain",
        text=text,
        player=player,
        whisper=whisper
    }
end

local function sendFormattedMessage(json_text, player, whisper)
    message_queue[#message_queue+1] = {
        type="formatted",
        text=json_text,
        player=player,
        whisper=whisper
    }
end

local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function front_of_pos(pos_x, pos_z, rotation, distance)
    local x = pos_x + math.cos(rotation) * distance
    local z = pos_x + math.sin(rotation) * distance
    return x, z
end

local messageThread = function()
    while true do
        local sleep_time = 0
        for k,v in ipairs(message_queue) do
            if v.type == "plain" then
                if v.whisper then
                    chatbox.sendMessageToPlayer(v.text, v.player, "\xA7bTP-Drone\xA7r")
                else
                    chatbox.sendMessage(v.text, "\xA7bTP-Drone\xA7r")
                end
            elseif v.type == "formatted" then
                if v.whisper then
                    chatbox.sendFormattedMessageToPlayer(v.text, v.player, "\xA7bTP-Drone\xA7r")
                else
                    chatbox.sendFormattedMessage(v.text, "\xA7bTP-Drone\xA7r")
                end
            end
            table.remove(message_queue, k)
            sleep_time = 1.1
            break
        end
        sleep(sleep_time)
    end
end

local mainThread = function()
    while true do
        local event, username, message, uuid, hidden = os.pullEvent("chat")
        local cmd = split(message, " ")

        if cmd[1] == "tpdrone" then
            local player_pos = ply.getPlayerPos(username)

            print("["..username.."] "..message)

            if drone_needed[cmd[2]] then
                sendMessage("\xA7eCommand received! Drone is starting up..", username, true)

                rs.setAnalogOutput("front", 15)
                sleep(1)
                rs.setAnalogOutput("front", 0)

                repeat
                    sleep(0.5)
                until drone.isConnectedToDrone()

                drone.clearArea()
            end

            if cmd[2] == "relative" then
                sendMessage("\xA7cDrone is ready, do NOT move!", username, hidden)
                local distance, y = tonumber(cmd[3]), tonumber(cmd[4])

                local x,z = front_of_pos(player_pos.x, player_pos.z, ((player_pos.yaw%360)-270)%360, distance)
                
                x,y,z = math.ceil(x+0.5), math.ceil(y+0.5), math.ceil(z+0.5)

                print("Target: "..x.." "..y.." "..z)

                drone.addArea(player_pos.x-1, player_pos.y, player_pos.z-1, player_pos.x+1, player_pos.y, player_pos.z+1, "Filled")
                drone.showArea()

                drone.setAction("pneumaticcraft:entity_import")
                sleep(1)
                print("Picking up player..")

                repeat
                    sleep(1)
                until drone.isActionDone()

                drone.hideArea()
                drone.clearArea()
                
                drone.addArea(x+2,y+2,z+2, x-2,y-2,z-2, "Filled")
                drone.setAction("pneumaticcraft:teleport")
                print("Teleporting to destination..")
                sendMessage("\xA7eAttempting teleportation..", username, hidden)

                repeat
                    sleep(1)
                until drone.isActionDone()

                sendMessage("\xA7eDropping player..", username, hidden)

                drone.clearArea()

                sleep(3)

                drone.addArea(x+2,y+2,z+2, x-2,y-2,z-2, "Filled")
                drone.setAction("pneumaticcraft:entity_export")
                sleep(1)
                print("Dismounting player..")

                repeat
                    sleep(1)
                until drone.isActionDone()

                sendMessage("\xA7eGoing home..", username, hidden)

                drone.clearArea()

                drone.exitPiece()
                print("CMD Terminated! Going home!")
            elseif cmd[2] == "absolute" then
                sendMessage("\xA7cDrone is ready, do NOT move!", username, hidden)
                local x,y,z = tonumber(cmd[3]), tonumber(cmd[4]), tonumber(cmd[5])

                x,y,z = math.ceil(x+0.5), math.ceil(y+0.5), math.ceil(z+0.5)

                print("Target: "..x.." "..y.." "..z)

                drone.addArea(player_pos.x-1, player_pos.y, player_pos.z-1, player_pos.x+1, player_pos.y, player_pos.z+1, "Filled")
                drone.showArea()

                drone.setAction("pneumaticcraft:entity_import")
                sleep(1)
                print("Picking up player..")

                repeat
                    sleep(1)
                until drone.isActionDone()

                drone.hideArea()
                drone.clearArea()
                

                drone.addArea(x, y, z)
                drone.setAction("pneumaticcraft:teleport")
                sleep(1)
                print("Teleporting to destination..")

                repeat
                    sleep(1)
                until drone.isActionDone()

                drone.clearArea()

                sleep(3)

                drone.addArea(x,y,z, x,y,z, "Filled")
                drone.setAction("pneumaticcraft:entity_export")
                sleep(1)
                print("Dismounting player..")

                repeat
                    sleep(1)
                until drone.isActionDone()

                drone.clearArea()

                drone.exitPiece()
                print("CMD Terminated! Going home!")
            elseif cmd[2] == "player" then
                sendMessage("\xA7cDrone is ready, do NOT move!", username, hidden)
                local username = cmd[3]
                local target_player_pos = ply.getPlayerPos(username)
                local x,y,z = target_player_pos.x, target_player_pos.y, target_player_pos.z

                x,y,z = math.ceil(x+0.5), math.ceil(y+0.5), math.ceil(z+0.5)

                print("Target: "..x.." "..y.." "..z)

                drone.addArea(player_pos.x-1, player_pos.y, player_pos.z-1, player_pos.x+1, player_pos.y, player_pos.z+1, "Filled")
                drone.showArea()

                drone.setAction("pneumaticcraft:entity_import")
                sleep(1)
                print("Picking up player..")

                repeat
                    sleep(1)
                until drone.isActionDone()

                drone.hideArea()
                drone.clearArea()
                

                drone.addArea(x, y, z)
                drone.setAction("pneumaticcraft:teleport")
                sleep(1)
                print("Teleporting to destination..")

                repeat
                    sleep(1)
                until drone.isActionDone()

                drone.clearArea()

                sleep(3)

                drone.addArea(x,y,z, x,y,z, "Filled")
                drone.setAction("pneumaticcraft:entity_export")
                sleep(1)
                print("Dismounting player..")

                repeat
                    sleep(1)
                until drone.isActionDone()

                drone.clearArea()

                drone.exitPiece()
                print("CMD Terminated! Going home!")
            elseif cmd[2] == "help" then
                sendFormattedMessage(help_message, username, true)
            else
                print("Unknown Command!")
                sendMessage("\xA7cUnknown Command! Use \xA76tpdrone help\xA7c to see the usage", username, true)
            end
        end
    end
end

parallel.waitForAny(mainThread,messageThread)
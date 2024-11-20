local compass = peripheral.find("compass")
local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end
local function toPos(x,y,z)
    return {x=math.floor(tonumber(x)), y=math.floor(tonumber(y)), z=math.floor(tonumber(z))}
end

local width, height = term.getSize()

local function findItem(name)
    for i1=1, 16 do
        local item = turtle.getItemDetail(i1)
        if item and item.name:match(name) then
            return i1
        end
    end
end

local function getItemCount(name)
    local count = 0
    for i1=1, 16 do
        local item = turtle.getItemDetail(i1)
        if item and item.name:match(name) then
            count = count+turtle.getItemCount(i1)
        end
    end
    return count
end

local player_owner = ""

local function equipItem(name)
    for i1=1, 16 do
        local item = turtle.getItemDetail(i1)
        if item and item.name:match(name) then
            turtle.select(i1)
            turtle.equipLeft()
            turtle.select(1)
            sleep(0.1)
            return turtle.getItemDetail(i1)
        end
    end
end

local function getPos()
    local old_item = equipItem("modem")
    local x,y,z = gps.locate()
    equipItem(old_item.name)
    return {x=x, y=y, z=z}
end

local function grabInterfaceItem(name, count)
    print("ME Interface: "..name.." x"..count)
    local missing_count = count
    sleep(0.2)
    local interface = peripheral.find("meBridge")
    if not interface then
        repeat
            sleep(0.2)
            interface = peripheral.find("meBridge")
        until interface
    end
    local list = interface.listItems()
    if not list then
        repeat
            sleep(0.2)
            list = interface.listItems()
        until list
    end
    local target = ""
    for k,v in pairs(list) do
        if v.name:match(name) then
            target = v.name
            missing_count = missing_count or v.amount
            print(k.."/"..#list)
            break
        end
    end
    repeat
        local amount = interface.exportItem({name=target, count=missing_count}, "back")
        missing_count = missing_count-amount
    until missing_count <= 0
end

local function sendMessage(msg)
    local old_item = equipItem("chat_box")
    local cb = peripheral.find("chatBox")
    for i1=1, 5 do
        local success = cb.sendMessageToPlayer(msg, player_owner, "Railer")
        if success then return true end
        sleep(0.5)
    end
    equipItem(old_item.name)
    printError("Couldn't send message!")
end

local function deployInterface()
    print("Deploying ME Interface")
    turtle.up()

    turtle.select(findItem("quantum_ring"))
    turtle.turnLeft()

    turtle.placeDown()
    turtle.placeUp()

    turtle.forward()
    turtle.placeDown()
    turtle.placeUp()

    turtle.back()
    turtle.place()

    turtle.back()
    turtle.placeDown()
    turtle.placeUp()
    turtle.select(findItem("quantum_link"))
    turtle.place()
    turtle.select(findItem("entangled_sing"))
    turtle.drop()

    turtle.back()
    turtle.select(findItem("quantum_ring"))
    turtle.place()

    turtle.down()
    turtle.select(findItem("me_bridge"))
    turtle.placeUp()
end

local function packInterface()
    print("Picking up ME Interface")
    local old_item = equipItem("pickaxe")
    turtle.digUp()

    turtle.up()
    turtle.dig()

    turtle.forward()
    turtle.digUp()
    turtle.digDown()
    turtle.dig()

    turtle.forward()
    turtle.digUp()
    turtle.digDown()
    turtle.dig()

    turtle.forward()
    turtle.digUp()
    turtle.digDown()

    turtle.back()
    turtle.turnRight()
    turtle.down()
    equipItem(old_item.name)
end

local function deployPortal()
    local obsidian_count = getItemCount("obsidian")
    deployInterface()
    grabInterfaceItem("minecraft:obsidian", 36-obsidian_count)
    grabInterfaceItem("minecraft:flint_and_steel", 1)
    grabInterfaceItem("track_station", 1)
    packInterface()

    local old_item = equipItem("pickaxe")

    turtle.digDown()

    for i1=1, 4 do
        turtle.back()
    end
    turtle.select(findItem("track_station"))
    turtle.placeDown()

    equipItem(old_item.name)

    turtle.select(findItem("obsidian"))

    for i1=1, 4 do
        turtle.forward()
    end
    turtle.forward()

    turtle.down()
    turtle.turnLeft()
    turtle.placeDown()

    for i1=1, 3 do
        turtle.forward()
        turtle.placeDown()
    end

    turtle.place()

    for i1=1, 7 do
        turtle.up()
        turtle.place()
    end
    turtle.placeUp()

    for i1=1, 6 do
        turtle.back()
        turtle.placeUp()
    end
    turtle.turnLeft()
    turtle.turnLeft()
    turtle.place()

    for i1=1, 7 do
        turtle.down()
        turtle.place()
    end
    turtle.placeDown()

    for i1=1, 2 do
        turtle.back()
        turtle.placeDown()
    end
    turtle.back()

    turtle.turnLeft()
    turtle.back()
    turtle.select(findItem("flint_and_steel"))
    turtle.place()
    turtle.down()

    turtle.back()
    turtle.select(findItem("track_station"))
    turtle.place()
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

local facing_order = {
    north=0,
    east=1,
    south=2,
    west=3,

    [0] = "north",
    [1] = "east",
    [2] = "south",
    [3] = "west",
}

local prettyTurn = {
    [-1] = "Left",
    [1] = "Right",
    [0] = "Front"
}

local dir_to_facing = {
    ["+x"] = 1,
    ["-x"] = 3,
    ["+z"] = 2,
    ["-z"] = 0
}

local function dirRotation(start, target)
    if (start + 1)%4 == target then
        return 1
    elseif (start - 1)%4 == target then
        return -1
    elseif start == target then
        return 0
    else
        return 1
    end
end

local start_pos = getPos()
local target_pos = {}

print("Enter target OW coordinates: X (Y) Z")
local input = read()
print("Enter station name:")
local name = read()
print("Enter username (for chat msgs)")
player_owner = read()

target_pos = toPos(input:match("([-]?%d+) ([-]?%d+) ([-]?%d+)"))
print("OW Coords: "..target_pos.x.." "..target_pos.z)
target_pos.x = math.floor(target_pos.x / 8)
target_pos.y = math.floor(target_pos.y)
target_pos.z = math.floor(target_pos.z / 8)
print("Nether Coords: "..target_pos.x.." "..target_pos.z)

sleep(0.5)

equipItem("compass")
compass = peripheral.find("compass")
local start_facing = facing_order[compass.getFacing()]

local first_dir = ""
local x_distance = start_pos.x - target_pos.x
local z_distance = start_pos.z - target_pos.z

if math.abs(z_distance) > math.abs(x_distance) then
    if target_pos.z > start_pos.z then
        first_dir = "+z"
    else
        first_dir = "-z"
    end
else
    if target_pos.x > start_pos.x then
        first_dir = "+x"
    else
        first_dir = "-x"
    end
end
local first_facing = dir_to_facing[first_dir]

print("Simulating path..")

local instructions = {}
local virtual_facing = start_facing
local virtual_length = 0
local virtual_position = {x=start_pos.x, z=start_pos.z}

local function virtual_forward(count, facing)
    if facing == 1 then -- East
        virtual_position.x = virtual_position.x + count
    elseif facing == 3 then --West
        virtual_position.x = virtual_position.x - count
    elseif facing == 2 then --South
        virtual_position.z = virtual_position.z + count
    elseif facing == 0 then -- North
        virtual_position.z = virtual_position.z - count
    end
end

print("Generating..")

repeat
    if virtual_facing ~= first_facing then
        local turn = dirRotation(virtual_facing, first_facing)
        instructions[#instructions+1] = {
            type = "turn",
            value = turn
        }
        virtual_forward(10, virtual_facing)
        virtual_facing = (virtual_facing+turn)%4
        virtual_forward(10, virtual_facing)
        print("Turning: "..prettyTurn[turn].." Curr: "..facing_order[virtual_facing])
        sleep(0.1)
    end
until virtual_facing == first_facing

sleep(0.5)

x_distance = math.abs(target_pos.x - virtual_position.x)
z_distance = math.abs(target_pos.z - virtual_position.z)

local target_length = 0
if first_dir:match("x") then
    target_length = math.abs(x_distance)-10
elseif first_dir:match("z") then
    target_length = math.abs(z_distance)-10
end

repeat
    local segment_length = clamp(target_length-virtual_length, 0, 32)
    instructions[#instructions+1] = {
        type = "forward",
        value = segment_length
    }
    virtual_length = virtual_length+segment_length
    virtual_forward(segment_length, virtual_facing)
    print("Forward: "..segment_length.." Curr: "..virtual_length.."/"..target_length)
    sleep(0)
until virtual_length == target_length

sleep(0.5)

local second_dir = ""

if math.abs(z_distance) > math.abs(x_distance) then
    if target_pos.x > start_pos.x then
        second_dir = "+x"
    else
        second_dir = "-x"
    end
else
    if target_pos.z > start_pos.z then
        second_dir = "+z"
    else
        second_dir = "-z"
    end
end

local second_facing = dir_to_facing[second_dir]

repeat
    if virtual_facing ~= second_facing then
        local turn = dirRotation(virtual_facing, second_facing)
        instructions[#instructions+1] = {
            type = "turn",
            value = turn
        }
        virtual_forward(10, virtual_facing)
        virtual_facing = (virtual_facing+turn)%4
        virtual_forward(10, virtual_facing)
        print("Turning: "..prettyTurn[turn].." Curr: "..facing_order[virtual_facing])
        sleep(0.1)
    end
until virtual_facing == second_facing

sleep(0.5)

local virtual_length = 0

x_distance = math.abs(target_pos.x - virtual_position.x)
z_distance = math.abs(target_pos.z - virtual_position.z)

if first_dir:match("x") then
    target_length = math.abs(z_distance)-1
elseif first_dir:match("z") then
    target_length = math.abs(x_distance)-1
end

repeat
    local segment_length = clamp(target_length-virtual_length, 0, 32)
    instructions[#instructions+1] = {
        type = "forward",
        value = segment_length
    }
    virtual_length = virtual_length+segment_length
    virtual_forward(segment_length, virtual_facing)
    print("Forward: "..segment_length.." Curr: "..virtual_length.."/"..target_length)
    sleep(0)
until virtual_length == target_length

sleep(0.5)

print("Starting!")
sendMessage("Starting construction")

for k, inst in ipairs(instructions) do
    local track_count = getItemCount("tieless")
    if track_count < 48 then
        sendMessage("Not enough tracks, refilling..")
        print("Not enough tracks!")
        deployInterface()
        grabInterfaceItem("track_tieless", 256-track_count)
        packInterface()
    end
    turtle.select(findItem("track_tieless"))
    if inst.type == "turn" then
        local msg = "("..k.."/"..#instructions..") "..prettyTurn[inst.value].." turn"
        print(msg)
        turtle.placeDown()
        for i1=1, 10 do
            turtle.forward()
            write(1, height-1, msg.." ("..i1.."/10)")
        end
        if inst.value > 0 then
            turtle.turnRight()
        else
            turtle.turnLeft()
        end
        write(1, height-1, msg.." (10/10, "..prettyTurn[inst.value]..")")
        for i1=1, 10 do
            turtle.forward()
            write(1, height-1, msg.." (10/10, "..prettyTurn[inst.value]..", "..i1.."/10)")
        end
        turtle.placeDown()
    elseif inst.type == "forward" then
        local msg = "("..k.."/"..#instructions..") ".."Moving "..inst.value.." blocks"
        print(msg)
        turtle.placeDown()
        for i1=1, inst.value do
            turtle.forward()
            write(1, height-1, msg.." ("..i1.."/"..inst.value..")")
        end
        turtle.placeDown()
    end
end

sendMessage("Starting portal deployment")

print("Done!")
deployPortal()

local station = peripheral.find("Create_Station")
repeat
    station = peripheral.find("Create_Station")
until station
station.setStationName(name)

sendMessage("Station deployed! '"..name.."'")
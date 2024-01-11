print("Insert Address (with spaces, eg. 1 13 4 51 4) or 'back' for last entered address")

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local curr_symbol = 0

local function engageSymbol(target)
    local dist
    dist = math.abs(target - curr_symbol)
    dist = math.min(dist, 39-dist)

    print("Distance: "..dist)

    local error = 0

    if (target-curr_symbol) % 38 < 19 then
        for i2=1, dist*4 do
            rs.setAnalogOutput("front", 14)
            sleep()
            rs.setAnalogOutput("front", 0)
        end
        error = error+dist*(0.6153846153846)
        if error > 1 then
            repeat
                rs.setAnalogOutput("front", 14)
                sleep()
                rs.setAnalogOutput("front", 0)
                error = error-1
                print("Error: "..error)
            until error < 1
        end
    else
        for i2=1, dist*4 do
            rs.setAnalogOutput("front", 5)
            sleep()
            rs.setAnalogOutput("front", 0)
        end
        error = error-dist*(0.6153846153846)
        if error < -1 then
            repeat
                rs.setAnalogOutput("front", 5)
                sleep()
                rs.setAnalogOutput("front", 0)
                error = error+1
                print("Error: "..error)
            until error > -1
        end
    end

    rs.setAnalogOutput("front", 15)
    sleep(0.5)
    rs.setAnalogOutput("front", 0)

    curr_symbol = target
end

local address = read()

if address == "back" then
    local file = io.open("mdial_last_address.txt", "r")
    address = file:read("*a")
    file:close()
else
    local file = io.open("mdial_last_address.txt", "w")
    file:write(address)
    file:close()
end

local address_table = split(address, " ")

local found_stargate = false

local stat, data = turtle.inspect()
if data.name == "sgjourney:milky_way_stargate" then
    goto start_dial
end

for i1=1, 5 do
    local stat, data = turtle.inspectDown()
    if data.name == "sgjourney:milky_way_stargate" then
        found_stargate = true
        break
    else
        turtle.digDown()
        turtle.down()
    end
end

if not found_stargate then
    for i1=1, 5 do
        turtle.up()
    end
    error("Couldn't find any stargate!")
    return
end

turtle.turnLeft()
turtle.turnLeft()

turtle.dig()
turtle.forward()

turtle.turnLeft()
turtle.turnLeft()

turtle.digDown()
turtle.down()

::start_dial::

turtle.dig()

local found_item = false

for i1=1, 16 do
    local data = turtle.getItemDetail(i1, true)
    if data and data.name == "sgjourney:milky_way_stargate" then
        found_item = true
        turtle.select(i1)
        break
    end
end

if found_item then
    turtle.place()
else
    error("Can't find item")
end

for k,v in ipairs(address_table) do
    print("Moving from "..curr_symbol.." to "..v)
    engageSymbol(tonumber(v))
    os.sleep(0.5)
end

turtle.up()

turtle.turnLeft()
turtle.turnLeft()

turtle.dig()
turtle.forward()
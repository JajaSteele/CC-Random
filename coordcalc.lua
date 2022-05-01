local function onlypos(n)
    if n < 0 then n = -n end
    return n
end

local chatbox = peripheral.find("chatBox")

local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function chat(t)
    if userName ~= "" and chatbox ~= nil then
        chatbox.sendMessageToPlayer(t,userName)
    end
end

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end

repeat
    clear()
    term.setTextColor(0x1)
    print("Please enter current coords:")
    print("X Y Z")
    term.setTextColor(0x100)
    currCoords = split(io.read()," ")
until #currCoords == 3

repeat
    clear()
    term.setTextColor(0x1)
    print("Please enter target coords:")
    print("X Y Z")
    term.setTextColor(0x100)
    tarCoords = split(io.read()," ")
until #currCoords == 3


clear()
term.setTextColor(0x1)
print("Please your username:\n(or leave blank to disable chat msg)")
term.setTextColor(0x100)
userName = io.read()
chat("Hello World!")


currX = tonumber(currCoords[1])
currY = tonumber(currCoords[2])
currZ = tonumber(currCoords[3])

tarX = tonumber(tarCoords[1])
tarY = tonumber(tarCoords[2])
tarZ = tonumber(tarCoords[3])

term.setTextColor(0x1)
print(currX.." "..currY.." "..currZ.." >>> "..tarX.." "..tarY.." "..tarZ)

dist1 = tarX-currX
dist2 = tarY-currY
dist3 = tarZ-currZ

if dist1 < 0 then dist1 = -dist1 end
if dist2 < 0 then dist2 = -dist2 end
if dist3 < 0 then dist3 = -dist3 end

totaldist = dist1+dist2+dist3

flatdist = dist1+dist3

print("Distance:\n  Flat: "..flatdist.."\n  Total: "..totaldist)

print("Max Travel Dist: ")
maxdist = tonumber(io.read())

newX = currX
newY = currY
newZ = currZ

wait1 = false

while true do
    term.clear()
    term.setCursorPos(1,1)

    if wait1 == false then
        newdist1 = tarX-newX
        newdist2 = tarY-newY
        newdist3 = tarZ-newZ

        if newdist1 < maxdist and newdist1 > -maxdist then
            newX = newX + newdist1
        else
            if newdist1 > 0 then
                newX = newX + maxdist
            else
                newX = newX - maxdist
            end
        end

        if newdist2 < maxdist and newdist2 > -maxdist then
            newY = newY + newdist2
        else
            if newdist2 > 0 then
                newY = newY + maxdist
            else
                newY = newY - maxdist
            end
        end

        if newdist3 < maxdist and newdist3 > -maxdist then
            newZ = newZ + newdist3
        else
            if newdist1 > 0 then
                newZ = newZ + maxdist
            else
                newZ = newZ - maxdist
            end
        end
    else
        wait1 = false
    end

    print("Coords to Enter:")
    term.setTextColor(0x4000)
    term.write("X"..newX)
    term.setTextColor(0x20)
    term.write(" Y"..newY)
    term.setTextColor(0x800)
    term.write(" Z"..newZ)
    term.setTextColor(0x1)
    print("\n")
    chat("Coords to Enter: X"..newX.." Y"..newY.." Z"..newZ)

    print("Target Coords:")
    term.setTextColor(0x4000)
    term.write("X"..tarX)
    term.setTextColor(0x20)
    term.write(" Y"..tarY)
    term.setTextColor(0x800)
    term.write(" Z"..tarZ)
    term.setTextColor(0x1)
    print("\n")

    print("Distance Left:")
    print("  Flat: "..onlypos(newdist1+newdist3))
    print("  Total: "..onlypos(newdist1+newdist2+newdist3))
    print("Press ENTER to continue..\n(or write \"repeat\" to send in chat again)")
    res1 = io.read()
    if res1 == "repeat" then
        wait1 = true
    end
    if newX == tarX and newY == tarY and newZ == tarZ then
        print("Destination Reached!")
        chat("Destination Reached!")
        break
    end
end

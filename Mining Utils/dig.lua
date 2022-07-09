term.clear()
term.setCursorPos(1,1)
sp = peripheral.find("speaker")
local args = {...}

if args[1] == "once" then
  turtle.dig()
  return
end

local function dig()
  return turtle.dig()
end
local function forward()
  return turtle.forward()
end
local function back()
  return turtle.back()
end
local function turn(t)
  if t == "right" then
    return turtle.turnRight()
  end
  if t == "left" then
    return turtle.turnLeft()
  end
end

local function play(s,v,p)
  if sp ~= nil then
    sp.playSound(s,v,p)
    return true
  else
    return false
  end
end

local function clear()
  term.clear()
  term.setCursorPos(1,1)
end

print("Remaining Fuel: "..turtle.getFuelLevel())

print("Length:")
local t_l = tonumber(io.read())
clear()
print("Height(1-3):")
local t_h = tonumber(io.read())
clear()
print("Width(1-3):")
local t_w = tonumber(io.read())
clear()
print("Come Back after finished?(y/n)")
local t_return = string.lower(io.read())
clear()
if t_return == "y" then
  t_return = true
else
  t_return = false
end

if t_w == 1 and t_h < 3 then
  print("Bridge Gaps?(y/n) (ONLY 1x1 or 1x2 size!)")
  t_bridge = string.lower(io.read())
  clear()
  if t_bridge == "y" then
    t_bridge = true
  else
    t_bridge = false
  end
  print("Optimized Mining?(y/n) (ONLY 1x1 or 1x2 size!)")
  t_opti = string.lower(io.read())
  clear()
  if t_opti == "y" then
    t_opti = true
    print("--Optimized Mining Settings--")
    print("Distance between branches:")
    t_opti_distance = tonumber(io.read())
    print("Branch Length:")
    t_opti_length = tonumber(io.read())
    clear()
  else
    t_opti = false
  end
else
  t_bridge = false
  t_opti = false
end

function drawUI()
  clear()
  print("Starting..")
  print("Size: H"..t_h.." W"..t_w)
  print("Return: "..tostring(t_return))
  print("Bridge: "..tostring(t_bridge))
  print("Optimized: "..tostring(t_opti))
  if t_opti then
    print("  Distance: "..t_opti_distance)
    print("  Length: "..t_opti_length)
  end
  print("\n")
  print("Distance Mined: "..digLength)
end

play("minecraft:entity.experience_orb.pickup",1,0.75)

digLength = 0
no_fuel = false

optiCount = 0

if t_h == 3 then
  turtle.up()
  turtle.dig()
  turtle.forward()
end

for i1=1, t_l do
  if t_w > 1 and t_h ~= 3 then
    turn("right")
    dig()
    if t_h == 2 then
      forward()
      turtle.digUp()
      turtle.back()
    end
    turn("left")
    if t_w > 2 then
      turn("left")
      dig()
      if t_h == 2 then
        forward()
        turtle.digUp()
        turtle.back()
      end
      turn("right")
    end
  end
  if t_h == 2 then
    turtle.digUp()
  elseif t_h == 3 then
    turtle.digUp()
    turtle.digDown()
    if t_w >= 2 then
      turn("right")
      dig()
      forward()
      turtle.digUp()
      turtle.digDown()
      back()
      if t_w == 3 then
        turn("left")
        turn("left")
        dig()
        forward()
        turtle.digUp()
        turtle.digDown()
        back()
        turn("right")
      else
        turn("left")
      end
    end
  end
  fuelLevel = turtle.getFuelLevel()
  digLength = digLength+1
  if fuelLevel <= digLength+6 then
    t_return = true
    no_fuel = true
    break
  end
  if optiCount >= t_opti_distance+1 then
    turn("right")
    for i1=1, t_opti_length do
      dig()
      forward()
      turtle.digUp()
    end
    turn("left")
    turn("left")
    for i1=1, t_opti_length do
      forward()
    end
    for i1=1, t_opti_length do
      dig()
      forward()
      turtle.digUp()
    end
    for i1=1, t_opti_length do
      back()
    end
    turn("right")
    optiCount = 0
  end
  dig()
  turtle.forward()
  optiCount = optiCount+1
  if t_bridge == true then
    blockDown, blockInfo = turtle.inspectDown()
    if blockDown then
      blockName = blockInfo["name"]
    end
    if blockDown == false or blockName == "minecraft:water" or blockName == "minecraft:lava" then
      if turtle.getItemCount() == 0 then
        for i1=1,16 do
          turtle.select(i1)
          if turtle.getItemCount() > 0 then
            break
          end
        end
      end
      turtle.placeDown()
    end
  end
end
if t_return then
  turn("left")
  turn("left")
  if no_fuel then
    for i1=1, digLength-1 do
      forward()
    end
  else
    for i1=1, t_l do
      forward()
    end
  end
  turn("left")
  turn("left")
  if t_h == 3 then
    back()
    turtle.down()
  end
end
play("minecraft:entity.player.levelup",1,0.75)
if no_fuel then
  play("minecraft:block.beacon.deactivate",1,1.5)
end

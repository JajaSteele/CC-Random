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

print("Remaining Fuel: "..turtle.getFuelLevel())

print("Length:")
local t_l = tonumber(io.read())
print("Height(1-3):")
local t_h = tonumber(io.read())
print("Width(1-3):")
local t_w = tonumber(io.read())
print("Come Back after finished?(y/n)")
local t_return = string.lower(io.read())
if t_return == "y" then
  t_return = true
else
  t_return = false
end

play("minecraft:entity.experience_orb.pickup",1,0.75)

digLength = 0
no_fuel = false

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
  dig()
  turtle.forward()
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

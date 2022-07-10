
args = {...}
widthCount = 0

while true do
  local upCount = 0
  local hasStarted = false
  while true do
    local stat, block = turtle.inspect()
    if (stat == true and block["tags"]["minecraft:logs"] == true) or (hasStarted == false and upCount < 2) then
      print(hasStarted,upCount)
      turtle.dig()
      turtle.digUp()
      turtle.up()
      upCount = upCount+1
      if (stat == true and block["tags"]["minecraft:logs"] == true) then
        hasStarted = true
      end
    else
      break
    end
  end
  if args[1] ~= "big" then
    for i1=1, 16 do
      turtle.select(i1)
      if turtle.getItemCount() > 0 then
        turtle.dropDown()
      end
    end
  end
  for i1=1, upCount do
    turtle.down()
  end
  if args[1] == "big" then
    widthCount = widthCount+1
    if widthCount == 1 then
      turtle.turnRight()
      turtle.dig()
      turtle.forward()
      turtle.turnLeft()
    end
    if widthCount == 2 then
      turtle.forward()
    end
    if widthCount == 3 then
      turtle.turnLeft()
      turtle.dig()
      turtle.forward()
      turtle.turnRight()
    end
    if widthCount == 4 then break end
  else
    break
  end
end

if args[1] == "big" then
  for i1=1, 16 do
    turtle.select(i1)
    if turtle.getItemCount() > 0 then
      turtle.drop()
    end
  end
end

function mineCane()
  turtle.dig()
  turtle.forward()
  turtle.digDown()
end

while true do
  if turtle.inspect() then
    for i1=1, 16 do
      mineCane()
    end
    turtle.turnRight()
    mineCane()
    turtle.turnRight()
    for i1=1, 15 do
      mineCane()
    end
    turtle.turnLeft()
    turtle.forward()
    mineCane()
    turtle.turnLeft()
    for i1=1, 15 do
      mineCane()
    end
    turtle.turnRight()
    mineCane()
    turtle.turnRight()
    for i1=1, 15 do
      mineCane()
    end
    turtle.forward()
    turtle.turnRight()
    for i1=1, 4 do
      turtle.forward()
    end
    turtle.turnRight()
    for i1=1, 16 do
      turtle.select(i1)
      turtle.dropDown()
    end
  end
  os.sleep(2)
end

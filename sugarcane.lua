function mineCane()
  turtle.dig()
  turtle.forward()
  turtle.digDown()
end

waiting = true

while true do
  if waiting then
    print("Waiting for Sugarcane..")
    waiting = false
  end
  if turtle.inspect() then
    if turtle.getFuelLevel() >= 64 then
      print("Starting!")
      for i1=1, 16 do
        mineCane()
      end
      print("Row n°1 done.")
      turtle.turnRight()
      mineCane()
      turtle.turnRight()
      for i1=1, 15 do
        mineCane()
      end
      print("Row n°2 done.")
      turtle.turnLeft()
      turtle.forward()
      mineCane()
      turtle.turnLeft()
      for i1=1, 15 do
        mineCane()
      end
      print("Row n°3 done.")
      turtle.turnRight()
      mineCane()
      turtle.turnRight()
      for i1=1, 15 do
        mineCane()
      end
      print("Row n°4 done.\nReturning to Home.")
      turtle.forward()
      turtle.turnRight()
      for i1=1, 4 do
        turtle.forward()
      end
      turtle.turnRight()
      print("Dropping All..")
      for i1=1, 16 do
        turtle.select(i1)
        turtle.dropDown()
      end
      waiting = true
    else
      print("Warning! No Fuel!")
    end
  end
  os.sleep(2)
end

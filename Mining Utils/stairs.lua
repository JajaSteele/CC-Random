
args = {...}

local currPath = shell.getRunningProgram()

local completion = require "cc.shell.completion"
local complete = completion.build(
  { completion.choice, { "down", "up" } },
  { completion.choice, { "clockwise", "inverted" } },
  { completion.choice, {"Depth(NUMBER)"}}
)
shell.setCompletionFunction(currPath, complete)

if args[1] == nil then
  print("Auto-Completion loaded!")
end

function dig(w)
  if w == nil then
    turtle.dig()
  elseif w == "up" then
    turtle.digUp() else turtle.digDown()
  end
end

function r(a,b)
  if b ~= nil then
    for i1=1, a do
      turtle[b]()
    end
  else
    turtle[a]()
  end
end

function place(d)
  if turtle.getItemCount() == 0 then
    for i2=1, 16 do
      turtle.select(i2)
      if turtle.getItemCount() > 0 then
        break
      end
    end
  end
  if d ~= nil then
    if (turtle.inspectDown() == false and d == "down") or (turtle.inspectUp() == false and d == "up") then
      if d == "down" then turtle.placeDown() elseif d == "up" then turtle.placeUp() end
    end
  else
    if turtle.inspect() == false then
      turtle.place()
      print("place")
    end
  end
end



if args[1] == "down" and args[2] == "clockwise" and args[3] ~= nil then -- Clockwise and Down
  for i1=1, tonumber(args[3]) do
    dig()
    r("forward")
    dig("down")
    dig("up")
    r("down")
    place("down")
    r("turnRight")
  end
  r("turnLeft")
  r("up")
  r("back")
end

if args[1] == "down" and args[2] == "inverted" and args[3] ~= nil then -- Anti-Clockwise and Down
  for i1=1, tonumber(args[3]) do
    dig()
    r("forward")
    dig("down")
    dig("up")
    r("down")
    place("down")
    r("turnLeft")
  end
  r("turnRight")
  r("up")
  r("back")
end

if args[1] == "up" and args[2] == "clockwise" and args[3] ~= nil then -- Clockwise and Up
  place("up")
  r("turnRight")
  place()
  r("turnLeft")
  for i1=1, tonumber(args[3]) do
    dig()
    r("forward")
    dig("up")
    dig("down")
    r("up")
    place("up")
    r("turnRight")
  end
  r("turnLeft")
  r("down")
  r("back")
end

if args[1] == "up" and args[2] == "inverted" and args[3] ~= nil then -- Anti-Clockwise and Up
  place("up")
  r("turnLeft")
  place()
  r("turnRight")
  for i1=1, tonumber(args[3]) do
    dig()
    r("forward")
    dig("up")
    dig("down")
    r("up")
    place("up")
    r("turnLeft")
  end
  r("turnRight")
  r("down")
  r("back")
end

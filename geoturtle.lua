geo = peripheral.find("geoScanner")

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function check(t,l)
  res = false
  for k,v in pairs(l) do
    if t == v then
      res = true
      break
    end
  end
  return res
end

function sbc(c)
  term.setBackgroundColor(c)
end

function sfc(c)
  term.setTextColor(c)
end

function w(t)
  term.write(t)
end

mx,my = term.getSize()

term.clear()
term.setCursorPos(1,1)

s_chunk = false

maxRange = geo.getConfiguration().scanBlocks.maxCostRadius

if not s_chunk then
  print("Range? (0-"..maxRange..")")
  s_range = tonumber(io.read())
  print("Show Relative Coords? (y/n)")
  s_coords = io.read():lower()
  if s_coords == "y" then
    s_coords = true
  else
    s_coords = false
  end

  print("Show Distance? (y/n)")
  s_dist = io.read():lower()
  if s_dist == "y" then
    s_dist = true
  else
    s_dist = false
  end
end

print("Filter? (y/n)")
s_filter = io.read():lower()
if s_filter == "y" then
  s_filter = true
  print("Enter your filter: (block id without namespace, separated by commas.)")
  s_filter_list = split(io.read(),",")
else
  s_filter = false
end



if not s_chunk then
  print("Scanning..")
  os.sleep(1)
  term.setCursorPos(1,1)
  newData, reason = geo.scan(s_range)
  term.clear()
  if newData ~= nil then
    for k,v in pairs(newData) do
      name = split(v["name"],":")[2]
      if s_filter and check(name,s_filter_list) then
        print(name)
        if s_coords then
          sfc(colors.red) w(" x: "..v["x"])
          sfc(colors.lime) w(" y: "..v["y"])
          sfc(colors.blue) w(" z: "..v["z"])
          sfc(colors.white)
        end
        if s_dist then
          distance = math.abs(v["x"])+math.abs(v["y"]),math.abs(v["z"])
          sfc(colors.yellow) w(" D: "..distance)
          sfc(colors.white)
        end
      elseif not s_filter then
        print(name)
        if s_coords then
          sfc(colors.red) w(" x: "..v["x"])
          sfc(colors.lime) w(" y: "..v["y"])
          sfc(colors.blue) w(" z: "..v["z"])
          sfc(colors.white)
        end
        if s_dist then
          distance = math.abs(v["x"])+math.abs(v["y"]),math.abs(v["z"])
          sfc(colors.yellow) w(" D: "..distance)
          sfc(colors.white)
        end
      end
    end
  else
    print("ERROR: "..reason)
  end
  term.setCursorPos(1,my-3)
  print("Cooldown: "..(geo.getOperationCooldown("scanBlocks")/1000).."s\nFuel Remaining: "..turtle.getFuelLevel())
  os.sleep(geo.getOperationCooldown("scanBlocks")/1000)
else
  print("Error, no CHUNK SCAN available.")
end
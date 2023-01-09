geo = peripheral.find("geoScanner")

function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function check(t,l)
  local res = false
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

function clear(y1,y2)
  for i1=1, y2-(y1-1) do
    term.setCursorPos(1,(y1-1)+i1)
    term.clearLine()
  end
end

mx,my = term.getSize()

term.clear()
term.setCursorPos(1,1)

print("Chunk Scan Mode? (y/n)")
s_chunk = io.read():lower()
if s_chunk == "y" then
  s_chunk = true
else
  s_chunk = false
end

maxRange = geo.getConfiguration().scanBlocks.maxFreeRadius

if not s_chunk then
  print("Range? (0-"..maxRange..")")
  s_range = tonumber(io.read())
  print("Show Relative Coords? (y/n)")
  s_coords = io.read():lower()
  if s_coords == "y" then
    s_coords = true
    print("Show N/S/W/E instead of XYZ? (y/n)")
    s_coords_compass = io.read():lower()
    if s_coords_compass == "y" then
      s_coords_compass = true
    else
      s_coords_compass = false
    end
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

print("Show Name? (y/n)")
s_showname = io.read():lower()
if s_showname == "y" then
  s_showname = true
else
  s_showname = false
end

function sort_dist(a,b)
  return a.dist < b.dist
end


function main()
  if not s_chunk then
    while true do
      term.setCursorPos(1,1)
      newData = geo.scan(s_range)
      for k,v in pairs(newData) do
        newData[k].dist = math.abs(v["x"])+math.abs(v["y"]),math.abs(v["z"])
      end
      table.sort(newData,sort_dist)
      if s_filter then
        clear(2,my)
        term.setCursorPos(1,2)
      else
        term.clear()
      end
      if newData ~= nil then
        for k,v in pairs(newData) do
          name = split(v["name"],":")[2]
          if s_filter and check(name,s_filter_list) then
            if s_showname then
              print(name)
            else
              print("")
            end
            if s_coords then
              if not s_coords_compass then
                sfc(colors.red) w(" x: "..v["x"])
                sfc(colors.lime) w(" y: "..v["y"])
                sfc(colors.blue) w(" z: "..v["z"])
              else
                if v.x >= 0 then
                  sfc(colors.red) w(" E: "..math.abs(v["x"]))
                else
                  sfc(colors.red) w(" W: "..math.abs(v["x"]))
                end
                if v.y >= 0 then
                  sfc(colors.lime) w(" UP: "..math.abs(v["y"]))
                else
                  sfc(colors.lime) w(" DOWN: "..math.abs(v["y"]))
                end
                if v.z >= 0 then
                  sfc(colors.blue) w(" S: "..math.abs(v["z"]))
                else
                  sfc(colors.blue) w(" N: "..math.abs(v["z"]))
                end
              end

              sfc(colors.white)
            end
            if s_dist then
              
              sfc(colors.yellow) w(" D: "..v.dist)
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

              sfc(colors.yellow) w(" D: "..v.dist)
              sfc(colors.white)
            end
          end
        end
      end
      term.setCursorPos(1,my)
      term.write("Cooldown: "..(geo.getOperationCooldown("scanBlocks")/1000).."s")
      os.sleep(geo.getOperationCooldown("scanBlocks")/1000)
    end
  else
    while true do
      term.setCursorPos(1,1)
      newData = geo.chunkAnalyze()
      term.clear()
      if newData ~= nil then
        for k,v in pairs(newData) do
          name = split(k,":")[2]
          if s_filter and check(name,s_filter_list) then
            print(v.."x "..name)
          elseif not s_filter then
            print(v.."x "..name)
          end
        end
      end
      os.sleep(2.5)
    end
  end
end

function filter_display()
  local position = 1
  while true do
    local oldX,oldY = term.getCursorPos()
    term.setCursorPos(1,1)
    term.clearLine()
    term.write(position..". "..s_filter_list[position])
    term.setCursorPos(oldX,oldY)
    os.sleep(1)
    position = position+1
    if position > #s_filter_list then
      position = 1
    end
  end
end

parallel.waitForAny(main,filter_display)

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

if not s_chunk then
  print("Range? (0-8)")
  s_range = tonumber(io.read())
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
  while true do
    term.setCursorPos(1,1)
    newData = geo.scan(s_range)
    term.clear()
    if newData ~= nil then
      for k,v in pairs(newData) do
        name = split(v["name"],":")[2]
        if s_filter and check(name,s_filter_list) then
          print(name)
        elseif not s_filter then
          print(name)
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
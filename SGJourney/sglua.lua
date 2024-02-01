local basic = "a = peripheral.find('basic_interface')"
local crystal = "b = peripheral.find('crystal_interface')"
local advanced = "c = peripheral.find('advanced_crystal_interface')"

local basic_stat = ""
if not peripheral.find("basic_interface") then
    basic_stat = " (Missing)"
end

local crystal_stat = ""
if not peripheral.find("crystal_interface") then
    crystal_stat = " (Missing)"
end

local advanced_stat = ""
if not peripheral.find("advanced_crystal_interface") then
    advanced_stat = " (Missing)"
end

local clear = "term.clear() term.setCursorPos(1,1) print('a = basic "..basic_stat.."\\nb = crystal "..crystal_stat.."\\nc = advanced "..advanced_stat.."')"

term.clear()
term.setCursorPos(1,1)

for i1=1, #basic do
    local char = basic:sub(i1,i1)
    os.queueEvent("char", char)
end
os.queueEvent("key", keys.enter, false)

for i1=1, #crystal do
    local char = crystal:sub(i1,i1)
    os.queueEvent("char", char)
end
os.queueEvent("key", keys.enter, false)

for i1=1, #advanced do
    local char = advanced:sub(i1,i1)
    os.queueEvent("char", char)
end
os.queueEvent("key", keys.enter, false)

for i1=1, #clear do
    local char = clear:sub(i1,i1)
    os.queueEvent("char", char)
end
os.queueEvent("key", keys.enter, false)

shell.execute("lua")
turtle.select(1)
turtle.place()
turtle.back()
turtle.select(2)
turtle.place()

sleep(0.5)

local t = peripheral.wrap("front")
if not t then
    repeat
        t = peripheral.wrap("front")
    until t ~= nil
end

local curr_x, curr_y, curr_z = gps.locate()

term.clear()
term.setCursorPos(1,1)

local found_list = {}

for x=1, 16 do
    for z=1, 16 do
        for k,v in pairs(t.getColumnAt(x-1,z-1)) do
            if v.block:match("inject") then
                print("Found: ",x-1,z-1,v.block)
                found_list[#found_list+1] = {
                    block = v.block,
                    pos = {
                        x=(curr_x+(x-1)),
                        y=(curr_y),
                        z=((curr_z)-(z-1))
                    }
                }
            end
        end
    end
end

local print_list = {}

for k,v in ipairs(found_list) do
    print_list[k] = string.format('[name:"%s", x:%d, y:%d, z:%d]', v.block, v.pos.x, v.pos.y, v.pos.z)
end

peripheral.find("chatBox").sendMessage("Found:\n  "..table.concat(print_list, "\n  "))
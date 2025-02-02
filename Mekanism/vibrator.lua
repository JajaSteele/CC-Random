local completion = require("cc.completion")

local last_id = ""
local file = io.open("/.vibrator_last.txt", "r")
if file then
    last_id = file:read("*a")
    file:close()
end

local function fill(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            term.setCursorPos(x+i1-1,y+i2-1)
            term.write(char or " ")
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char, target)

    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                term.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    term.write()
                else
                    term.write(char or " ")
                end
            end
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function write(x,y,text,bg,fg, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_posx,old_posy = term.getCursorPos()
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()

    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    term.setCursorPos(x,y)
    term.write(text)

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local vibe = peripheral.find("seismicVibrator")
print("Enter block ID:")
local new_id = read(nil, nil, function(text) return completion.choice(text, {last_id}) end, last_id)

local file2 = io.open("/.vibrator_last.txt", "w")
file2:write(new_id)
file2:close()

local width, height = term.getSize()

term.clear()
term.setCursorPos(1,1)
print("Scanning Chunk..")

write(1,2, "[")
write(width,2, "]")

local found_list = {}
local function_map = {}

local progress = 0
local max = 16*16
for x=0, 15 do
    for z=0, 15 do
        function_map[#function_map+1] = function ()
            local data = vibe.getColumnAt(x,z)
            for k,block in pairs(data) do
                if block.block == new_id then
                    found_list[#found_list+1] = {
                        x=x, y=k, z=z, block=block.block
                    }
                end
            end
            progress = progress+1
            fill(2,2,1+((width-2)*(progress/max)), 2, colors.black, colors.red, "#")
        end
    end
end

parallel.waitForAll(table.unpack(function_map))
sleep(0.1)

term.setCursorPos(1,3)

print("Found "..#found_list.." matching blocks!")
sleep(0.5)
term.clear()
term.setCursorPos(1,1)
for i1=1, height-2 do
    local data = found_list[i1]
    if data then
        print(data.x, data.y, data.z)
    else
        print("")
    end
end

print("Click to exit")
os.pullEvent("mouse_click")
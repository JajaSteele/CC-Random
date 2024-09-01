local monitor = peripheral.find("monitor")
if monitor then
    
else
    error("No monitor found")
end

local optimal_scale = 5
local example_text = " 1 2 3 "
local min_height = 5
repeat
    monitor.setTextScale(optimal_scale)
    local mx, my = monitor.getSize()
    if mx >= #example_text and my >=min_height then
        break
    else
        optimal_scale = optimal_scale-0.5
    end
until optimal_scale == 0.5

monitor.setTextScale(optimal_scale)

local config = {}

local function loadConfig()
    if fs.exists("code_config.txt") then
        local file = io.open("saved_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    else
        print("Enter Code")
    end
end
local function writeConfig()
    local file = io.open("code_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()

config.code = config.code or nil

local function fill(x,y,x1,y1,bg,fg,char)
    local old_bg = monitor.getBackgroundColor()
    local old_fg = monitor.getTextColor()
    local old_posx,old_posy = monitor.getCursorPos()
    if bg then
        monitor.setBackgroundColor(bg)
    end
    if fg then
        monitor.setTextColor(fg)
    end
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            monitor.setCursorPos(x+i1-1,y+i2-1)
            monitor.write(char or " ")
        end
    end
    monitor.setTextColor(old_fg)
    monitor.setBackgroundColor(old_bg)
    monitor.setCursorPos(old_posx,old_posy)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char)
    local old_bg = monitor.getBackgroundColor()
    local old_fg = monitor.getTextColor()
    local old_posx,old_posy = monitor.getCursorPos()
    if bg then
        monitor.setBackgroundColor(bg)
    end
    if fg then
        monitor.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                monitor.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    monitor.write()
                else
                    monitor.write(char or " ")
                end
            end
        end
    end
    monitor.setTextColor(old_fg)
    monitor.setBackgroundColor(old_bg)
    monitor.setCursorPos(old_posx,old_posy)
end

local function write(x,y,text,bg,fg)
    local old_posx,old_posy = monitor.getCursorPos()
    local old_bg = monitor.getBackgroundColor()
    local old_fg = monitor.getTextColor()

    if bg then
        monitor.setBackgroundColor(bg)
    end
    if fg then
        monitor.setTextColor(fg)
    end

    monitor.setCursorPos(x,y)
    monitor.write(text)

    monitor.setTextColor(old_fg)
    monitor.setBackgroundColor(old_bg)
    monitor.setCursorPos(old_posx,old_posy)
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local max_length = 7
local input_code = ""

local function addChar(char)
    print(char, #input_code.." < "..max_length)
    if #input_code < max_length then
        input_code = input_code .. char
    end
end

local button_table = {
}


local function regButton(x,y, func)
    button_table[#button_table+1] = {x=x, y=y, func=func}
end

local function findPressedButton(x,y)
    for k,v in pairs(button_table) do
        if x == v.x and y == v.y then
            return v
        end
    end
end

local w,h = monitor.getSize()

local function drawThread()
    while true do
        fill(1, 1, w, 1, colors.black, colors.white, " ")
        if #input_code < 1 then
            write(2,1, " PIN ", colors.black, colors.lightGray)
        else
            write(1,1, string.rep("*", #input_code), colors.black, colors.yellow)
        end
        write(2,2, "1 2 3", colors.black, colors.white)
        write(2,3, "4 5 6", colors.black, colors.white)
        write(2,4, "7 8 9", colors.black, colors.white)
        write(2,5, "X 0 V", colors.black, colors.white)

        write(2,5, "X", colors.black, colors.red)

        write(6,5, "V", colors.black, colors.green)
        os.pullEvent("redraw_keypad")
    end
end

local function checkCode()
    
end

regButton(2,2, function() addChar("1") end) regButton(4,2, function() addChar("2") end) regButton(6,2, function() addChar("3") end)
regButton(2,3, function() addChar("4") end) regButton(4,3, function() addChar("5") end) regButton(6,3, function() addChar("6") end)
regButton(2,4, function() addChar("7") end) regButton(4,4, function() addChar("8") end) regButton(6,4, function() addChar("9") end)
regButton(2,5, function() input_code = "" end) regButton(4,5, function() addChar("0") end) regButton(6,5, function()  end)

local function clickThread()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local button = findPressedButton(x,y)
        if button and button.func then
            button.func()
        end
        os.queueEvent("redraw_keypad")
    end
end

parallel.waitForAll(drawThread, clickThread)
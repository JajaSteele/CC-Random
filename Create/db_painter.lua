local dp = peripheral.find("Create_DisplayLink")
local monitor = peripheral.find("monitor")

local dp_height, dp_width = dp.getSize()

local args = {...}

local display_spacing = 1.5

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

local function drawLine(x1, y1, x2, y2, char)
    local startX = math.floor(x1)
    local startY = math.floor(y1)
    local endX = math.floor(x2)
    local endY = math.floor(y2)

    if startX == endX and startY == endY then
        write(startX, startY , char, colors.black, colors.white)
        dp.setCursorPos(clamp((startX*display_spacing)-2, 1, dp_width) ,clamp(startY-1, 1, dp_height))
        dp.write(char)
        return
    end
    
    local minX = math.min( startX, endX )
    local maxX, minY, maxY
    if minX == startX then
        minY = startY
        maxX = endX
        maxY = endY
    else
        minY = endY
        maxX = startX
        maxY = startY
    end

    -- TODO: clip to screen rectangle?
        
    local xDiff = maxX - minX
    local yDiff = maxY - minY
            
    if xDiff > math.abs(yDiff) then
        local y = minY
        local dy = yDiff / xDiff
        for x=minX,maxX do
            write(x, math.floor( y + 0.5 ) , char, colors.black, colors.white)
            dp.setCursorPos(clamp((x*display_spacing)-2, 1, dp_width) ,clamp(y-1, 1, dp_height))
            dp.write(char)
            y = y + dy
        end
    else
        local x = minX
        local dx = xDiff / yDiff
        if maxY >= minY then
            for y=minY,maxY do
                write(math.floor( x + 0.5 ), y , char, colors.black, colors.white)
                dp.setCursorPos(clamp((x*display_spacing)-2, 1, dp_width) ,clamp(y-1, 1, dp_height))
                dp.write(char)
                x = x + dx
            end
        else
            for y=minY,maxY,-1 do
                write(math.floor( x + 0.5 ), y , char, colors.black, colors.white)
                dp.setCursorPos(clamp((x*display_spacing)-2, 1, dp_width) ,clamp(y-1, 1, dp_height))
                dp.write(char)
                x = x - dx
            end
        end
    end
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local symmetry_x = 0

local mode = 0

local mode_list

mode_list = {
    {
        symbol="P",
        func=function(x,y)
            write(x,y, "#", colors.black, colors.white)
            dp.setCursorPos((x*display_spacing)-2 ,y-1)
            dp.write("#")
            dp.update()
        end
    },
    {
        symbol="D",
        func=function(x,y)
            write(x,y, "\x07", colors.black, colors.gray)
            dp.setCursorPos((x*display_spacing)-2 ,y-1)
            dp.write(" ")
            dp.update()
        end
    },
    {
        symbol="L",
        func=function(x,y)
            write(x,y, "\x04", colors.black, colors.lime)
            local event, side, x2, y2 = os.pullEvent("monitor_touch")
            drawLine(x,y, x2, y2, "#")

            if symmetry_x ~= 0 then
                local dist_from_line = x-symmetry_x
                local dist_from_line2 = x2-symmetry_x
                drawLine(symmetry_x-dist_from_line, y, symmetry_x-dist_from_line2, y2, "#")
            end

            dp.update()
        end
    },
    {
        symbol="S",
        func=function(x,y)
            if x == symmetry_x then
                symmetry_x = 0
                write(x, dp_height+3, " ", colors.black, colors.orange)
            else
                write(symmetry_x, dp_height+3, " ", colors.black, colors.orange)
                symmetry_x = x
                write(x, dp_height+3, "|", colors.black, colors.orange)
            end
        end
    }
}

local buttons = {
    {
        symbol="C",
        func=function(x,y)
            --dp.clear()
            --monitor.clear()
            --monitor.setTextScale(0.5)
            --monitor.setCursorPos(1,1)
            --fill(1,1, (dp_width/display_spacing)+2, dp_height+2, colors.black, colors.gray, "\x07")
            --rect(1,1, (dp_width/display_spacing)+2, dp_height+2, colors.black, colors.red, "\x7F")
            --dp.update()

            for y=1, dp_height do
                fill(2, (y+2)-1, (dp_width/display_spacing)+1, (y+2)-1, colors.black, colors.gray, "\x07")
                dp.setCursorPos(1, y)
                dp.clearLine()
                dp.update()
            end
        end
    },
}

monitor.setPaletteColor(colors.gray, 0x151515)


local function monitorTouch()
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setCursorPos(1,1)
    dp.clear()
    dp.update()
    fill(1,1, (dp_width/display_spacing)+2, dp_height+2, colors.black, colors.gray, "\x07")
    rect(1,1, (dp_width/display_spacing)+2, dp_height+2, colors.black, colors.red, "\x7F")
    while true do
        for k,v in ipairs(mode_list) do
            if mode == k then
                write(1+k, 1, v.symbol, colors.white, colors.black)
            else
                write(1+k, 1, v.symbol, colors.black, colors.white)
            end
        end
        for k,v in ipairs(buttons) do
            write(1+k, dp_height+2, v.symbol, colors.black, colors.white)
        end
        local event, side, x, y = os.pullEvent("monitor_touch")
        if x > 1 and y > 1 and x < (dp_width/display_spacing)+2 and y < dp_height+2 then
            if mode_list[mode] then
                local stat, err = pcall(mode_list[mode].func, x, y)
                if not stat then
                    print(err)
                end
                if (mode_list[mode].symbol ~= "S" and mode_list[mode].symbol ~= "L") and symmetry_x ~= 0 then
                    local dist_from_line = x-symmetry_x
                    local stat, err = pcall(mode_list[mode].func, symmetry_x-dist_from_line, y)
                    if not stat then
                        print(err)
                    end
                end
            else
                print("Unknown Mode: "..mode)
            end
        elseif y == 1 and x > 1 then
            local new_mode = mode_list[x-1]
            print("Setting mode to "..x-1)
            if new_mode then
                mode = x-1
                print("Success!")
            end
        elseif y == dp_height+2 and x > 1 then
            local action = buttons[x-1]
            print("Setting mode to "..x-1)
            if action then
                local stat, err = pcall(action.func, x, y)
                if not stat then
                    print(err)
                end
                print("Success!")
            end
        end
    end
end

parallel.waitForAny(monitorTouch)
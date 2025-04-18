local bridge = peripheral.find("meBridge")

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

local function disp_time(time)
    local days = math.floor(time/86400)
    local hours = math.floor((time % 86400)/3600)
    local minutes = math.floor((time % 3600)/60)
    local seconds = math.floor((time % 60))
    return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
end

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)

local mon_win = window.create(monitor, 1,1, monitor.getSize())
local test_table = {}
for i1=1, 16 do
    test_table[#test_table+1] = {}
end

local width,height = mon_win.getSize()
local display_count = width/4

while true do
    local last_x = 2
    mon_win.setVisible(false)
    mon_win.clear()
    local cpu_data = bridge.getCraftingCPUs() or {}
    for i1=1, display_count do
        local x = last_x
        local cpu = cpu_data[i1]
        if cpu then
            if cpu.isBusy then
                if cpu.craftingJob then
                    local job = cpu.craftingJob
                    local progress = clamp(job.progress/job.totalItem, 0, 1)
                    if progress == 1 then
                        write(x, 1, i1, colors.black, colors.green, mon_win)
                        write(x, height, string.format("%.0f", progress*100), colors.black, colors.green, mon_win)
                    else
                        write(x, 1, i1, colors.black, colors.orange, mon_win)
                        write(x, height, string.format("%.0f", progress*100), colors.black, colors.orange, mon_win)
                    end
                    fill(x,3, x+2, height-2, colors.black, colors.red, "\x7F", mon_win)
                    fill(x,3, x+2, (height-2)*progress, colors.green, colors.gray, "\x7F", mon_win)
                else
                    write(x, 1, i1, colors.black, colors.yellow, mon_win)
                    write(x, height, "BSY", colors.black, colors.yellow, mon_win)
                    fill(x,3, x+2, height-2, colors.black, colors.orange, "\x7F", mon_win)
                end
            else
                write(x, 1, i1, colors.black, colors.white, mon_win)
                write(x, height, "RDY", colors.black, colors.white, mon_win)
                fill(x,3, x+2, height-2, colors.black, colors.white, "\x7F", mon_win)
            end
        else
            write(x, 1, i1, colors.black, colors.gray, mon_win)
            write(x, height, "---", colors.black, colors.gray, mon_win)
            fill(x,3, x+2, height-2, colors.black, colors.gray, "\x7F", mon_win)
        end
        last_x = x+4
    end
    mon_win.setVisible(true)
    sleep(0.125)
end
local monitor = peripheral.find("monitor")

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

local bill_list = {}
if not fs.exists("/bills") then
    print("Creating /bills directory..")
    fs.makeDir("/bills")
end

local temp_list = fs.list("/bills")

for k,v in pairs(temp_list) do
    local extension = v:match(".+%.(.+)")
    local name = v:match("(.+)%..+")

    if extension == "txt" then
        bill_list[#bill_list+1] = {
            filename = v,
            name = name
        }
    end
end

table.sort(bill_list, function (a,b)
    return a.name < b.name
end)

local width, height = monitor.getSize()

local curr_bill = 1
local default_timer = 30
local next_timer = default_timer

local select_page = 1
local select_map = {}

local display_mode = "bill"

local function switchMode(mode)
    display_mode = mode
    os.queueEvent("redraw")
end

local drawThread = function()
    while true do
        os.pullEvent("redraw")
        monitor.clear()
        monitor.setTextColor(colors.white)
        if display_mode == "bill" then
            local bill_data = bill_list[curr_bill]
            local bill_io = io.open("/bills/"..bill_data.filename, "r")
            local bill_text
            if bill_io then
                write(1,1, "Tip: "..bill_data.name, colors.black, colors.yellow, monitor)
                bill_text = bill_io:read("*a")
                bill_io:close()
            else
                bill_text = ""
                write(1,1, "ERROR: Couldn't open "..bill_data.filename, colors.black, colors.red, monitor)
            end

            local color_mode = false
            local parsed_color = ""
            monitor.setCursorPos(2,3)
            for char in bill_text:gmatch(".") do
                if char == "\n" then
                    local currx,curry = monitor.getCursorPos()
                    monitor.setCursorPos(2,curry+1)
                elseif char == "&" then
                    color_mode = true
                elseif color_mode then
                    if char == " " then
                        color_mode = false
                        monitor.setTextColor(colors[parsed_color] or colors.white)
                        parsed_color = ""
                    else
                        parsed_color = parsed_color..char
                    end
                else
                    monitor.write(char)
                end
            end
            write(1,height-1, "R-Click monitor to explore other tips", colors.black, colors.gray, monitor)
        elseif display_mode == "select" then
            write(1,1, "All Tips: Page "..select_page, colors.black, colors.yellow, monitor)
            local entry_line = 2
            select_map = {}
            for i1=1, #bill_list do
                local bill_data = bill_list[i1]
                if entry_line > height-1 then   
                    break
                end
                if bill_data then
                    write(2,entry_line, bill_data.name, colors.black, colors.lightGray, monitor)
                    select_map[entry_line] = {data=bill_data, id=i1}
                    entry_line = entry_line+1
                end
            end
            write(1,height-1, "R-Click a tip to view it", colors.black, colors.gray, monitor)
        end
        fill(1,height,width,height, colors.black, colors.gray, "-", monitor)
        fill(1,height,(width*(next_timer/default_timer)),height, colors.black, colors.lightBlue, "-", monitor)
    end
end

local timerThread = function ()
    while true do
        next_timer = next_timer-1
        if next_timer <= 0 then
            switchMode("bill")
            next_timer = default_timer
            curr_bill = curr_bill+1
            if curr_bill > #bill_list then
                curr_bill = 1
            end
        end
        os.queueEvent("redraw")
        sleep(1)
    end
end

local inputThread = function()
    while true do
        local data = {os.pullEvent()}
        if data[1] == "monitor_touch" then
            next_timer = default_timer
            if display_mode == "bill" then
                switchMode("select")
            elseif display_mode == "select" then
                local _, mon, x, y = table.unpack(data)
                if select_map[y] then
                    local selected_bill = select_map[y]
                    curr_bill = selected_bill.id
                    switchMode("bill")
                end
            end
        end
    end
end

os.queueEvent("redraw")
parallel.waitForAll(drawThread, timerThread, inputThread)
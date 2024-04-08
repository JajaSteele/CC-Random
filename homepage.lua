local file_list = fs.list("/")

local function getFileType(filename)
    return filename:match(".+%.(%w+)")
end

local function getFileName(filename)
    return filename:match("(.+)%.%w+")
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local selected_program = ""
local run_threads = true
local selected_color = colors.blue

local function fill(x,y,x1,y1,bg,fg,char)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end
    for i2=1, (y1-y)+1 do
        term.setCursorPos(x,y+i2-1)
        term.write(string.rep(char or " ", (x1-x)+1))
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
end

local function write(x,y,text,bg,fg)
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
end

local program_list = {}
local function updateList()
    file_list = fs.list("/")
    program_list = {}
    for k,v in pairs(file_list) do
        if v ~= shell.getRunningProgram() and getFileType(fs.getName(v)) == "lua" then
            program_list[#program_list+1] = getFileName(fs.getName(v))
        end
    end
end

local width, height = term.getSize()

local scroll = 0

local function drawMenu()
    term.setBackgroundColor(colors.lightBlue)
    term.clear()
    os.queueEvent("redraw_list")
    while true do
        os.pullEvent("redraw_list")
        term.setCursorBlink(false)
        updateList()
        if run_threads then
            fill(1,1, width, 1, colors.lightGray, colors.white, " ")
            write(1,1, "Home page", colors.lightGray, colors.black)
            term.setBackgroundColor(colors.lightBlue)
            term.setCursorPos(1,1)
            for i1=1, height-1 do
                local file = program_list[i1+scroll] or ""
                term.setCursorPos(2, i1+1)
                term.clearLine()
                if file == selected_program then
                    term.setTextColor(selected_color)
                else
                    term.setTextColor(colors.black)
                end
                term.write(file)
            end
        end
    end
end

local function scrollInput()
    while true do
        local event, scroll_dir = os.pullEvent("mouse_scroll")
        if run_threads then
            scroll = math.ceil(clamp(scroll+(scroll_dir*1), 0, clamp(#program_list-(height-4), 0, #program_list)))
            os.queueEvent("redraw_list")
        end
    end
end

local function clickThread()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        if y > 1 then
            local file = program_list[(y-1)+scroll]
            if file ~= nil then

                selected_program = file
                selected_color = colors.blue

                
                os.queueEvent("redraw_list")
                sleep(0.5)
                run_threads = false

                term.setTextColor(colors.white)
                term.setBackgroundColor(colors.black)

                term.clear()
                term.setCursorPos(1,1)

                sleep()

                local stat = shell.run(file)

                run_threads = true

                term.setCursorBlink(false)

                if not stat then
                    selected_color = colors.red
                    os.queueEvent("redraw_list")
                    sleep(0.25)
                    selected_color = colors.black
                    os.queueEvent("redraw_list")
                    sleep(0.25)
                    selected_color = colors.red
                    os.queueEvent("redraw_list")
                    sleep(0.25)
                    selected_color = colors.black
                    os.queueEvent("redraw_list")
                    sleep(0.25)
                    selected_color = colors.red
                    os.queueEvent("redraw_list")
                    sleep(0.25)
                    selected_program = ""
                    os.queueEvent("redraw_list")
                else
                    selected_color = colors.blue
                    os.queueEvent("redraw_list")
                    sleep(0.25)
                    selected_program = ""
                    os.queueEvent("redraw_list")
                end


            end
        end
    end
end

while true do
    local stat, err = pcall(function()
        parallel.waitForAll(drawMenu, scrollInput, clickThread)
    end)

    if not stat then
        if err ~= "Terminated" then
            error(err)
        else
            term.setTextColor(colors.red)
            term.setBackgroundColor(colors.lightBlue)

            term.clear()
            term.setCursorPos(1,1)
            print("Starting Homepage")
            local stat2, err2 = pcall(function()
                for i1=1, 7 do
                    write(1,2,"[", colors.lightBlue, colors.red)
                    write(width,2,"]", colors.lightBlue, colors.red)
                    fill(2,2,(width-1)*(i1/7), 2, colors.lightBlue, colors.red, "/")
                    sleep(0.1)
                end
            end)
            term.setTextColor(colors.red)
            term.setBackgroundColor(colors.lightBlue)

            term.clear()
            term.setCursorPos(1,1)
            if not stat2 then
                if err2 == "Terminated" then
                    term.setTextColor(colors.white)
                    term.setBackgroundColor(colors.black)
                    print("Exited Program")
                    return
                else
                    term.setTextColor(colors.white)
                    term.setBackgroundColor(colors.black)
                    error(err2)
                end
            else
                term.setTextColor(colors.white)
                term.setBackgroundColor(colors.black)
                print("Exited Program")
                return
            end
        end
    end
end
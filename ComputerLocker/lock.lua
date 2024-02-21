local config = {}

local function saveConfig()
    local file = io.open("/cfg_lock.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

if fs.exists("/cfg_lock.txt") then
    local file = io.open("/cfg_lock.txt", "r")
    config = textutils.unserialise(file:read("*a"))
    file:close()
else
    print("Welcome to the Locker Wizard!")
    print("Enter your new password:")
    config.password = read()

    print("Display program list on unlock? (Y/N)")
    config.list_programs = (read():lower() == "y")

    local startup_file = io.open("startup.lua", "w")
    startup_file:write("shell.execute('lock.lua')")
    startup_file:close()

    saveConfig()
end



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
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            term.setCursorPos(x+i1-1,y+i2-1)
            term.write(char or " ")
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
end

local width, height = term.getSize()
local height_middle = math.ceil(height/2)

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char)
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

local function center_text(text)
    local width, height = term.getSize()
    local text_len = text:len()

    return (width/2) - (text_len/2)
end

local function custom_read(replaceChar)
    local start_x, start_y = term.getCursorPos()
    local bg = term.getBackgroundColor()
    local fg = term.getTextColor()
    local blur_length = 0
    local text_input = ""
    local blur_status = true
    local type_function = function()
        while true do
            local event = {os.pullEvent()}
            if event[1] == "char" then
                text_input = text_input..event[2]
                os.startTimer(0.5)
                blur_length = #text_input-1
            elseif event[1] == "key" then
                if event[2] == keys.backspace then
                    text_input = text_input:sub(1, (#text_input)-1)
                    blur_length = #text_input
                elseif event[2] == keys.enter or event[2] == keys.numPadEnter then
                    return
                elseif event[2] == keys.leftCtrl then
                    blur_status = false
                end
            elseif event[1] == "key_up" then
                if event[2] == keys.leftCtrl then
                    blur_status = true
                end
            end

            fill(1, start_y, width, start_y, bg, fg, " ")
            if replaceChar then
                write(center_text(text_input), start_y, text_input, bg, fg)
                if blur_status then
                    write(center_text(text_input), start_y, string.rep(replaceChar, blur_length), bg, fg)
                end
            else
                write(center_text(text_input), start_y, text_input, bg, fg)
            end
        end
    end
    local blur_function = function()
        while true do
            local event = {os.pullEvent()}
            if event[1] == "timer" then
                blur_length = blur_length+clamp(#text_input-blur_length, -1, 1)
                write(center_text(text_input), start_y, string.rep(replaceChar, blur_length), bg, fg)
            end
        end
    end

    parallel.waitForAny(type_function, blur_function)
    return text_input
end

while true do
    local stat, err = pcall(function()
        term.clear()
        term.setCursorPos(1,1)

        fill(1, 1, width, height, colors.lightBlue, colors.white, " ")

        write(2, height_middle-3, "Computer is locked", colors.lightBlue, colors.red)

        fill(1, height_middle-1, width, height_middle-1, colors.black, colors.white, "-")
        fill(1, height_middle, width, height_middle, colors.black, colors.white, " ")
        fill(1, height_middle+1, width, height_middle+1, colors.black, colors.white, "-")

        write(2, height_middle+3, "Hold 'CTRL' to display password", colors.lightBlue, colors.blue)

        term.setCursorPos(1, height_middle)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.lightGray)
        local input_pw = custom_read("*"):gsub("\n", "")
        if input_pw == config.password then
            return "correct"
        elseif input_pw == "exit" then
            os.shutdown()
        end
    end)
    if not stat and err == "Terminated" then
        os.shutdown()
    elseif stat then
        if err == "correct" then
            write(2, height_middle-3, "Computer is unlocked!", colors.lime, colors.black)
            sleep(1)
            for i1=1, height+2 do
                fill(1, 1, width, height, colors.black, colors.white, " ")
                fill(1, 1, width, height-i1, colors.lightBlue, colors.white, " ")
                fill(1, height-i1, width, height-i1, colors.black, colors.blue, "\x7F")
                sleep(0.025)
            end
            term.clear()
            term.setCursorPos(1,1)
            term.setTextColor(colors.lightGray)
            print("Computer successfully unlocked!")
            if config.list_programs then
                term.setTextColor(colors.white)
                print("Available Programs:")
                term.setTextColor(colors.orange)

                local text = ""
                for k,v in ipairs(fs.list("/")) do
                    if v:match("[/]?.+%.(.+)") == "lua" then
                        text = text.." "..(v)
                    end
                end
                print(text)
                print("")
            end
            break
        end
    end
end
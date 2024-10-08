local monitor = peripheral.find("monitor")
if monitor then
    
else
    print("Waiting for monitor..")
    while true do
        local stat, err, success = pcall(function()
            repeat
                os.pullEvent("peripheral")
                monitor = peripheral.find("monitor")
            until monitor
            print("Monitor connected!")
            error("monitor_connected")
        end)
        if not stat then print(err) end
        if (err or ""):match("monitor_connected") then
            break
        else
            print("Termination not allowed.")
        end
    end
end

local completion = require "cc.completion"
local mode_list = {
    "rs",
    "program"
}

local function path_completion(text)
    if fs.exists(text) and fs.isDir(text) then
        return completion.choice(text, fs.list(text))
    else
        return completion.choice(text, fs.list(""))
    end
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
monitor.setPaletteColor(colors.black, 0x000000)

if not fs.exists("/startup.lua") then
    local startup = io.open("/startup.lua", "w")
    local location = shell.getRunningProgram()

    local startup_text = [[print("Starting CodeRS") shell.run("]]..location..[[")]]
    startup:write(startup_text)
    startup:close()

    print("Created startup file")
    sleep(0.5)
    settings.set("shell.allow_disk_startup", false)
    settings.save()
    print("Disabled disk startup")
    sleep(0.5)
end

local config = {}
local function writeConfig()
    local file = io.open(".code_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

local function loadConfig()
    if fs.exists(".code_config.txt") then
        local file = io.open(".code_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end

if not fs.exists(".code_config.txt") then
    print("Enter Code:")
    print("(7 characters max)")
    local new_code = read()
    if #new_code <= 7 then
        config.code = new_code
    else
        print("Error! Code too long")
    end

    print("Auto-Enter when reaching code length?")
    print("y/n")
    local res = read()
    if res == "y" or res == "yes" or res == "true" then
        res = true
    else
        res = false
    end
    config.auto_enter = res
    print("Auto-Enter set to: "..tostring(res))

    print("Enter Mode: (rs, program)")
    local new_mode = read(nil, nil, function(txt) return completion.choice(txt, mode_list) end)
    config.mode = new_mode

    if new_mode == "rs" then
        print("Redstone Side?")
        config.output_side = read(nil, nil, completion.side)
    elseif new_mode == "program" then
        print("Enter the desired file to start on success:")
        local file = read(nil, nil, path_completion)
        config.output_program = file
    end

    sleep(0.5)
    term.clear()

    writeConfig()
end

loadConfig()

config.mode = config.mode or "rs"
config.output_program = config.output_program or nil
config.code = config.code or nil
config.auto_enter = config.auto_enter or false
config.output_side = config.output_side or "back"

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

local top_status = "pin"

local exit_mode = false
local confirm_exit = false

local function drawThread()
    while true do
        fill(1, 1, w, 1, colors.black, colors.white, " ")
        if top_status == "pin" then
            if #input_code < 1 then
                write(2,1, " PIN ", colors.black, colors.lightGray)
            else
                write(1,1, string.rep("*", #input_code), colors.black, colors.yellow)
            end
        elseif top_status == "false" then
            write(1,1, "DENIED", colors.black, colors.red)
        elseif top_status == "true" then
            write(1,1, "SUCCESS", colors.black, colors.green)
        elseif top_status == "true_exit" then
            write(1,1, "ALLOWED", colors.black, colors.purple)
        elseif top_status == "exit" then
            if #input_code < 1 then
                write(2,1, "TRMNT", colors.black, colors.purple)
            else
                write(1,1, string.rep("*", #input_code), colors.black, colors.magenta)
            end
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

regButton(2,2, function() addChar("1") end) regButton(4,2, function() addChar("2") end) regButton(6,2, function() addChar("3") end)
regButton(2,3, function() addChar("4") end) regButton(4,3, function() addChar("5") end) regButton(6,3, function() addChar("6") end)
regButton(2,4, function() addChar("7") end) regButton(4,4, function() addChar("8") end) regButton(6,4, function() addChar("9") end)
regButton(4,5, function() addChar("0") end) 
regButton(2,5, function() input_code = "" end)
regButton(6,5, function() 
    local input = input_code
    input_code = ""
    os.queueEvent("redraw_keypad")
    if input == config.code then
        if exit_mode then
            top_status = "true_exit"
            os.queueEvent("redraw_keypad")
            exit_mode = false
            confirm_exit = true
            print("CODE CONFIRMED\nTermination is now allowed")
            os.sleep(0.5)
        else
            top_status = "true"
            os.queueEvent("redraw_keypad")
            if config.mode == "rs" then
                redstone.setOutput(config.output_side, true)
                os.sleep(0.5)
                redstone.setOutput(config.output_side, false)
            elseif config.mode == "program" then
                os.sleep(0.5)
                shell.run(config.output_program)
            end
        end
        top_status = "pin"
    else
        if confirm_exit then
            print("Wrong code entered, termination blocking re-enabled!")
            confirm_exit = false
        end
        top_status = "false"
        exit_mode = false
        os.queueEvent("redraw_keypad")
        redstone.setOutput(config.output_side, false)
        os.sleep(0.5)
        top_status = "pin"
    end
    os.queueEvent("redraw_keypad")
end)

local function clickThread()
    while true do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local button = findPressedButton(x,y)
        if button and button.func then
            button.func()
        end
        if config.auto_enter and #input_code >= #(config.code) then
            os.queueEvent("monitor_touch", "idk", 6, 5)
        end
        os.queueEvent("redraw_keypad")
    end
end

local function monitorDisconnectThread()
    while true do
        os.pullEvent("peripheral_detach")
        if not peripheral.find("monitor") then
            print("Monitor Detached! Rebooting..")
            os.reboot()
        end
    end
end

while true do
    local stat, err = pcall(function()
        parallel.waitForAll(drawThread, clickThread, monitorDisconnectThread)
    end)
    if not stat then
        if err == "Terminated" then
            if confirm_exit then
                print("Program successfully terminated")
                break
            else
                if exit_mode == true then
                    print("No code entered")
                    exit_mode = true
                    top_status = "exit"
                else
                    print("Please enter code to allow terminate")
                    exit_mode = true
                    top_status = "exit"
                end
            end
        else
            print(err)
        end
    end
end
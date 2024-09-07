local completion = require("cc.completion")

local width, height = term.getSize()

local main_window = window.create(term.current(), 1, 1, width, height-3, true)
local input_window = window.create(term.current(), 1, height-2, width, 3, true)

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local config = {}

local function loadConfig()
    if fs.exists("/.jjsdialer_config.txt") then
        local file = io.open("/.jjsdialer_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open("/.jjsdialer_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()

if config.default_fastdial == nil then
    config.default_fastdial = true
end

writeConfig()

local logs_data = {
    gate = {
        file="/.jd_logs/gate.log",
        data = {}
    }
}

local logging = {
    gate = {
        fn = {
            write = function(level_letter, text)
                local data = logs_data.gate.data
                data[#data+1] = os.date("[%m/%d-%H:%M:%S]")..level_letter.."> "..text.."$end"
                if #data > 300 then
                    table.remove(data, 1)
                end

                local file = io.open(logs_data.gate.file, "a")
                if file then
                    for k, line in ipairs(data) do
                        file:write(line.."\n")
                    end
                    file:close()
                end
            end,
            load = function()
                local file = io.open(logs_data.gate.file, "r")
                local data = logs_data.gate.data
                data = {}
                if file then
                    for entry in file:read("*a"):gmatch("(.+)$end") do
                        data[#data+1] = entry
                    end
                    file:close()
                end
            end
        }
    }
}

logging.gate.fn.load()

print(textutils.serialize(logs_data.gate.data))

sleep(10)

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))

    modem.open(2707)
end

local function fill(win, x,y,x1,y1,bg,fg,char)
    local old_bg = win.getBackgroundColor()
    local old_fg = win.getTextColor()
    local old_posx,old_posy = win.getCursorPos()
    if bg then
        win.setBackgroundColor(bg)
    end
    if fg then
        win.setTextColor(fg)
    end
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            win.setCursorPos(x+i1-1,y+i2-1)
            win.write(char or " ")
        end
    end
    win.setTextColor(old_fg)
    win.setBackgroundColor(old_bg)
    win.setCursorPos(old_posx,old_posy)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(win, x,y,x1,y1,bg,fg,char)
    local old_bg = win.getBackgroundColor()
    local old_fg = win.getTextColor()
    local old_posx,old_posy = win.getCursorPos()
    if bg then
        win.setBackgroundColor(bg)
    end
    if fg then
        win.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                win.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    win.write()
                else
                    win.write(char or " ")
                end
            end
        end
    end
    win.setTextColor(old_fg)
    win.setBackgroundColor(old_bg)
    win.setCursorPos(old_posx,old_posy)
end

local function write(win, x,y,text,bg,fg)
    local old_posx,old_posy = win.getCursorPos()
    local old_bg = win.getBackgroundColor()
    local old_fg = win.getTextColor()

    if bg then
        win.setBackgroundColor(bg)
    end
    if fg then
        win.setTextColor(fg)
    end

    win.setCursorPos(x,y)
    win.write(text)

    win.setTextColor(old_fg)
    win.setBackgroundColor(old_bg)
    win.setCursorPos(old_posx,old_posy)
end

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function parseCommand(text)
    local output = {}
    local quote_mode = false
    local buffer = ""
    local last_char = ""
    for char_num=1, #text do
        local char = text:sub(char_num, char_num)

        if char:match("[%w_%.%-]") then
            buffer = buffer..char
        elseif char:match("%s") then
            if quote_mode then
                buffer = buffer..char
            else
                if buffer ~= "" then
                    output[#output+1] = buffer
                    buffer = ""
                end
            end
        elseif char:match('["\']') then
            quote_mode = not quote_mode
            if quote_mode == false then
                output[#output+1] = buffer
                buffer = ""
            end
        end

        if char_num == #text then
            last_char = char
            quote_mode = false
            output[#output+1] = buffer
            buffer = ""
        end
    end
    return output, last_char
end

local commands = {
    type="parent",
    name="main",
    children={}
}

local function registerCommand(parent, name, args, func)
    if parent and parent.children then
        parent.children[name] = {
            type="command",
            args=args,
            func=func,
            name=name
        }
    end
    return parent.children[name]
end

local function registerParent(parent, name)
    if parent and parent.children then
        parent.children[name] = {
            type="parent",
            children = {},
            name=name
        }
    end
    return parent.children[name]
end

local cmd_main = registerParent(commands, "main")

local arg_type_completion = {
    boolean={
        "true",
        "false"
    },
    string={},
    basic_address={}
}

local basic_addresses = {
    overworld = {extragalactic = "-1-35-4-31-15-30-32-", milky_way = "-27-25-4-35-10-28-"},
    nether = {extragalactic = "-1-35-6-31-15-28-32-", milky_way = "-27-23-4-34-12-28-"},
    the_end = {extragalactic = "-18-24-8-16-7-35-30-", milky_way = "-13-24-2-19-3-30-", pegasus = "-14-30-6-13-17-23-"},
    abydos = {extragalactic = "-1-17-2-34-26-9-33-", milky_way = "-26-6-14-31-11-29-"},
    chulak = {extragalactic = "-1-9-14-21-17-3-29-", milky_way = "-8-1-22-14-36-19-"},
    blackhole = {extragalactic = "-1-34-12-18-7-31-6-", milky_way = "-18-7-3-36-25-15-"},
    lantea = {extragalactic = "-18-20-1-15-14-7-19-", pegasus = "-29-5-17-34-6-12-"},
}

local function commandCompletion(text, parent)
    local current_step = parent
    local current_arg = {}
    local args, last_char = parseCommand(text)
    local arg_pos = nil
    local last_complete_arg = 0
    local last_arg = args[#args]
    local full_arg = false
    local args_left = 0
    local correct_args = 0
    for pos=1, #args+1 do
        arg = args[pos]
        if arg then
            if current_step.type == "parent" and current_step.children[arg] then
                current_step = current_step.children[arg]
                last_complete_arg = pos
                correct_args = correct_args+1
            elseif current_step.type == "command" and current_step.args then
                if not arg_pos then arg_pos = pos end
                local curr_arg_pos = (pos)-((arg_pos) or 0)
                current_arg = current_step.args[curr_arg_pos]

                args_left = #current_step.args - curr_arg_pos
            else
                break
            end
        else
            if last_complete_arg == #args then
                if current_step.type == "command" and current_step.args then
                    if not arg_pos then arg_pos = pos end
                    local curr_arg_pos = (pos+1)-((arg_pos) or 0)
                    current_arg = current_step.args[curr_arg_pos]

                    args_left = #current_step.args - curr_arg_pos
                end
            else
                if current_step.type == "command" and current_step.args then
                    local curr_arg_pos = (pos)-((arg_pos) or 0)
                    current_arg = current_step.args[curr_arg_pos]

                    args_left = #current_step.args - curr_arg_pos
                end
            end
        end
    end
    if last_complete_arg == #args then
        full_arg = true
        last_arg = ""
    end

    local prefix = ""
    if last_char ~= "" and full_arg and not last_char:match("%s") then
        prefix = " "
    end

    local return_value = {}
    if arg_pos and current_arg then
        if arg_type_completion[current_arg.type] then
            for k,v in pairs(arg_type_completion[current_arg.type]) do
                return_value[#return_value+1] = prefix..v
            end
        end
    else
        if current_step.type == "parent" and current_step.children then
            for child_name,v in pairs(current_step.children) do
                return_value[#return_value+1] = prefix..child_name
            end
        end
    end

    --fill(input_window, 1, 3, width, 3)
    --write(input_window, 1, 3, (tostring(return_value[1]) or "??").." | "..tostring(full_arg))

    local arg_info
    
    if current_arg and current_arg.optional then
        arg_info = (current_arg and current_arg.name and "["..current_arg.name.."("..(current_arg.display_type or "?")..", Optional)]" or "No Argument")
    else
        arg_info = (current_arg and current_arg.name and "<"..current_arg.name.."("..(current_arg.display_type or "?")..")>" or "No Argument")
    end
    return completion.choice((last_arg or ""), (#text > 0 and (correct_args > 0 or (#args == 1 and not full_arg)) and return_value or {})), arg_info, (args_left > 0 and args_left or nil)
end

local command_history = {}

local function commandInputThread()
    while true do
        term.redirect(input_window)
        fill(input_window, 1, 2, width, 2)
        write(input_window, 1, 2, ">", colors.black, colors.blue)
        term.setCursorPos(3, 2)
        local input = read(nil, command_history, (function(text)
                local completion, arg_detail, arg_left = commandCompletion(text, cmd_main) 
                input_window.setVisible(false)
                fill(input_window, 1, 3, width, 3)
                write(input_window, 1, 3, arg_detail..( arg_left and " | Left: "..arg_left or ""), colors.black, colors.lightGray)
                input_window.setVisible(true)
                return completion
            end), "")

        if command_history[#command_history] ~= input and input ~= "" then
            command_history[#command_history+1] = input
        end

        local current_step = cmd_main
        local arg_list = {}
        local args, last_char = parseCommand(input)
        local arg_pos = nil
        for pos=1, #args+1 do
            arg = args[pos]
            if arg then
                if current_step.type == "parent" and current_step.children[arg] then
                    current_step = current_step.children[arg]
                elseif current_step.type == "command" then
                    arg_list[#arg_list+1] = arg
                else
                    break
                end
            end
        end

        if current_step.type == "command" and current_step.func then
            local stat, err = pcall(current_step.func, table.unpack(arg_list))
            if not stat then
                error(err)
            end
        end
    end
end

local dialing_enabled = false

local function gateDialingThread()
    while true do
        local event, fastdial, address = os.pullEvent("jjsdialer_internal_dial")
        dialing_enabled = true
        
        for k, symbol in ipairs(address) do
            if dialing_enabled then
                if (fastdial and interface.engageSymbol) or not interface.rotateClockwise then
                    interface.engageSymbol(symbol)
                    sleep(0.1)
                elseif not fastdial and interface.rotateClockwise then
                    if interface.isChevronOpen(symbol) then
                        interface.closeChevron()
                    end
            
                    if (symbol-interface.getCurrentSymbol()) % 39 < 19 then
                        interface.rotateAntiClockwise(symbol)
                    else
                        interface.rotateClockwise(symbol)
                    end
                    
                    repeat
                        sleep(0.1)
                    until interface.getCurrentSymbol() == symbol
            
                    sleep(0.1)
                    interface.openChevron()
                    sleep(0.1)
                    interface.encodeChevron()
                    sleep(0.1)
                    interface.closeChevron()
                end
            else
                interface.disconnectStargate()
                break
            end
        end
        dialing_enabled = false
    end
end

local main_w, main_h = main_window.getSize()

local main_window_mode = "none"

local logging_mode = "none"
local logging_start_line = 3
local logging_stop_line = main_h-1

local main_scrolling = 0

local function mainDrawThread()
    while true do
        os.pullEvent("jjsdialer_internal_redraw_main")
        if main_window_mode == "none" then
            main_window.clear()
        elseif main_window_mode == "logging" then
            main_window.setVisible(false)
            write(main_window, 1, 1, "Logging Display: "..logging_mode)

            local data =  {}
            if logs_data[logging_mode] then
                data = logs_data[logging_mode].data
            end
            main_window.setCursorPos(1, logging_start_line)
            for num=1, #data do
                local entry = data[#data-(logging_stop_line-logging_start_line)+num]
                if entry then
                    local level_letter = entry:match("](%w)>")
                    if level_letter == "I" then
                        main_window.setTextColor("colors.lightGray")
                    elseif level_letter == "W" then
                        main_window.setTextColor("colors.yellow")
                    elseif level_letter == "E" then
                        main_window.setTextColor("colors.red")
                    end

                    for char in entry:gmatch(".") do
                        if char == "\n" then
                            local curr_x, curr_y = main_window.getCursorPos()
                            main_window.setCursorPos(6, curr_y+1)
                        elseif char == "$" then
                            break
                        else
                            main_window.write(char)
                        end
                    end
                    local curr_x, curr_y = main_window.getCursorPos()
                    main_window.setCursorPos(1, curr_y+1)
                end
            end
            main_window.setVisible(true)
        end
    end
end

local function mainClickThread()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        local stat, err = pcall(main_clickfunc, button, x, y)
    end
end

local function setMainMode(text)
    main_window_mode = text
    os.queueEvent("jjsdialer_internal_redraw_main")
end

local function gateLogging()
    local record_outgoing = false
    local outgoing_travellers = {}
    local record_incoming = false
    local incoming_travellers = {}
    while true do
        local event = {os.pullEvent()}
        if event[1] then
            if event[1] == "stargate_disconnected" then
                if record_incoming then
                    record_incoming = false
                    logging.gate.fn.write("I", "Stargate Disconnected".."\nTravellers:"..(#incoming_travellers))
                elseif record_outgoing then
                    record_outgoing = false
                    logging.gate.fn.write("I", "Stargate Disconnected".."\nTravellers:"..(#outgoing_travellers))
                end
            elseif event[1] == "stargate_incoming_wormhole" then
                logging.gate.fn.write("W", "Incoming Wormhole"..(event[2] and "\n"..table.concat(event[2], " ") or ""))
                record_incoming = true
                incoming_travellers = {}
            elseif event[1] == "stargate_outgoing_wormhole" then
                logging.gate.fn.write("I", "Outgoing Wormhole"..(event[2] and "\n"..table.concat(event[2], " ") or ""))
                record_outgoing = true
                outgoing_travellers = {}
            elseif event[1] == "stargate_deconstructing_entity" then
                if record_outgoing then
                    outgoing_travellers[#outgoing_travellers+1] = {name=event[3]}
                end
                if event[5] then
                    logging.gate.fn.write("W", "Traveller Disintegrated\nType: "..event[2].." Name: "..event[3] )
                end
            elseif event[1] == "stargate_reconstructing_entity" then
                if record_incoming then
                    incoming_travellers[#incoming_travellers+1] = {name=event[3]}
                end
            end
            os.queueEvent("jjsdialer_internal_redraw_main")
        end
    end
end

local sg = registerParent(cmd_main, "sg")
local sg_dial = registerParent(sg, "dial")
local sg_dial_manual = registerCommand(sg_dial, "manual", {
    {name="address", type="string", display_type="string", optional = false},
    {name="fastdial", type="boolean", display_type="boolean", optional = true}
}, function(address, fastdial)
    if address then
        local address_table = {}
        for v in address:gmatch("%d+") do
            if tonumber(v) then
                address_table[#address_table+1] = tonumber(v)
            end
        end

        address_table[#address_table+1] = 0

        os.queueEvent("jjsdialer_internal_dial", ((fastdial and fastdial == "true") or config.default_fastdial), address_table)
    end
end)

local sg_dial_defaults = registerParent(sg_dial, "defaults")

for destination, addresses in pairs(basic_addresses) do
    local new_dest = registerParent(sg_dial_defaults, destination)
    for location, address in pairs(addresses) do
        local new_cmd = registerCommand(new_dest, location, {
            {name="fastdial", type="boolean", optional = true}
        }, function(fastdial)
            local func_address = address
            if func_address then
                local address_table = {}
                for v in func_address:gmatch("%d+") do
                    if tonumber(v) then
                        address_table[#address_table+1] = tonumber(v)
                    end
                end
        
                address_table[#address_table+1] = 0
        
                os.queueEvent("jjsdialer_internal_dial", ((fastdial and fastdial == "true") or config.default_fastdial), address_table)
            end
        end)
    end
end

local sg_stop = registerCommand(sg, "stop", {}, function()
    interface.disconnectStargate()
    if interface.rotateClockwise then
        if (0-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(0)
        else
            interface.rotateClockwise(0)
        end
    end
end)

local logs = registerParent(cmd_main, "logs")
local logs_gate = registerCommand(logs, "gate", {}, function()
    logging_mode = "gate"
    setMainMode("logging")
end)

local stat, err = pcall(function()
    parallel.waitForAny(commandInputThread, gateDialingThread, mainClickThread, mainDrawThread, gateLogging)
end)

term.redirect(term.native())

if not stat then err(err) end
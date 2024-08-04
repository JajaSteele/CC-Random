local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
end

local width, height = term.getSize()

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

local function sendForgedRednet(receiver, sender, message, protocol)
    modem.transmit(receiver, sender, {
        nRecipient = receiver,
        nMessageID = math.random(100000000, 999999999),
        message = message,
        nSender = sender,
        sProtocol = protocol
    })
end

local function receiveForgedRednet(receiver, protocol, timeout, sender)
    modem.open(receiver)
    local timer_id
    if timeout and type(timeout) == "number" then
        timer_id = os.startTimer(timeout)
    end
    while true do
        local data = {os.pullEvent()}
        local event = data[1]

        if event == "timer" then
            if data[2] == timer_id then
                modem.close(receiver)
                return nil
            end
        elseif event == "modem_message" then
            local event, side, channel, reply_channel, message, distance = table.unpack(data)
            if message.nRecipient == receiver and (not protocol or protocol == message.sProtocol) and (not sender or message.nSender == sender) then
                modem.close(receiver)
                return message.nSender, message.message, message.sProtocol
            end
        end
    end
end

local ui_elements = {}
local biggest_id = 0

local function setClickFunc(element_id, func)
    if ui_elements[element_id] then
        ui_elements[element_id].click_func = func
        return true
    else
        return false
    end
end

local function setValue(element_id, value_id, value)
    local element = ui_elements[element_id]
    if element and element.value then
        element.value[value_id] = value
        if element.special_func and element.special_func.set_value then
            local stat, err = pcall(element.special_func.set_value, element_id)
            if not stat then error(err) end
        end
        return true
    else
        return false
    end
end

local function getValue(element_id, value_id)
    if ui_elements[element_id] and ui_elements[element_id].value then
        return ui_elements[element_id].value[value_id]
    else
        return false
    end
end

local function setActive(element_id, active)
    local element = ui_elements[element_id]
    if element then
        element.is_active = active
        return true
    else
        return false
    end
end

local function getActive(element_id)
    local element = ui_elements[element_id]
    if element then
        return element.is_active
    else
        return false
    end
end

local function getPos(element_id)
    local element = ui_elements[element_id]
    if element then
        return element.pos
    else
        return false
    end
end

local function getElement(id)
    return ui_elements[id]
end

local function input(x, y, max, fg, bg, char_filter, default)
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
    term.setCursorBlink(true)
    local input = default or ""
    while true do
        fill(x,y, x+#input, y, bg, fg, " ")
        write(x,y, input, bg, fg)
        term.setCursorPos(x+#input,y)
        local data = {os.pullEvent()}
        local event = data[1]

        if event == "char" then
            local event, char = table.unpack(data)
            if char_filter then
                char = char:match(char_filter)
            end

            if #input < (max or #input+1) and char then
                input = input..char
            end
        elseif event == "key" then
            local event, key, held = table.unpack(data)
            if key == keys.backspace and #input > 0 then
                input = input:sub(1, #input-1)
            elseif key == keys.enter or key == keys.numPadEnter then
                break
            end
        end
    end
    
    term.setCursorBlink(false)
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)

    return input
end

local function addText(x, y, text, fg, bg)
    local data = {
        type = "text",
        pos = {
            x=x,
            y=y,
            x2=x+#text,
            y2=y
        },
        value = {
            text=text,
            fg = fg,
            bg = bg
        },
        id = biggest_id+1,
        special_func = {
            set_value = (function(id)
                local em = getElement(id) 
                em.pos.x2 = em.pos.x+#(em.value.text)
            end)
        },
        is_active = true
    }
    ui_elements[biggest_id+1] = data
    biggest_id = biggest_id+1
    return data.id
end

local function addFill(x, y, x2, y2, bg, fg, char)
    local data = {
        type = "fill",
        pos = {
            x=x,
            y=y,
            x2=x2,
            y2=y2
        },
        value = {
            char=char,
            fg = fg,
            bg = bg
        },
        id = biggest_id+1,
        is_active = true
    }
    ui_elements[biggest_id+1] = data
    biggest_id = biggest_id+1
    return data.id
end

local function addInputBox(x, y, prefix, default_input, fg, bg, input_fg, input_bg, char_filter, max_length)
    local data = {
        type = "input_box",
        pos = {
            x=x,
            y=y,
            input_x=x+#prefix+1,
            input_y=y,
            x2=x+#prefix+1+#default_input,
            y2=y
        },
        value = {
            prefix=prefix,
            input=default_input,
            fg = fg,
            bg = bg,
            input_fg = input_fg,
            input_bg = input_bg,
            char_filter = char_filter,
            max = max_length
        },
        id = biggest_id+1,
        special_func = {
            set_value = (function(id)
                local em = getElement(id) 
                em.pos.x2 = em.pos.x+#(em.value.prefix)+1+#(em.value.input)
            end)
        },
        click_func = (function(id, button)
            local old_bg = term.getBackgroundColor()
            local old_fg = term.getTextColor()
            local old_posx,old_posy = term.getCursorPos()

            local em = getElement(id)
            term.setCursorPos(em.pos.input_x, em.pos.input_y)
            term.setTextColor(input_fg)
            term.setBackgroundColor(input_bg)

            fill(em.pos.input_x, em.pos.input_y, em.pos.input_x+#em.value.input, em.pos.input_y, input_bg, input_fg, " ")

            local input = input(em.pos.input_x, em.pos.input_y, em.value.max, em.value.input_fg, em.value.input_bg, em.value.char_filter, em.value.input)
            em.value.input = input

            em.pos.x2 = em.pos.x+#(em.value.prefix)+1+#(em.value.input)

            term.setCursorPos(old_posx,old_posy)
            term.setTextColor(old_fg)
            term.setBackgroundColor(old_bg)
            return input
        end),
        is_active = true
    }
    ui_elements[biggest_id+1] = data
    biggest_id = biggest_id+1
    return data.id
end

local function uiDrawer()
    while true do
        os.pullEvent("ui_redraw")
        term.clear()
        for num, element in pairs(ui_elements) do
            if element.is_active then
                if element.type == "text" then
                    write(element.pos.x, element.pos.y, element.value.text, element.value.bg, element.value.fg)
                elseif element.type == "input_box" then
                    write(element.pos.x, element.pos.y, element.value.prefix, element.value.bg, element.value.fg)
                    write(element.pos.input_x, element.pos.input_y, element.value.input, element.value.input_bg, element.value.input_fg)
                elseif element.type == "fill" then
                    fill(element.pos.x, element.pos.y, element.pos.x2, element.pos.y2, element.value.bg, element.value.fg, element.value.char)
                end
            end
        end
    end
end

local function clickManager()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        local last_found_element

        for num, element in pairs(ui_elements) do
            if element.is_active and x >= element.pos.x and y >= element.pos.y and x <= element.pos.x2 and y <= element.pos.y2 then
                last_found_element = element
            end
        end

        if last_found_element and last_found_element.click_func then
            local stat, err = pcall(last_found_element.click_func, last_found_element.id, button)
            if not stat then error(err) end
        end

        os.queueEvent("ui_redraw")
    end
end

local sender_message_data
sender_message_data = "msg"

-- Rednet Sender Page
local sender_title_bar = addFill(1,1, width, 1, colors.gray, colors.white, " ")
local sender_title = addText(3,1, "Rednet Forger", colors.white, colors.gray)

local sender_sender_input = addInputBox(2,3, "Sender:", "0", colors.white, colors.black, colors.magenta, colors.black, "%d", 4)
local sender_receiver_input = addInputBox(getPos(sender_sender_input).input_x+5,3, "Receiver:", "0", colors.white, colors.black, colors.magenta, colors.black, "%d", 4)

local sender_message_button = addInputBox(2,5, "Message:", '"msg"', colors.white, colors.black, colors.yellow, colors.black)
local sender_protocol_input = addInputBox(2,6, "Protocol:", "prc", colors.white, colors.black, colors.yellow, colors.black)

local sender_confirm = addText(2,8, "Send Forged Message", colors.lime, colors.black)
setClickFunc(sender_confirm, function()
    local sender = tonumber(getValue(sender_sender_input, "input"))
    local receiver = tonumber(getValue(sender_receiver_input, "input"))
    local message = sender_message_data
    local protocol = getValue(sender_protocol_input, "input")
    sendForgedRednet(receiver, sender, message, protocol)
end)

-- Rednet Message Editor Page
local me_title_bar = addFill(1,1, width, 1, colors.gray, colors.white, " ")
local me_title = addText(3,1, "Rednet Message Editor", colors.white, colors.gray)

local me_type_input = addInputBox(2,3, "Type:", "string", colors.white, colors.black, colors.yellow, colors.black, "%a")
local me_type_next = {
    boolean="string",
    string="number",
    number="boolean"
}
local me_type_prev = {
    string="boolean",
    boolean="number",
    number="string"
}

local me_type_settings = {
    string={
        limit=nil,
        filter=nil,
        color=colors.yellow
    },
    boolean={
        limit=nil,
        filter="%a",
        color=colors.lightBlue
    },
    number={
        limit=nil,
        filter="%d",
        color=colors.magenta
    }
}
local me_msg_input = addInputBox(2,5, "Message:", "msg", colors.white, colors.black, colors.yellow, colors.black, "%a")
setClickFunc(me_type_input, function(id, button)
    local new_type
    if button == 1 then
        new_type = me_type_next[getValue(id, "input")]
        setValue(id, "input", new_type)
    elseif button == 2 then
        new_type = me_type_prev[getValue(id, "input")]
        setValue(id, "input", new_type)
    end

    if new_type then
        setValue(me_msg_input, "max", me_type_settings[new_type].limit)
        setValue(me_msg_input, "char_filter", me_type_settings[new_type].filter)
        setValue(me_msg_input, "input_fg", me_type_settings[new_type].color)
    end
end)

local me_save_button = addText(2,7, "Save Message", colors.lime, colors.black)
setClickFunc(me_save_button, function(id, button)
    local msg_type = getValue(me_type_input, "input")
    local msg = getValue(me_msg_input, "input")

    if msg_type == "string" then
        sender_message_data = msg
        setValue(sender_message_button, "input", '"'..msg..'"')
        setValue(sender_message_button, "input_fg", colors.yellow)
    elseif msg_type == "number" then
        sender_message_data = tonumber(msg) or 0
        setValue(sender_message_button, "input", tostring(sender_message_data))
        setValue(sender_message_button, "input_fg", colors.magenta)
    elseif msg_type == "boolean" then
        local d = msg:lower()
        if d == "y" or d == "yes" or d == "true" or d == "1" then
            sender_message_data = true
        else
            sender_message_data = false
        end
        setValue(sender_message_button, "input", textutils.serialize(sender_message_data))
        setValue(sender_message_button, "input_fg", colors.lightBlue)
    end
end)
local me_exit_button = addText(2,8, "Exit Editor", colors.red, colors.black)

--Receiver Page
local receiver_title_bar = addFill(1,1, width, 1, colors.gray, colors.white, " ")
local receiver_title = addText(3,1, "Rednet Receiver", colors.white, colors.gray)

local receiver_sender_input = addInputBox(2,3, "Sender:", "", colors.white, colors.black, colors.magenta, colors.black, "%d", 4)
local receiver_receiver_input = addInputBox(getPos(sender_sender_input).input_x+5,3, "Receiver:", "0", colors.white, colors.black, colors.magenta, colors.black, "%d", 4)
local receiver_protocol_input = addInputBox(2,5, "Protocol:", "", colors.white, colors.black, colors.yellow, colors.black)
local receiver_timeout_input = addInputBox(2,6, "Timeout (s):", "", colors.white, colors.black, colors.magenta, colors.black, "%d", 2)

local receiver_button = addText(2, 8, "Receive", colors.lime, colors.black)

--Inspector Page
local inspector_msg_data

local inspector_title_bar = addFill(1,1, width, 1, colors.gray, colors.white, " ")
local inspector_title = addText(3,1, "Rednet Inspector", colors.white, colors.gray)

local inspector_sender_input = addInputBox(2,3, "Sender:", "0", colors.lightGray, colors.black, colors.magenta, colors.black, "%d", 4)
local inspector_receiver_input = addInputBox(getPos(sender_sender_input).input_x+5,3, "Receiver:", "0", colors.lightGray, colors.black, colors.magenta, colors.black, "%d", 4)

local inspector_protocol = addInputBox(2,5, "Protocol:", '?', colors.lightGray, colors.black, colors.yellow, colors.black)
local inspector_message = addInputBox(2,6, "Message:", '"?"', colors.lightGray, colors.black, colors.yellow, colors.black)

local inspector_table_export = addText(getPos(inspector_message).x2+1,6, "Export", colors.blue, colors.black)

local inspector_exit_button = addText(2,8, "Exit Inspector", colors.red, colors.black)

setClickFunc(inspector_sender_input, nil)
setClickFunc(inspector_receiver_input, nil)
setClickFunc(inspector_protocol, nil)
setActive(inspector_table_export, false)

local pages = {
    rednet_sender = {
        title_bar = sender_title_bar,
        title = sender_title,

        sender_input = sender_sender_input,
        receiver_input = sender_receiver_input,

        sender_message_button = sender_message_button,
        sender_protocol_input = sender_protocol_input,

        sender_confirm = sender_confirm,
    },
    msg_editor = {
        me_title_bar = me_title_bar,
        me_title = me_title,
        me_type_input = me_type_input,
        me_msg_input = me_msg_input,

        me_save_button = me_save_button,
        me_exit_button = me_exit_button
    },
    rednet_receiver = {
        receiver_title_bar = receiver_title_bar,
        receiver_title = receiver_title,

        receiver_sender_input = receiver_sender_input,
        receiver_receiver_input = receiver_receiver_input,
        receiver_protocol_input = receiver_protocol_input,
        receiver_timeout_input = receiver_timeout_input,
        receiver_button = receiver_button,
    },
    rednet_inspector = {
        inspector_title_bar = inspector_title_bar,
        inspector_title = inspector_title,

        inspector_sender_input = inspector_sender_input,
        inspector_receiver_input = inspector_receiver_input,

        inspector_protocol = inspector_protocol,
        inspector_message = inspector_message,
        inspector_table_export = inspector_table_export,

        inspector_exit_button = inspector_exit_button,
    }
}
local current_page = "rednet_sender"

local function changePage(page_name)
    local active_page = {}
    for page,page_data in pairs(pages) do
        if page == page_name then
            active_page = page_data
        else
            for k, element in pairs(page_data) do
                setActive(element, false)
            end
        end
    end
    if active_page then
        for k, element in pairs(active_page) do
            setActive(element, true)
        end
    end
    current_page = page_name
    os.queueEvent("ui_redraw")
end

setClickFunc(me_exit_button, function()
    changePage("rednet_sender")
end)
setClickFunc(sender_message_button, function()
    changePage("msg_editor")
end)

setClickFunc(sender_title, function()
    changePage("rednet_receiver")
end)
setClickFunc(receiver_title, function()
    changePage("rednet_sender")
end)

setClickFunc(inspector_exit_button, function()
    changePage("rednet_receiver")
end)

setClickFunc(receiver_button, function(id, button)
    local sender_filter = tonumber(getValue(receiver_sender_input, "input"))
    local receiver_filter = tonumber(getValue(receiver_receiver_input, "input"))
    local protocol_filter = getValue(receiver_protocol_input, "input")
    local timeout_filter = tonumber(getValue(receiver_timeout_input, "input"))

    if protocol_filter == "" then protocol_filter = nil end

    setValue(receiver_button, "fg", colors.orange)
    setValue(receiver_button, "text", "Awaiting Message..")
    os.queueEvent("ui_redraw")

    local sender, message, protocol = receiveForgedRednet(receiver_filter, protocol_filter, timeout_filter, sender_filter)

    if sender then
        setValue(receiver_button, "fg", colors.lime)
        setValue(receiver_button, "text", "Receive")

        setValue(inspector_sender_input, "input", tostring(sender))
        setValue(inspector_receiver_input, "input", tostring(receiver_filter))
        setValue(inspector_protocol, "input", protocol)

        local msg_type = type(message)

        if msg_type == "string" then
            inspector_msg_data = message
            setValue(inspector_message, "input", '"'..message..'"')
            setValue(inspector_message, "input_fg", colors.yellow)
            setActive(inspector_table_export, false)
        elseif msg_type == "number" then
            inspector_msg_data = tonumber(message) or 0
            setValue(inspector_message, "input", tostring(inspector_msg_data))
            setValue(inspector_message, "input_fg", colors.magenta)
            setActive(inspector_table_export, false)
        elseif msg_type == "boolean" then
            if message then
                inspector_msg_data = true
            else
                inspector_msg_data = false
            end
            setValue(inspector_message, "input", textutils.serialize(inspector_msg_data))
            setValue(inspector_message, "input_fg", colors.lightBlue)
            setActive(inspector_table_export, false)
        elseif msg_type == "table" then
                inspector_msg_data = message
            setValue(inspector_message, "input", "<table>")
            setValue(inspector_message, "input_fg", colors.orange)
            setActive(inspector_table_export, true)
            getPos(inspector_table_export).x = getPos(inspector_message).x2+1
        end
        
        changePage("rednet_inspector")
    else
        setValue(receiver_button, "fg", colors.red)
        setValue(receiver_button, "text", "No Response!")
        os.queueEvent("ui_redraw")
        sleep(1)
        setValue(receiver_button, "fg", colors.lime)
        setValue(receiver_button, "text", "Receive")
        os.queueEvent("ui_redraw")
    end
end)

changePage(current_page)

parallel.waitForAll(uiDrawer, clickManager)
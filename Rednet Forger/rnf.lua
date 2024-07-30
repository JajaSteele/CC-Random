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

-- Rednet Sender Page
local sender_title_bar = addFill(1,1, width, 1, colors.gray, colors.white, " ")
local sender_title = addText(1,1, "Rednet Forge Sender", colors.white, colors.gray)

local sender_sender_input = addInputBox(2,3, "Sender:", "0", colors.white, colors.black, colors.yellow, colors.black, "%d", 4)
local sender_receiver_input = addInputBox(getPos(sender_sender_input).input_x+5,3, "Receiver:", "0", colors.white, colors.black, colors.yellow, colors.black, "%d", 4)

local sender_message_input = addInputBox(2,5, "Message:", "msg", colors.white, colors.black, colors.yellow, colors.black)
local sender_protocol_input = addInputBox(2,6, "Protocol:", "prc", colors.white, colors.black, colors.yellow, colors.black)

local sender_confirm = addText(2,8, "Send Forged Message", colors.lime, colors.black)
setClickFunc(sender_confirm, function()
    local sender = tonumber(getValue(sender_sender_input, "input"))
    local receiver = tonumber(getValue(sender_receiver_input, "input"))
    local message = getValue(sender_message_input, "input")
    local protocol = getValue(sender_protocol_input, "input")
    sendForgedRednet(receiver, sender, message, protocol)
end)

local pages = {
    rednet_sender = {
        title_bar = sender_title_bar,
        title = sender_title,

        sender_input = sender_sender_input,
        receiver_input = sender_receiver_input,

        sender_message_input = sender_message_input,
        sender_protocol_input = sender_protocol_input,

        sender_confirm = sender_confirm,
    }
}

local current_page = "rednet_sender"

local function changePage(page_name)
    for page,page_data in pairs(pages) do
        if page == page_name then
            for k, element in pairs(page_data) do
                setActive(element, true)
            end
        else
            for k, element in pairs(page_data) do
                setActive(element, false)
            end
        end
    end
    current_page = page_name
    os.queueEvent("ui_redraw")
end

changePage(current_page)

parallel.waitForAll(uiDrawer, clickManager)
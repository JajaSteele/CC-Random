local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

local save = {}

local function loadSave()
    if fs.exists(".controller_save.txt") then
        local file = io.open(".controller_save.txt", "r")
        save = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open(".controller_save.txt", "w")
    file:write(textutils.serialise(save))
    file:close()
end

loadSave()

local width, height = term.getSize()

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

local input_axis = {
    x=0,
    y=0,
    z=0
}

local key_mapping = {
    [keys.w] = {
        on = {
            axis = "x",
            value = 1
        },
        off = {
            axis = "x",
            value = 0
        }
    },
    [keys.s] = {
        on = {
            axis = "x",
            value = -1
        },
        off = {
            axis = "x",
            value = 0
        }
    },
    [keys.d] = {
        on = {
            axis = "z",
            value = 1
        },
        off = {
            axis = "z",
            value = 0
        }
    },
    [keys.a] = {
        on = {
            axis = "z",
            value = -1
        },
        off = {
            axis = "z",
            value = 0
        }
    },
    [keys.space] = {
        on = {
         axis = "y",
            value = 1
        },
        off = {
            axis = "y",
            value = 0
        }
    },
    [keys.leftShift] = {
        on = {
            axis = "y",
            value = -1
        },
        off = {
            axis = "y",
            value = 0
        }
    },
}

if modem then
    rednet.open(peripheral.getName(modem))
end

print("Enter username:")
local user = read(nil, nil, nil, save.user or "")
save.user = user
print("Enter ID:")
local id = tonumber(read(nil, nil, nil, tostring(save.id) or ""))
save.id = id

writeSave()

rednet.send(id, {type="connection", content={user=user}}, "jjs_pnc_ship")

term.clear()

local function inputThread()
    while true do
        local event = {os.pullEvent()}

        if event[1] == "key" and not event[3] then
            local content = key_mapping[event[2]]
            if content and content.on then
                rednet.send(id, {type="axis_input", content=content.on}, "jjs_pnc_ship")
                input_axis[content.on.axis] = content.on.value
                fill(1,1,width,1)
                write(1,1, "Axis: x"..input_axis.x.." y"..input_axis.y.." z"..input_axis.z)
            end
        elseif event[1] == "key_up" then
            local content = key_mapping[event[2]]
            if content and content.off then
                rednet.send(id, {type="axis_input", content=content.off}, "jjs_pnc_ship")
                input_axis[content.off.axis] = content.off.value
                fill(1,1,width,1)
                write(1,1, "Axis: x"..input_axis.x.." y"..input_axis.y.." z"..input_axis.z)
            end
        end
    end
end

parallel.waitForAll(inputThread)
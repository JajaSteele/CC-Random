local interface = peripheral.find("advanced_crystal_interface")

local point_of_origins = {
    "sgjourney:abydos",
    "sgjourney:ankh",
    "sgjourney:apophis",
    "sgjourney:athos",
    "sgjourney:aurum",
    "sgjourney:centauri",
    "sgjourney:chulak",
    "jajasgates:cl_xtreme",
    "sgjourney:coatepec",
    "sgjourney:creeper",
    "sgjourney:dark_star",
    "sgjourney:destiny",
    "moregates:enchant",
    "sgjourney:ender_eye",
    "sgjourney:eye_of_horus",
    "sgjourney:eye_of_ra",
    "sgjourney:gamekeeper",
    "sgjourney:giza",
    "sgjourney:hammer",
    "moregates:icarus",
    "sgjourney:icarus",
    "sgjourney:kaliem",
    "sgjourney:mjolnir",
    "sgjourney:phoenix",
    "sgjourney:pontem",
    "sgjourney:pyramid",
    "sgjourney:reflection",
    "sgjourney:serpent",
    "sgjourney:subido",
    "sgjourney:tauri",
    "sgjourney:terra",
    "sgjourney:triforce",
    "sgjourney:universal",
    "sgjourney:ursa",
    "sgjourney:ursa_major",
    "sgjourney:ursa_minor",
    "sgjourney:wheel",
    "sgjourney:wither",
}
local symbols = {
    "sgjourney:abydos",
    "sgjourney:athos",
    "sgjourney:cavum_tenebrae",
    "sgjourney:centauri",
    "sgjourney:chulak",
    "jajasgates:cl_xtreme",
    "moregates:enchantment",
    "sgjourney:end",
    "sgjourney:galaxy_andromeda",
    "sgjourney:galaxy_ida",
    "sgjourney:galaxy_kaliem",
    "sgjourney:galaxy_milky_way",
    "sgjourney:galaxy_othala",
    "sgjourney:galaxy_pegasus",
    "sgjourney:galaxy_triangulum",
    "sgjourney:lantea",
    "sgjourney:nether",
    "sgjourney:othala",
    "sgjourney:tauri",
    "sgjourney:terra",
    "sgjourney:universal",
    "moregates:universal_custom",
}   

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

local function rsleep(seconds)
    local current_utc = os.epoch("utc")
    local target = current_utc+(seconds*1000)

    repeat
        sleep(0.1)
    until os.epoch("utc") >= target
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

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local position_poo = 1
local position_symbols = 1

local dynamic_symbols = false
interface.dynamicSymbols(dynamic_symbols)

local curr_term = term.current()
local w,h = term.getSize()
local win = window.create(curr_term, 1, 1, w, h)

local length_poo_id = #tostring(#point_of_origins)
local length_symbols_id = #tostring(#symbols)

local y_poo = 2
local y_symbols = 5
local y_dynamic_symbols = 8

local poo_auto = false
local symbols_auto = false

term.redirect(win)

local function drawThread()
    while true do
        os.pullEvent("ui_redraw")
        win.setVisible(false)
        local current_poo = point_of_origins[position_poo]
        local current_symbols = symbols[position_symbols]

        write(1, y_poo, "Point of Origin  \x10", colors.black, (poo_auto and colors.green) or colors.lightGray)
        fill(1,y_poo+1,w,y_poo+1, colors.gray, colors.white, " ")
        write(1, y_poo+1, position_poo, colors.gray, colors.yellow)
        write(length_poo_id+2, y_poo+1, current_poo, colors.gray, colors.white)

        write(1, y_symbols, "Symbols  \x10", colors.black, (symbols_auto and colors.green) or colors.lightGray)
        fill(1,y_symbols+1,w,y_symbols+1, colors.gray, colors.white, " ")
        write(1, y_symbols+1, position_symbols, colors.gray, colors.yellow)
        write(length_symbols_id+2, y_symbols+1, current_symbols, colors.gray, colors.white)

        write(1, y_dynamic_symbols, "Dynamic Symbols", colors.black, colors.lightGray)
        fill(1,y_dynamic_symbols+1,w,y_dynamic_symbols+1, colors.gray, colors.white, " ")
        write(1, y_dynamic_symbols+1, (dynamic_symbols and "Enabled") or "Disabled", colors.gray, (dynamic_symbols and colors.lime) or colors.red)

        win.setVisible(true)
    end
end

local function interactionThread()
    while true do
        local data = {os.pullEvent()}
        if data[1] == "mouse_scroll" then
            local event, dir, x, y = table.unpack(data)
            if y == y_poo+1 then
                position_poo = clamp(position_poo+dir, 1, #point_of_origins)
                interface.overridePointOfOrigin(point_of_origins[position_poo])
            elseif y == y_symbols+1 then
                position_symbols = clamp(position_symbols+dir, 1, #symbols)
                interface.overrideSymbols(symbols[position_symbols])
            elseif y == y_dynamic_symbols+1 then
                dynamic_symbols = not dynamic_symbols
                interface.dynamicSymbols(dynamic_symbols)
            end
            os.queueEvent("ui_redraw")
        elseif data[1] == "mouse_click" then
            local event, button, x, y = table.unpack(data)
            local dir = 0
            if button == 1 then
                dir = 1
            elseif button == 2 then
                dir = -1
            end
            if y == y_poo then
                poo_auto = not poo_auto
                if poo_auto then
                    os.queueEvent("autoscroll_wake")
                end
            elseif y == y_symbols then
                symbols_auto = not symbols_auto
                if symbols_auto then
                    os.queueEvent("autoscroll_wake")
                end
            elseif y == y_poo+1 then
                position_poo = clamp(position_poo+dir, 1, #point_of_origins)
                interface.overridePointOfOrigin(point_of_origins[position_poo])
            elseif y == y_symbols+1 then
                position_symbols = clamp(position_symbols+dir, 1, #symbols)
                interface.overrideSymbols(symbols[position_symbols])
            elseif y == y_dynamic_symbols+1 then
                dynamic_symbols = not dynamic_symbols
                interface.dynamicSymbols(dynamic_symbols)
            end
            os.queueEvent("ui_redraw")
        end
    end
end

local function autoScroll()
    while true do
        rsleep(2)
        if symbols_auto or poo_auto then
            if poo_auto then
                position_poo = clamp(position_poo+1, 1, #point_of_origins)
                interface.overridePointOfOrigin(point_of_origins[position_poo])
                if position_poo == #point_of_origins then
                    poo_auto = false
                end
            end
            if symbols_auto then
                position_symbols = clamp(position_symbols+1, 1, #symbols)
                interface.overrideSymbols(symbols[position_symbols])
                if position_symbols == #symbols then
                    symbols_auto = false
                end
            end
            os.queueEvent("ui_redraw")
        else
            os.pullEvent("autoscroll_wake")
        end
    end
end

os.queueEvent("ui_redraw")
parallel.waitForAny(drawThread, interactionThread, autoScroll)
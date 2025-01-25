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

local args = {...}
local config = {}

if args[1] == "config" or not fs.exists("/.armor_config.txt") then
    print("Welcome to the configuration wizard!")
    print("Enter ID of AM server")
    config.server = tonumber(read())

    local configfile = io.open("/.armor_config.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end
local function loadConfig()
    if fs.exists(".armor_config.txt") then
        local file = io.open(".armor_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open(".armor_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()

local save = {
    ["exampe_preset"] = {
        order = {
            [100] = "",
            [101] = "",
            [102] = "",
            [103] = ""
        }
    }
}

local draw_order = {}

local function reloadDrawOrder()
    local presets = {}
    for k,v in pairs(save) do
        presets[#presets+1] = {name=k}
    end
    table.sort(presets, function(a, b) return a.name < b.name end)
    draw_order = presets
end

local function loadSave()
    if fs.exists(".armor_save.txt") then
        local file = io.open(".armor_save.txt", "r")
        save = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open(".armor_save.txt", "w")
    file:write(textutils.serialise(save))
    file:close()
end

loadSave()

reloadDrawOrder()

local click_map = {}

local scroll = 0
local width, height = term.getSize()

local function inputPrompt(header)
    fill(1,height-3, width, height, colors.black, colors.white)
    term.setCursorPos(3, height-1)
    write(1, height-1, "> ", colors.black, colors.white)
    write(1, height-3, header, colors.black, colors.lightGray)
    local input = read()
    fill(1,height-3, width, height, colors.black, colors.white)
    return input
end

local function displayMessage(display_time, color, line1, line2, line3)
    fill(1,height-3, width, height, colors.black, colors.white)
    write(1, height-2, line1 or "", colors.black, color or colors.white)
    write(1, height-1, line2 or "", colors.black, color or colors.white)
    write(1, height, line3 or "", colors.black, color or colors.white)
    sleep(display_time or 1)
    fill(1,height-3, width, height, colors.black, colors.white)
end

term.setPaletteColor(colors.gray, 0x222222)

local function drawThread()
    term.clear()
    fill(1,1, width,1, colors.lightGray)
    local title = "Armor Manager"
    write(width-#title+1,1, title, colors.lightGray, colors.black)
    while true do
        os.pullEvent("redraw")
        click_map = {}
        for i1=1, height-4 do
            local preset_num = i1+scroll
            local preset = draw_order[preset_num]

            local draw_height = 1+i1
            local bg_color = ((i1%2 == 0 and colors.black) or colors.gray)
            fill(1,draw_height, width, draw_height, bg_color)
            if preset then
                click_map[draw_height] = preset.name
                write(1, draw_height, "- "..preset.name, bg_color, colors.orange)
            end
        end
    end
end

local function clickThread()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        local click_target = click_map[y]

        if click_target then
            if button == 1 then
                local save_data = save[click_target]
                if save_data then
                    local order = save_data.order
                    rednet.send(config.server, order, "jjs_armor_order")
                    local sender, msg, prot = rednet.receive("jjs_armor_confirm", 1)
                    if not msg or sender ~= config.server then
                        displayMessage(1, colors.red, "Request timed out")
                    end
                end
            elseif button == 2 then
                local input = inputPrompt("Confirm Delete? (Y/N)"):lower()
                if input == "yes" or input == "y" or input == "true" then
                    save[click_target] = nil
                    writeSave()
                    reloadDrawOrder()
                    os.queueEvent("redraw")
                end
            end
        end
        if button == 3 then
            rednet.send(config.server, "", "jjs_armor_fetch")
            local sender, msg, prot = rednet.receive("jjs_armor_data", 1)

            if not msg or sender ~= config.server then
                displayMessage(1, colors.red, "Fetching timed out")
            elseif type(msg) == "table" then
                local name = inputPrompt("New preset name:")

                local new_order = {}
                for k,v in pairs(msg) do
                    new_order[#new_order+1] = {slot=k, name=v.name, displayName=v.displayName}
                end
                local new_preset = {
                    order = new_order
                }
                save[name] = new_preset
                writeSave()
                reloadDrawOrder()
                os.queueEvent("redraw")
            end
        end
    end
end

local function scrollThread()
    while true do
        local event, dir, x, y = os.pullEvent("mouse_scroll")
    end
end

os.queueEvent("redraw")
parallel.waitForAll(drawThread, clickThread)
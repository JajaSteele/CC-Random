local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local monitor = peripheral.find("monitor")

monitor.setTextScale(0.5)
local width, height = monitor.getSize()
monitor.clear()
monitor.setCursorPos(1,1)

local button_list = {}

local building_num = 1

monitor.setPaletteColor(colors.black, 0x1f1b19)
monitor.setPaletteColor(colors.white, 0x0e0c0b)

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
    for i2=1, (y1-y)+1 do
        monitor.setCursorPos(x,y+i2-1)
        monitor.write(string.rep(char or " ", (x1-x)+1))
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

for i1=1, height do
    local text = string.format("%02d", building_num)
    monitor.setCursorPos(1,i1)
    monitor.write(text)
    button_list[#button_list+1] = {x=1, y=i1, x2=2, y2=i1, symbol=building_num, glow=true, text=text}
    building_num = building_num+1
end

for i1=1, height do
    local text = string.format("%02d", building_num)
    monitor.setCursorPos(4,i1)
    if i1 ~= 5 and i1 ~= 6 then
        monitor.write(text)
        button_list[#button_list+1] = {x=4, y=i1, x2=5, y2=i1, symbol=building_num, glow=true, text=text}
        building_num = building_num+1
    end
end

local text = "#-#"
monitor.setCursorPos(7, 2)
monitor.write(text)

local text = "1-9"
monitor.setCursorPos(7, height-1)
monitor.write(text)
button_list[#button_list+1] = {x=7, y=height-1, x2=9, y2=height-1, symbol=building_num, glow=true, text=text}
building_num = building_num+1

monitor.setPaletteColor(colors.red, 0x400d0d)
monitor.setPaletteColor(colors.gray, 0x350808)
fill(6, 5, 6+4, height-4,colors.red, colors.gray, "\x7F")
fill(7, 4, 7+2, height-3,colors.red, colors.gray, "\x7F")

button_list[#button_list+1] = {x=6, y=4, x2=6+4, y2=height-3, symbol=0, glow=false, text=""}

for i1=1, height do
    local text = string.format("%02d", building_num)
    monitor.setCursorPos(width-4,i1)
    if i1 ~= 5 and i1 ~= 6 then
        monitor.write(text)
        button_list[#button_list+1] = {x=width-4, y=i1, x2=width-3, y2=i1, symbol=building_num, glow=true, text=text}
        building_num = building_num+1
    end
end

for i1=1, height do
    local text = string.format("%02d", building_num)
    monitor.setCursorPos(width-1,i1)
    monitor.write(text)
    button_list[#button_list+1] = {x=width-1, y=i1, x2=width, y2=i1, symbol=building_num, glow=true, text=text}
    building_num = building_num+1
end

local function inputThread()
    while true do
        local event = {os.pullEvent()}

        if event[1] == "monitor_touch" then
            local _, side, x, y = table.unpack(event)
            for k,v in pairs(button_list) do
                if x >= v.x and x <= v.x2 and y >= v.y and y <= v.y2 then
                    if v.glow then
                        monitor.setCursorPos(v.x, v.y)
                        monitor.setTextColor(colors.orange)
                        monitor.write(v.text)
                        monitor.setTextColor(colors.white)
                    elseif v.symbol == 0 then
                        monitor.setPaletteColor(colors.red, 0xcd3a2d)
                        monitor.setPaletteColor(colors.gray, 0xe66828)
                    end
                    if interface.engageSymbol then
                        interface.engageSymbol(v.symbol)
                    else
                        if (v.symbol-sg.getCurrentSymbol()) % 39 < 19 then
                            sg.rotateAntiClockwise(v.symbol)
                        else
                            sg.rotateClockwise(v.symbol)
                        end
                        
                        repeat
                            sleep()
                        until sg.getCurrentSymbol() == v.symbol
                        sg.openChevron()
                        sg.closeChevron()
                    end
                    break
                end
            end
        end
    end
end

local function resetThread()
    while true do
        local event = {os.pullEvent()}
        if event[1] == "stargate_reset" then
            sleep()
            print("resetting")
            for k,v in pairs(button_list) do
                monitor.setCursorPos(v.x, v.y)
                monitor.setTextColor(colors.white)
                monitor.write(v.text)
                if v.symbol == 0 then
                    monitor.setPaletteColor(colors.red, 0x400d0d)
                    monitor.setPaletteColor(colors.gray, 0x350808)
                end
            end
        end
    end
end

parallel.waitForAny(inputThread,resetThread)
local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local monitor = peripheral.find("monitor")

local function prettyEnergy(energy)
    if energy > 1000000000000 then
        return string.format("%.2f", energy/1000000000000).." TFE"
    elseif energy > 1000000000 then
        return string.format("%.2f", energy/1000000000).." GFE"
    elseif energy > 1000000 then
        return string.format("%.2f", energy/1000000).." MFE"
    elseif energy > 1000 then
        return string.format("%.2f", energy/1000).." kFE"
    else
        return string.format("%.2f", energy).." FE"
    end
end

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

local max_energy

if peripheral.getType(interface) == "basic_interface" then
    max_energy = 0
elseif peripheral.getType(interface) == "crystal_interface" then
    max_energy = 100000000
elseif peripheral.getType(interface) == "advanced_crystal_interface" then
    max_energy = 100000000
end

local width, height = monitor.getSize()

while true do
    local energy = interface.getEnergy()
    if energy > max_energy then
        max_energy = energy
    end

    monitor.clear()
    monitor.setCursorPos(1,1)

    fill(1,1, width,1, colors.black, colors.lightGray, "-")
    fill(1,2, width*(energy/max_energy), height-2, colors.red, colors.red, " ")
    if (width*(energy/max_energy))%1 > 0.5 then
        fill((width*(energy/max_energy))+1,2, (width*(energy/max_energy))+1, height-2, colors.black, colors.red, "\x7F")
    end
    fill(1,height-1, width,height-1, colors.black, colors.lightGray, "-")

    write(1, height, "Energy: "..prettyEnergy(energy).."/"..prettyEnergy(max_energy), colors.black, colors.yellow)

    sleep(0.25)
end
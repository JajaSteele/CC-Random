local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local monitor = peripheral.find("monitor")
local last_address = {}

local button_list = {}

local function findButton(num)
    for k,v in pairs(button_list) do
        if v.symbol == num then
            return v
        end
    end
end

local building_num = 1

local function loadSave()
    if fs.exists("last_address.txt") then
        local file = io.open("last_address.txt", "r")
        last_address = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeSave()
    local file = io.open("last_address.txt", "w")
    file:write(textutils.serialise(last_address))
    file:close()
end

loadSave()

if interface and interface.getConnectedAddress and interface.isStargateConnected() then
    last_address = interface.getConnectedAddress()
    writeSave()
    print("Set last address to: "..table.concat(interface.getConnectedAddress(), " "))
end

if not monitor then
    print("Awaiting Monitor..")
    repeat
        monitor = peripheral.find("monitor")
        sleep(0.25)
    until monitor
    print("Monitor Found!")
end

monitor.setTextScale(0.5)
local width, height = monitor.getSize()
monitor.clear()
monitor.setCursorPos(1,1)
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
button_list[#button_list+1] = {x=7, y=2, x2=9, y2=2, symbol=69, glow=false, text="#-#"}

local text = "1-9"
monitor.setCursorPos(7, height-1)
monitor.write(text)
button_list[#button_list+1] = {x=7, y=height-1, x2=9, y2=height-1, symbol=building_num, glow=true, text=text}
building_num = building_num+1

monitor.setPaletteColor(colors.gray, 0x400d0d)
monitor.setPaletteColor(colors.red, 0x350808)
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
                    if v.symbol == 69 then
                        os.queueEvent("dialAutoStart", last_address)
                        monitor.setCursorPos(v.x, v.y)
                        monitor.setTextColor(colors.blue)
                        monitor.write(v.text)
                        monitor.setTextColor(colors.white)
                        break
                    end
                    if interface.engageSymbol then
                        interface.engageSymbol(v.symbol)
                    else
                        if (v.symbol-interface.getCurrentSymbol()) % 39 < 19 then
                            interface.rotateAntiClockwise(v.symbol)
                        else
                            interface.rotateClockwise(v.symbol)
                        end
                        
                        repeat
                            sleep()
                        until interface.getCurrentSymbol() == v.symbol

                        interface.openChevron()
                        sleep(0.25)
                        interface.closeChevron()
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
        if event[1] == "stargate_reset" or event[1] == "stargate_disconnected" then
            sleep()
            print("resetting")
            for k,v in pairs(button_list) do
                monitor.setCursorPos(v.x, v.y)
                monitor.setTextColor(colors.white)
                monitor.write(v.text)
                if v.symbol == 0 then
                    monitor.setPaletteColor(colors.gray, 0x400d0d)
                    monitor.setPaletteColor(colors.red, 0x350808)
                end
            end
        end
    end
end

local function externalThread()
    while true do
        local event = {os.pullEvent()}
        if event[1] == "stargate_chevron_engaged" then
            local symbol = event[5]
            if symbol then
                print(symbol.." engaged")
                local button = findButton(symbol)
                if button.glow then
                    monitor.setCursorPos(button.x, button.y)
                    monitor.setTextColor(colors.orange)
                    monitor.write(button.text)
                    monitor.setTextColor(colors.white)
                elseif button.symbol == 0 then
                    monitor.setPaletteColor(colors.red, 0xcd3a2d)
                    monitor.setPaletteColor(colors.gray, 0xe66828)
                end
            end
        elseif event[1] == "stargate_incoming_wormhole" or event[1] == "stargate_outgoing_wormhole" then
            monitor.setPaletteColor(colors.red, 0xcd3a2d)
            monitor.setPaletteColor(colors.gray, 0xe66828)
        end
    end
end

local function lastAddressThread()
    while true do
        local event = {os.pullEvent()}
        if (event[1] == "stargate_incoming_wormhole" and (event[2] and event[2] ~= {})) or (event[1] == "stargate_outgoing_wormhole") then
            last_address = event[2]
            writeSave()
            print("Set last address to: "..table.concat(event[2], " "))
        end
    end
end

local function dialAutoThread()
    while true do
        local event, address = os.pullEvent("dialAutoStart")
        if interface.rotateAntiClockwise then
            if (0-interface.getCurrentSymbol()) % 39 < 19 then
                interface.rotateAntiClockwise(0)
            else
                interface.rotateClockwise(0)
            end

            for k,v in ipairs(address) do
                sleep(0.5)
                local button = findButton(v)
                os.queueEvent("monitor_touch", "top", button.x, button.y)
                print(v)
            end

            repeat
                sleep()
            until interface.getCurrentSymbol() == 0

            
            sleep(0.5)
            interface.openChevron()
            sleep(0.5)
            interface.closeChevron()
        else
            for k,v in ipairs(address) do
                sleep(0.5)
                local button = findButton(v)
                os.queueEvent("monitor_touch", "top", button.x, button.y)
                print(v)
            end
            sleep(0.5)
            local brb = findButton(0)
            os.queueEvent("monitor_touch", "top", brb.x, brb.y)
        end
        local button = findButton(69)
        monitor.setCursorPos(button.x, button.y)
        monitor.setTextColor(colors.green)
        monitor.write(button.text)
        monitor.setTextColor(colors.white)
    end
end

local function monitorDetachDetector()
    while true do
        os.pullEvent("peripheral_detach")
        monitor = peripheral.find("monitor")
        if not monitor then
            error("All monitors detached!")
        end
    end
end

if interface.isStargateConnected() and interface.getConnectedAddress then
    last_address = interface.getConnectedAddress()
    writeSave()
    print("Set last address to: "..table.concat(interface.getConnectedAddress(), " "))
end

print("Last Address is: "..table.concat(last_address, " "))

parallel.waitForAny(inputThread,resetThread, lastAddressThread, dialAutoThread, externalThread, monitorDetachDetector)
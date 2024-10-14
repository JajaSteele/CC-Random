local script_version = "1.4"

-- AUTO UPDATE STUFF
local curr_script = shell.getRunningProgram()
local script_io = io.open(curr_script, "r")
local local_version_line = script_io:read()
script_io:close()

local function getVersionNumbers(first_line)
    local major, minor, patch = first_line:match("local script_version = \"(%d+)%.(%d+)\"")
    return {tonumber(major) or 0, tonumber(minor) or 0}
end

local local_version = getVersionNumbers(local_version_line)

print("Local Version: "..string.format("%d.%d", table.unpack(local_version)))

local update_source = "https://raw.githubusercontent.com/JajaSteele/CC-Random/main/SGJourney/world_dhd.lua"
local update_request = http.get(update_source)
if update_request then
    local script_version_line = update_request.readLine()
    update_request:close()
    local script_version = getVersionNumbers(script_version_line)
    print("Remote Version: "..string.format("%d.%d", table.unpack(script_version)))

    if script_version[1] > local_version[1] or (script_version[1] == local_version[1] and script_version[2] > local_version[2]) then
        print("Remote version is newer, updating local")
        sleep(0.5)
        local full_update_request = http.get(update_source)
        if full_update_request then
            local full_script = full_update_request.readAll()
            full_update_request:close()
            local local_io = io.open(curr_script, "w")
            local_io:write(full_script)
            local_io:close()
            print("Updated local script!")
            sleep(0.5)
            print("REBOOTING")
            sleep(0.5)
            os.reboot()
        else
            print("Full update request failed")
        end
    end
else
    print("Update request failed")
end
-- END OF AUTO UPDATE

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local monitor = peripheral.find("monitor")
local last_address = {}

local button_list = {}

settings.load()

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

settings.define("dhd.brb.main_off", {
    description = "Main color for the dark big button",
    default = 0x350808,
    type = "number"
})
settings.define("dhd.brb.secondary_off", {
    description = "Secondary color for the dark big button",
    default = 0x400d0d,
    type = "number"
})

settings.define("dhd.brb.main_on", {
    description = "Main color for the bright big button",
    default = 0xcd3a2d,
    type = "number"
})
settings.define("dhd.brb.secondary_on", {
    description = "Secondary color for the bright big button",
    default = 0xe66828,
    type = "number"
})

settings.define("dhd.panel.button_on", {
    description = "Color for turned on buttons",
    default = 0xf2b233,
    type = "number"
})
settings.define("dhd.panel.button_off", {
    description = "Color for turned off buttons",
    default = 0x0e0c0b,
    type = "number"
})
settings.define("dhd.panel.background", {
    description = "Color for the background",
    default = 0x2f2b29,
    type = "number"
})

local args = {...}

local default_palettes = {
    milky_way = {
        brb_main_off = 0x350808,
        brb_secondary_off = 0x400d0d,
        brb_main_on = 0xcd3a2d,
        brb_secondary_on = 0xe66828,
        button_on = 0xf2b233,
        button_off = 0x0e0c0b,
        background = 0x2f2b29,
    },
    pegasus = {
        brb_main_off = 0x061132,
        brb_secondary_off = 0x0d103f,
        brb_main_on = 0x28c0e6,
        brb_secondary_on = 0x28e6e3,
        button_on = 0x33adff,
        button_off = 0x060609,
        background = 0x2b2b2c,
    },
    high_contrast = {
        brb_main_off = 0x606060,
        brb_secondary_off = 0x707070,
        brb_main_on = 0xFFFFFF,
        brb_secondary_on = 0xFFFFFF,
        button_on = 0xFFFFFF,
        button_off = 0x404040,
        background = 0x060609,
    },
    nether = {
        brb_main_off = 0x5d280e,
        brb_secondary_off = 0x7e3815,
        brb_main_on = 0xe4943f,
        brb_secondary_on = 0xf2b26e,
        button_on = 0xff2414,
        button_off = 0x521814,
        background = 0x100000,
    },
    sculk = {
        brb_main_off = 0x0f252c,
        brb_secondary_off = 0x0d303b,
        brb_main_on = 0x13c191,
        brb_secondary_on = 0x19e1b2,
        button_on = 0x19e1b2,
        button_off = 0x173a45,
        background = 0x030c0f,
    },
    ivory = {
        brb_main_off = 0x441908,
        brb_secondary_off = 0x561b0b,
        brb_main_on = 0xdd7f13,
        brb_secondary_on = 0xe4a70c,
        button_on = 0xe67e00,
        button_off = 0x321d11,
        background = 0xded1b0,
    }
}

local palette_list = {}
for k,v in pairs(default_palettes) do
    palette_list[#palette_list+1] = k
end

local curr_program = shell.getRunningProgram()
if not shell.getCompletionInfo()[curr_program] then
    local completion = require "cc.shell.completion"
    local complete = completion.build({ completion.choice, palette_list })
    shell.setCompletionFunction(curr_program, complete)
    print("Shell Completion built!")
    sleep(0.5)
end

if args[1] and default_palettes[args[1]] then
    print("Setting palette to "..args[1])
    local palette = default_palettes[args[1]]

    settings.set("dhd.brb.main_off", palette.brb_main_off)
    settings.set("dhd.brb.secondary_off", palette.brb_secondary_off)
    
    settings.set("dhd.brb.main_on", palette.brb_main_on)
    settings.set("dhd.brb.secondary_on", palette.brb_secondary_on)

    settings.set("dhd.panel.button_on", palette.button_on)
    settings.set("dhd.panel.button_off", palette.button_off)
    settings.set("dhd.panel.background", palette.background)

    settings.save()
    sleep(0)
    settings.load()
end

local brb_main_off = (settings.get("dhd.brb.main_off"))
local brb_secondary_off = (settings.get("dhd.brb.secondary_off"))

local brb_main_on = (settings.get("dhd.brb.main_on"))
local brb_secondary_on = (settings.get("dhd.brb.secondary_on"))

local button_on = settings.get("dhd.panel.button_on")
local button_off = settings.get("dhd.panel.button_off")
local background = settings.get("dhd.panel.background")

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
monitor.setPaletteColor(colors.black, background)
monitor.setPaletteColor(colors.white, button_off)
monitor.setPaletteColor(colors.orange, button_on)

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

if height == 24 then
    print("Detected monitor size is 24 characters tall! Starting in Cursed Mode (1-47)")
    for i1=1, height do
        if building_num < 48 then
            local text = string.format("%02d", building_num)
            monitor.setCursorPos(1,i1)
            monitor.write(text)
            button_list[#button_list+1] = {x=1, y=i1, x2=2, y2=i1, symbol=building_num, glow=true, text=text}
            building_num = building_num+1
        end
    end
    
    monitor.setPaletteColor(colors.gray, brb_secondary_off)
    monitor.setPaletteColor(colors.red, brb_main_off)
    fill(6, 5, 6+4, height-4,colors.red, colors.gray, "\x7F")
    fill(7, 4, 7+2, height-3,colors.red, colors.gray, "\x7F")
    
    button_list[#button_list+1] = {x=6, y=4, x2=6+4, y2=height-3, symbol=0, glow=false, text=""}

    for i1=1, height do
        if building_num < 49 then
            if building_num == 48 then
                local text = string.format("%02d", 69)
                monitor.setCursorPos(width-1,i1)
                monitor.write(text)
                button_list[#button_list+1] = {x=width-1, y=i1, x2=width, y2=i1, symbol=69, glow=true, text="69"}
            else
                local text = string.format("%02d", building_num)
                monitor.setCursorPos(width-1,i1)
                monitor.write(text)
                button_list[#button_list+1] = {x=width-1, y=i1, x2=width, y2=i1, symbol=building_num, glow=true, text=text}
                building_num = building_num+1
            end
        end
    end

    local text = "X-X"
    monitor.setCursorPos(7, 2)
    monitor.write(text)
    button_list[#button_list+1] = {x=7, y=2, x2=9, y2=2, symbol=71, glow=true, text="X-X"}

    if interface.getIrisProgressPercentage then
        local text = "@-@"
        monitor.setCursorPos(7, height-1)
        monitor.write(text)
        button_list[#button_list+1] = {x=7, y=height-1, x2=9, y2=height-1, symbol=70, glow=false, text="@-@"}
    end
else
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

    local text = "1-9"
    monitor.setCursorPos(7, 1)
    monitor.write(text)
    button_list[#button_list+1] = {x=7, y=1, x2=9, y2=1, symbol=building_num, glow=true, text=text}
    building_num = building_num+1

    local text = "2-0"
    monitor.setCursorPos(7, 2)
    monitor.write(text)
    button_list[#button_list+1] = {x=7, y=2, x2=9, y2=2, symbol=building_num, glow=true, text=text}
    building_num = building_num+1

    local text = "x-x"
    monitor.setCursorPos(7, height-2)
    monitor.write(text)
    button_list[#button_list+1] = {x=7, y=height-2, x2=9, y2=height-2, symbol=71, glow=true, text="x-x"}

    local text = "#-#"
    monitor.setCursorPos(7, height-1)
    monitor.write(text)
    button_list[#button_list+1] = {x=7, y=height-1, x2=9, y2=height-1, symbol=69, glow=false, text="#-#"}

    if interface.getIrisProgressPercentage then
        local text = "@-@"
        monitor.setCursorPos(7, height)
        monitor.write(text)
        button_list[#button_list+1] = {x=7, y=height, x2=9, y2=height, symbol=70, glow=false, text="@-@"}
    end

    monitor.setPaletteColor(colors.gray, brb_secondary_off)
    monitor.setPaletteColor(colors.red, brb_main_off)
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
end

local iris_state = "idle"

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
                        monitor.setPaletteColor(colors.red, brb_main_on)
                        monitor.setPaletteColor(colors.gray, brb_secondary_on)
                    end
                    if v.symbol == 69 then
                        os.queueEvent("dialAutoStart", last_address)
                        monitor.setCursorPos(v.x, v.y)
                        monitor.setTextColor(colors.blue)
                        monitor.write(v.text)
                        monitor.setTextColor(colors.white)
                        break
                    end
                    if v.symbol == 70 then
                        monitor.setCursorPos(v.x, v.y)
                        monitor.setTextColor(colors.orange)
                        if interface.getIrisProgressPercentage then
                            if interface.getIrisProgressPercentage() > 50 then
                                interface.openIris()
                                monitor.write("<->")
                                iris_state = "opening"
                            else
                                interface.closeIris()
                                monitor.write(">-<")
                                iris_state = "closing"
                            end
                            os.queueEvent("irisAwait", v.x, v.y, v.text)
                        end
                        break
                    end
                    if v.symbol == 71 then
                        monitor.setCursorPos(v.x, v.y)
                        monitor.setTextColor(colors.orange)
                        monitor.write(v.text)
                        sleep(0.25)
                        interface.disconnectStargate()
                        sleep(0.25)
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
                    monitor.setPaletteColor(colors.gray, brb_secondary_off)
                    monitor.setPaletteColor(colors.red, brb_main_off)
                end
                if v.symbol == 70 then
                    if iris_state == "idle" then
                        monitor.setCursorPos(v.x, v.y)
                        monitor.setTextColor(colors.white)
                        monitor.write(v.text)
                    elseif iris_state == "opening" then
                        monitor.setCursorPos(v.x, v.y)
                        monitor.setTextColor(colors.orange)
                        monitor.write("<->")
                    elseif iris_state == "closing" then
                        monitor.setCursorPos(v.x, v.y)
                        monitor.setTextColor(colors.orange)
                        monitor.write(">-<")
                    end
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
                    monitor.setPaletteColor(colors.red, brb_main_on)
                    monitor.setPaletteColor(colors.gray, brb_secondary_on)
                end
            end
        elseif event[1] == "stargate_incoming_wormhole" or event[1] == "stargate_outgoing_wormhole" then
            monitor.setPaletteColor(colors.red, brb_main_on)
            monitor.setPaletteColor(colors.gray, brb_secondary_on)
        end
    end
end

local function lastAddressThread()
    while true do
        local event = {os.pullEvent()}
        if (event[1] == "stargate_incoming_wormhole" and (event[2] and event[2] ~= {})) or (event[1] == "stargate_outgoing_wormhole") then
            last_address = event[2]
            if event[1] == "stargate_incoming_wormhole" then
                repeat
                    sleep(0.5)
                until interface.getOpenTime() > 2 or not interface.isStargateConnected()
                last_address = interface.getConnectedAddress()
            end
            writeSave()
            print("Set last address to: "..table.concat(last_address, " "))
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

local function irisDetectThread()
    while true do
        local event, x, y, txt = os.pullEvent("irisAwait")
        repeat
            sleep(0.1)
            local iris = interface.getIrisProgressPercentage()
        until iris == 100 or iris == 0
        monitor.setTextColor(colors.white)
        monitor.setCursorPos(x, y)
        monitor.write(txt)
        iris_state = "idle"
    end
end

if interface.isStargateConnected() and interface.getConnectedAddress then
    last_address = interface.getConnectedAddress()
    writeSave()
    print("Set last address to: "..table.concat(interface.getConnectedAddress(), " "))
end

print("Last Address is: "..table.concat(last_address, " "))

parallel.waitForAny(inputThread,resetThread, lastAddressThread, dialAutoThread, externalThread, monitorDetachDetector, irisDetectThread)
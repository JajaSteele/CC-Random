local base_storage = peripheral.wrap("top")
local disk_drive = peripheral.wrap("bottom")

local shulker_placer = peripheral.wrap("left")
local shulker_filler = peripheral.wrap("right")

local computer_init = peripheral.wrap("back")

local monitor = peripheral.find("monitor")

local rsi = peripheral.find("redstoneIntegrator")

if monitor then
    term.redirect(monitor)
end

local w,h = monitor.getSize()

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

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char)
    local old_bg = monitor.getBackgroundColor()
    local old_fg = monitor.getTextColor()
    local old_posx,old_posy = monitor.getCursorPos()
    if bg then
        monitor.setBackgroundColor(bg)
    end
    if fg then
        monitor.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                monitor.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    monitor.write()
                else
                    monitor.write(char or " ")
                end
            end
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

local function findItemCount(inv, name)
    local count = 0
    if inv and inv.list then
        local list = inv.list()
        if not list then
            return nil
        end
        for k,v in pairs(list) do
            if v.name:match(name:lower()) then
                count = count+1
            end
        end
    end
    if count == 0 then
        return nil
    else
        return count
    end
end


local function findItem(inv, name)
    local multi_found = {}
    if inv and inv.list then
        local list = inv.list()
        if not list then
            return nil
        end
        for k,v in pairs(list) do
            if v.name:match(name:lower()) then
                multi_found[#multi_found+1] = {
                    count=v.count,
                    name=v.name,
                    slot=k
                }
            end
        end
    end
    if #multi_found > 1 then
        return multi_found[1], multi_found
    else
        return multi_found[1]
    end
end

local safemove = {
    pushItems = function(from, to, slot_in, target_count, slot_out)
        local transfer_count = 0
        local failed_attempts = 0
        repeat
            if from and to then
                if failed_attempts > 4 then
                    return transfer_count, false
                end
                local num = from["pushItems"](peripheral.getName(to), slot_in, target_count-transfer_count, slot_out)
                if num == 0 then
                    failed_attempts = failed_attempts+1
                    sleep(0.5)
                else
                    transfer_count = transfer_count+num
                end
            else
                return false
            end
        until transfer_count >= target_count
        return transfer_count
    end,
    pullItems = function(to, from, slot_in, target_count, slot_out)
        local transfer_count = 0
        local failed_attempts = 0
        repeat
            if from and to then
                if failed_attempts > 4 then
                    return transfer_count, false
                end
                local num = to["pullItems"](peripheral.getName(from), slot_out, target_count-transfer_count, slot_in)
                if num == 0 then
                    failed_attempts = failed_attempts+1
                    sleep(0.5)
                else
                    transfer_count = transfer_count+num
                end
            else
                return false
            end
        until transfer_count >= target_count
        return transfer_count
    end
}

local side_list = {
    "back",
    "front",
    "top",
    "bottom",
    "left",
    "right"
}

local is_filling = false

local function redstoneThread()
    local redstone_status = false
    while true do
        os.pullEvent("redstone")
        local new_status = false
        for k,side in pairs(side_list) do
            local signal = redstone.getInput(side)
            if signal then
                new_status = true
                break
            end
        end

        if redstone_status == false and new_status == true then
            os.queueEvent("redstone_update", true)
        elseif redstone_status == true and new_status == false then
            os.queueEvent("redstone_update", false)
        end
        redstone_status = new_status
    end
end

local startup_program = ([[
    print("Starting Program '&p' in ]]..(0.5)..[[s")
    sleep(]]..(0.5)..[[)
    shell.execute("&p")
]])

local function clearMonitor(middle_txt)
    fill(1,1,w,h, colors.black, colors.white, " ")
    
    fill(1,1, w,1, colors.black, colors.white, "-")
    fill(1,h, w,h, colors.black, colors.white, "-")

    fill(1,1, 1,h, colors.black, colors.white, "|")
    fill(w,1, w,h, colors.black, colors.white, "|")

    write(1,1, "@", colors.black, colors.lightBlue)
    write(w,1, "@", colors.black, colors.lightBlue)
    write(w,h, "@", colors.black, colors.lightBlue)
    write(1,h, "@", colors.black, colors.lightBlue)

    if middle_txt then
        if type(middle_txt) == "table" then
            local start_y = math.ceil(h/2)-(#middle_txt/2)
            for k,v in ipairs(middle_txt) do
                local x = math.ceil(w/2)-math.ceil(#v/2)
                local y = start_y+k
                write(x, y, v, colors.black, colors.blue)
            end 
        elseif type(middle_txt) == "string" then
            local x = math.ceil(w/2)-math.ceil(#middle_txt/2)
            write(x, math.floor(h/2), middle_txt, colors.black, colors.blue)
        end
    end
end

local function mainThread()
    while true do
        clearMonitor({"Gate Kit", "Manager"})
        local event, signal = os.pullEvent("redstone_update")
        if signal == true then
            is_filling = true
            local modem = findItem(base_storage, "wireless_modem_advanced")
            local computer = findItem(base_storage, "computer_advanced")
            local pocket = findItem(base_storage, "pocket_computer_advanced")
            local interface = findItem(base_storage, "advanced_crystal_interface")
            local dhd = findItem(base_storage, "milky_way_dhd")
            local shulker = findItem(base_storage, "shulker_box")

            local cookies = findItem(base_storage, "cookie")

            local energy_crystal = findItem(base_storage, "sgjourney:energy_crystal")
            local ctrl_crystal = findItem(base_storage, "sgjourney:large_control_crystal")
            
            if modem and computer and pocket and interface and dhd and shulker and energy_crystal and ctrl_crystal and energy_crystal.count >= 4 then
                term.clear()
                term.setCursorPos(1,1)
                print("Starting Kit Setup..")
                base_storage.pushItems(peripheral.getName(shulker_placer), shulker.slot, 1)
                print("Placing Shulker")
                sleep(0.5)
                print("Preparing computers")
                print("1/2 Preparing dialer computer")
                base_storage.pushItems(peripheral.getName(computer_init), computer.slot, 1)
                sleep(0.5)
                computer_init.pushItems(peripheral.getName(disk_drive), 1, 1)
                print("Copying Easydial..")
                local dial_disk_mount = disk_drive.getMountPath()
                local easydial_file = io.open("easydial_NOSPIN.lua", "r")
                local easydial = easydial_file:read("*a")
                easydial_file:close()

                print("Pasting Easydial..")
                local easydial_local = io.open(dial_disk_mount.."/easydial_NOSPIN.lua", "w")
                easydial_local:write(easydial)
                easydial_local:close()

                print("Writing Startup..")
                local startup = startup_program:gsub("&p", "easydial_NOSPIN.lua")
                local dial_startup_file = io.open(dial_disk_mount.."/startup.lua", "w")
                dial_startup_file:write(startup)
                dial_startup_file:close()

                shulker_filler.pullItems(peripheral.getName(disk_drive), 1, 1)
                print("2/2 Preparing address book pocket")

                base_storage.pushItems(peripheral.getName(computer_init), pocket.slot, 1)
                sleep(0.5)
                computer_init.pushItems(peripheral.getName(disk_drive), 1, 1)



                print("Copying Address Book..")
                local address_disk_mount = disk_drive.getMountPath()
                local addressbook_file = io.open("address_book.lua", "r")
                local addressbook = addressbook_file:read("*a")
                addressbook_file:close()

                print("Pasting Address Book..")
                local addressbook_local = io.open(dial_disk_mount.."/address_book.lua", "w")
                addressbook_local:write(addressbook)
                addressbook_local:close()



                print("Writing Startup..")
                local startup = startup_program:gsub("&p", "address_book.lua")
                local dial_startup_file = io.open(address_disk_mount.."/startup.lua", "w")
                dial_startup_file:write(startup)
                dial_startup_file:close()



                print("Copying Base Addresses..")
                local addresslist_disk_mount = disk_drive.getMountPath()
                local addresslist_file = io.open("saved_address.txt", "r")
                local addresslist = addresslist_file:read("*a")
                addresslist_file:close()

                print("Pasting Base Addresses..")
                local addresslist_local = io.open(dial_disk_mount.."/saved_address.txt", "w")
                addresslist_local:write(addresslist)
                addresslist_local:close()



                print("Copying Base Config..")
                local addressconfig_disk_mount = disk_drive.getMountPath()
                local addressconfig_file = io.open("saved_config.txt", "r")
                local addressconfig = addressconfig_file:read("*a")
                addressconfig_file:close()

                print("Pasting Base Config..")
                local addressconfig_local = io.open(dial_disk_mount.."/saved_config.txt", "w")
                addressconfig_local:write(addressconfig)
                addressconfig_local:close()



                shulker_filler.pullItems(peripheral.getName(disk_drive), 1, 1)

                print("Pushing rest of items..")
                print("Modem: ", safemove.pushItems(base_storage, shulker_filler, modem.slot, 1))
                print("Interface: ", safemove.pushItems(base_storage, shulker_filler, interface.slot, 1))
                print("DHD: ", safemove.pushItems(base_storage, shulker_filler, dhd.slot, 1))
                print("Control Crystal: ", safemove.pushItems(base_storage, shulker_filler, ctrl_crystal.slot, 1))
                print("Energy Crystal: ", safemove.pushItems(base_storage, shulker_filler, energy_crystal.slot, 4))
                if cookies then
                    print("Cookies: ", safemove.pushItems(base_storage, shulker_filler, cookies.slot, 32))
                end
                is_filling = false

                rsi.setOutput("front", true)
                sleep(1)
                rsi.setOutput("front", false)

                clearMonitor({"SUCCESS", "Gate Kit", "Assembled"})
                sleep(1)
            else
                term.clear()
                term.setCursorPos(1,1)
                clearMonitor({"ERROR", "Not enough items!"})
                sleep(4)
            end
        end
    end
end

parallel.waitForAny(redstoneThread, mainThread)
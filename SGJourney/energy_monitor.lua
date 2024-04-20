local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local monitors = {peripheral.find("monitor")}
local windows = {}

for k,monitor in pairs(monitors) do
    local width, height = monitor.getSize()
    windows[#windows+1] = window.create(monitor, 1, 1, width, height)
end

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

local function disp_time(time)
  local days = math.floor(time/86400)
  local hours = math.floor((time % 86400)/3600)
  local minutes = math.floor((time % 3600)/60)
  local seconds = math.floor((time % 60))
  return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
end


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


local max_energy
local eta
local last_energy = 0

local energy_delta = {}

if peripheral.getType(interface) == "basic_interface" then
    max_energy = 0
elseif peripheral.getType(interface) == "crystal_interface" then
    max_energy = 100000000
elseif peripheral.getType(interface) == "advanced_crystal_interface" then
    max_energy = 1000000000
end

local mode = 0
local timer = 0

local pause_timer = 0

local manual_switch = 0


local function mainThread()
    while true do
        if timer > 4 then
            timer = 0
            if mode > 0 then
                mode = 0
                if peripheral.getType(interface) == "basic_interface" then
                    max_energy = 0
                elseif peripheral.getType(interface) == "crystal_interface" then
                    max_energy = 100000000
                elseif peripheral.getType(interface) == "advanced_crystal_interface" then
                    max_energy = 1000000000
                end
            else
                mode = mode+1
                max_energy = interface.getEnergyTarget()
            end
        end
        if mode == 0 then
            energy_delta[mode] = (interface.getEnergy()-last_energy)
        elseif mode == 1 then
            energy_delta[mode] = (interface.getStargateEnergy()-last_energy)
        end
        for k,win in pairs(windows) do
            local width, height = win.getSize()
            term.redirect(win)

            win.setVisible(false)
            if mode == 0 then
                local energy = interface.getEnergy()
                last_energy = energy
                if energy > max_energy then
                    max_energy = energy
                end

                eta = ((max_energy-energy)/(energy_delta[mode]*4))

                win.clear()
                win.setCursorPos(1,1)

                fill(1,1, width,1, colors.black, colors.lightGray, "-")
                fill(1,2, width*clamp(energy/max_energy, 0, 1), height-2, colors.red, colors.red, " ")
                if (width*(energy/max_energy))%1 > 0.5 then
                    fill((width*(energy/max_energy))+1,2, (width*(energy/max_energy))+1, height-2, colors.black, colors.red, "\x7F")
                end
                fill(1,height-1, width,height-1, colors.black, colors.lightGray, "-")

                if eta > 0 then
                    write(1, height, "Interface : "..prettyEnergy(energy).."/"..prettyEnergy(max_energy).." ETA: "..disp_time(clamp(eta,0,720000)), colors.black, colors.cyan)
                else
                    write(1, height, "Interface : "..prettyEnergy(energy).."/"..prettyEnergy(max_energy), colors.black, colors.cyan)
                end
            elseif mode == 1 then
                local energy = interface.getStargateEnergy()
                last_energy = energy

                eta = ((max_energy-energy)/(energy_delta[mode]*4))

                win.clear()
                win.setCursorPos(1,1)

                fill(1,1, width,1, colors.black, colors.lightGray, "-")
                fill(1,2, width*clamp(energy/max_energy, 0, 1), height-2, colors.red, colors.red, " ")
                if (width*(energy/max_energy))%1 > 0.5 then
                    fill((width*(energy/max_energy))+1,2, (width*(energy/max_energy))+1, height-2, colors.black, colors.red, "\x7F")
                end
                fill(1,height-1, width,height-1, colors.black, colors.lightGray, "-")

                if eta > 0 then
                    write(1, height, "Stargate : "..prettyEnergy(energy).."/"..prettyEnergy(max_energy).." ETA: "..disp_time(clamp(eta,0,720000)), colors.black, colors.lime)
                else
                    write(1, height, "Stargate : "..prettyEnergy(energy).."/"..prettyEnergy(max_energy), colors.black, colors.lime)
                end
            end
            sleep()
            
            fill(1,1, width*clamp(timer/4, 0, 1), 1, colors.black, colors.lightBlue, "-")
            fill(1,height-1, width*clamp(timer/4, 0, 1), height-1, colors.black, colors.lightBlue, "-")
            if pause_timer > 0 then
                write(1, 1, "Locked for : "..pause_timer.."s", colors.black, colors.lightBlue)
            else
                if mode == 1 and interface.getStargateEnergy() < interface.getEnergyTarget() then
                    timer = 0
                    max_energy = interface.getEnergyTarget()
                    
                    write(1, 1, "Locked until gate is charged", colors.black, colors.lightBlue)
                end
            end
            win.setVisible(true)
        end
        if pause_timer <= 0 then
            timer = timer+0.5
        else
            pause_timer = clamp(pause_timer-0.5, 0, pause_timer)
        end
        sleep(0.5)
    end
end

local function touchThread()
    while true do
        local event = os.pullEvent("monitor_touch")
        timer = 4.5
        manual_switch = manual_switch+1
        if manual_switch > 2 then
            manual_switch = 0
            pause_timer = 0
        else
            pause_timer = 120
        end
    end
end

local stat, err = pcall(function()
    parallel.waitForAny(mainThread, touchThread)
end)

if not stat then
    term.redirect(term.native())
    error(err)
    sleep(1)
    os.reboot()
end
local monitor = peripheral.find("monitor")
local core = peripheral.find("draconic_rf_storage")

local win = window.create(monitor, 1, 1, monitor.getSize())
local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function prettyEnergy(energy)
    if energy > 1000000000000000 then
        return string.format("%.2f", energy/1000000000000000).." PFE"
    elseif energy > 1000000000000 then
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

local function prettyETA(time)

    time = clamp(time, 0, 31622400*512)

    local seconds = time%60
    local minutes = math.floor(time/60)%60
    local hours = math.floor(time/3600)%24
    local days = math.floor(time/86400)%30
    local months = math.floor(time/2635200)%12
    local years = math.floor(time/31622400)

    local output = ""

    if years >= 1 then
        output = string.format("%dy %dM %dd %dh %dm %ds", years, months, days, hours, minutes, seconds)
    elseif months >= 1 then
        output = string.format("%dM %dd %dh %dm %ds", months, days, hours, minutes, seconds)
    elseif days >= 1 then
        output = string.format("%dd %dh %dm %ds", days, hours, minutes, seconds)
    elseif hours >= 1 then
        output = string.format("%dh %dm %ds", hours, minutes, seconds)
    elseif minutes >=1 then
        output = string.format("%dm %ds", minutes, seconds)
    else
        output = string.format("%ds", seconds)
    end

    return output
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

local function sum(x)
    local s = 0
    for _, v in pairs(x) do s = s + v end
    return s
  end
  
  function math.log10(x)
      return math.log(x) / math.log(10)
  end
  
  local function midrange_mean(x)
    local sump = 0
    return 0.5 * (math.min(table.unpack(x)) + math.max(table.unpack(x)))
  end
  
  local function energetic_mean(x)
    local s = 0
    for _,v in ipairs(x) do s = s + (10 ^ (v / 10)) end
    return 10 * math.log10((1 / #x) * s)
  end
  
  local function weighted_mean(x, w)
    local sump = 0
    for i, v in ipairs (x) do sump = sump + (v * w[i]) end
    return sump / sum(w)
  end

local og_term = term.current()
term.clear()
term.redirect(win)

local width, height = term.getSize()
local input = 0
local output = 0
local energy = core.getEnergyStored()
local energy_max = core.getMaxEnergyStored()
local delta = 0
local eta_seconds = 0

local eta_history = {}
local eta_weight = {}

local empty_eta_seconds = 0

local empty_eta_history = {}
local empty_eta_weight = {}

local await = 5

local function drawThread()
    while true do
        win.setVisible(false)
        os.pullEvent("drawMonitor")
        term.clear()

        write(1,1, prettyEnergy(energy), colors.black, colors.lightGray)

        write(1,2, "[", colors.black, colors.white)
        write(width,2, "]", colors.black, colors.white)

        fill(2,2, 2+((width-2)*energy/energy_max), 2, colors.red, colors.orange, "\x7F")

        local input_text = prettyEnergy(input).."/t"
        local output_text = prettyEnergy(output).."/t"

        write(2,4, input_text, colors.black, colors.lime)
        write(width-#output_text,4, output_text, colors.black, colors.red)

        if eta_seconds > 0 then
            local delta_text = "ETA: "..prettyETA(eta_seconds)
            write(((width/2)-(#delta_text/2))+1, 5, delta_text, colors.black, colors.lightGray)
        else
            local delta_text = "ETA: "..prettyETA(empty_eta_seconds)
            write(((width/2)-(#delta_text/2))+1, 5, delta_text, colors.black, colors.red)
        end
        if await > 0 then
            local delta_text = "Loading Up.. "..string.format("%.1f%%", ((5-await)/5)*100)
            write(((width/2)-(#delta_text/2))+1, 5, delta_text, colors.black, colors.lightGray)
        end
        win.setVisible(true)
    end
end

local function logicThread()
    local old = core.getEnergyStored()
    local new = core.getEnergyStored()
    local highest = 0
    local empty_highest = 0
    while true do
        old = new
        new = core.getEnergyStored()

        input = core.getInputPerTick()
        output = core.getOutputPerTick()
        energy = core.getEnergyStored()
        energy_max = core.getMaxEnergyStored()

        delta = (new-old)
        if delta > highest then
            highest = delta
        end
        if delta < empty_highest then
            empty_highest = delta
        end
        
        if await > 0 then
            await = await-1
        else
            if delta > 0 then
                eta_seconds = (energy_max-energy)/delta
                table.insert(eta_history, 1, eta_seconds)
                table.insert(eta_weight, 1, 1)
                if #eta_history > 60 then
                    table.remove(eta_history, 61)
                    table.remove(eta_weight, 61)
                end
                eta_seconds = weighted_mean(eta_history, eta_weight)
                write(1,1, "filling eta: "..eta_seconds, colors.black, colors.orange, og_term)
                write(1,2, "samples: "..#eta_history, colors.black, colors.orange, og_term)
            else
                eta_seconds = -1
                empty_eta_seconds = energy/math.abs(delta)
                table.insert(empty_eta_history, 1, empty_eta_seconds)
                table.insert(empty_eta_weight, 1, 1)
                if #empty_eta_history > 60 then
                    table.remove(empty_eta_history, 61)
                    table.remove(empty_eta_weight, 61)
                end
                empty_eta_seconds = weighted_mean(empty_eta_history, empty_eta_weight)
                write(1,1, "empty eta: "..eta_seconds, colors.black, colors.orange, og_term)
                write(1,2, "samples: "..#eta_history, colors.black, colors.orange, og_term)
            end
        end

        os.queueEvent("drawMonitor")
        sleep(1)
    end
end

local stat, err = pcall(function()
    parallel.waitForAny(logicThread,drawThread)
end)
term.redirect(og_term)

if not stat then
    error(err)
end

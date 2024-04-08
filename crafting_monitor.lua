local bridge = peripheral.find("meBridge")

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function disp_time(time)
    local days = math.floor(time/86400)
    local hours = math.floor((time % 86400)/3600)
    local minutes = math.floor((time % 3600)/60)
    local seconds = math.floor((time % 60))
    return string.format("%d:%02d:%02d:%02d",days,hours,minutes,seconds)
end

local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)

local mon_win = window.create(monitor, 1,1, monitor.getSize())

while true do
    mon_win.setVisible(false)
    mon_win.clear()
    mon_win.setCursorPos(1,1)
    mon_win.setTextColor(colors.yellow)
    mon_win.write("-= ME Crafting Monitor =-")
    for k,v in ipairs(bridge.getCraftingCPUs()) do
        if v.isBusy and v.craftingJob then
            mon_win.setTextColor(colors.lime)
        else
            mon_win.setTextColor(colors.red)
        end
        mon_win.setCursorPos(1,(k*2))
        mon_win.write("CPU-"..(k-1)..string.format(" (%.0fk)", v.storage/1000))

        if v.isBusy and v.craftingJob then
            mon_win.setTextColor(colors.yellow)
            mon_win.write(" - Elapsed Time: "..disp_time(v.craftingJob.elapsedTimeNanos/1000000000))
        end

        mon_win.setCursorPos(3,(k*2)+1)
        mon_win.setTextColor(colors.lightGray)
        if v.isBusy and v.craftingJob then
            local job = v.craftingJob
            mon_win.setTextColor(colors.lightBlue)
            mon_win.write(job.storage.amount.."x ")

            mon_win.setTextColor(colors.lightGray)
            mon_win.write(job.storage.displayName)

            mon_win.setTextColor(colors.white)
            mon_win.write(" - ")

            mon_win.setTextColor(colors.lightGray)
            mon_win.write(string.format("%.1f%%", (job.progress/job.totalItem)*100))
        else
            mon_win.write("Idle")
        end
    end
    mon_win.setVisible(true)
    sleep(0.125)
end
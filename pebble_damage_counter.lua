local monitor = peripheral.find("monitor")

local function waitWorldTime(duration)
    local start = os.epoch("ingame") / 72000
    local stop = start+duration
    print("Start: "..start)
    print("Start: "..stop)
    repeat
        local time = os.epoch("ingame") / 72000
        monitor.setCursorPos(1,1)
        monitor.write(string.format("%.1fs    ", (stop-time)))
        sleep()
        print(time)
    until time >= stop
end

local config = {}

local function loadConfig()
    if fs.exists("saved_config.txt") then
        local file = io.open("saved_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open("saved_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()
config.starting_time = config.starting_time or os.epoch("ingame") / 72000
config.starting_time_utc = config.starting_time_utc or os.epoch("utc")
writeConfig()

local reset_timer = 10
local reset_enabled = true

monitor.clear()
local function timerDrawThread()
    while reset_enabled do
        monitor.setTextScale(0.5)
        monitor.setTextColor(colors.red)
        monitor.setCursorPos(1,1)
        monitor.write("Program Restarted!")
        monitor.setCursorPos(1,2)
        monitor.write("Click monitor to cancel auto-reset")
        monitor.setCursorPos(1,3)
        monitor.write(reset_timer.."s before auto-reset")
        sleep(0.1)
    end
end

local function timerLogicThread()
    while reset_enabled do
        sleep(1)
        reset_timer = reset_timer-1
        if reset_timer <= 0 then
            config.starting_time = os.epoch("ingame") / 72000
            config.starting_time_utc = os.epoch("utc")
            writeConfig()
            break
        end
    end
end

local function timerTouchThread()
    while reset_enabled do
        os.pullEvent("monitor_touch")
        reset_enabled = false
        break
    end
end

parallel.waitForAny(timerLogicThread, timerDrawThread, timerTouchThread)
if reset_enabled then
    monitor.clear()
    monitor.setTextScale(1)
    monitor.setTextColor(colors.red)
    monitor.setCursorPos(1,1)
    monitor.write("Auto-Reset")
    monitor.setCursorPos(1,2)
    monitor.write("Confirmed")
else
    monitor.clear()
    monitor.setTextScale(1)
    monitor.setTextColor(colors.green)
    monitor.setCursorPos(1,1)
    monitor.write("Auto-Reset")
    monitor.setCursorPos(1,2)
    monitor.write("Cancelled")
end
sleep(1)

local restart_prompt = false

local function drawThread()
    while true do
        local curr_time = os.epoch("ingame") / 72000
        local utc_time = os.epoch("utc")
        local elapsed_time = (curr_time-config.starting_time)
        monitor.setCursorPos(1,1)
        monitor.write("Estimated Damage:")
        monitor.setCursorPos(1,2)
        monitor.clearLine()
        local int_str = string.format("%.0f", elapsed_time/2)
        monitor.write(int_str:reverse():gsub("(%d%d%d)", "%1 "):reverse():gsub("^ (.+)", "%1"))

        if restart_prompt then
            monitor.setCursorPos(1,3)
            monitor.clearLine()
        else
            monitor.setCursorPos(1,3)
            monitor.write("Running For:")
            monitor.setCursorPos(1,4)
            monitor.clearLine()
            local e_utc = (utc_time-config.starting_time_utc)/1000
            monitor.write(string.format("%.0fd %.0fh %.0fm %.0fs", math.floor(e_utc/86400), math.floor((e_utc/3600)%24), math.floor((e_utc/60)%60), math.floor((e_utc)%60)))
        end
        sleep()
    end
end

local function touchThread()
    while true do
        os.pullEvent("monitor_touch")

        monitor.setTextColor(colors.orange)
        monitor.setCursorPos(1,4)
        monitor.clearLine()
        monitor.write("Confirm Restart?")
        local confirm_timeout = os.startTimer(2)
        restart_prompt = true
        while true do
            local event = {os.pullEvent()}
            if event[1] == "timer" and event[2] == confirm_timeout then
                monitor.setCursorPos(1,4)
                monitor.clearLine()
                monitor.setTextColor(colors.green)
                monitor.write("Restart Cancelled")
                sleep(0.5)
                monitor.setCursorPos(1,4)
                monitor.clearLine()
                monitor.setTextColor(colors.white)
                restart_prompt = false
                break
            elseif event[1] == "monitor_touch" then
                local x, y = event[3], event[4]
                if x < 16 and y == 4 then
                    monitor.setCursorPos(1,4)
                    monitor.clearLine()
                    config.starting_time = os.epoch("ingame") / 72000
                    config.starting_time_utc = os.epoch("utc")
                    writeConfig()
                    monitor.setTextColor(colors.red)
                    sleep(0.25)
                    monitor.setTextColor(colors.white)
                end
                restart_prompt = false
                break
            end
        end
    end
end

monitor.setTextColor(colors.white)
monitor.clear()

local stat, err = pcall(function()
    parallel.waitForAny(touchThread, drawThread)
end)

if not stat then
    if err == "Terminated" then
        monitor.clear()
        print("Terminated Program")
        monitor.setCursorPos(1,1)
        monitor.write("Terminated Program")
    else
        error(err)
    end
end
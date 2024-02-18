local old_time = os.epoch("utc")
local curr_time = os.epoch("utc")
while true do
    term.clear()
    term.setCursorPos(1,1)

    old_time = curr_time
    curr_time = os.epoch("utc")

    local delta = math.abs(curr_time-old_time)

    print("TPS: "..string.format("%.1f", (1000/delta)*20).." Tick Time: "..(delta/20).."ms")
    sleep(1)
end
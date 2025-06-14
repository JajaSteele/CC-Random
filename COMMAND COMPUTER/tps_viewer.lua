


while true do
    local stat, data = commands.exec("/forge tps")
    local last_line = data[#data]
    local ticktime = last_line:match("(%d+%.%d+) ms")
    local tps = last_line:match("TPS: (%d+%.%d+)")

    commands.exec("/scoreboard players set TPS tps_display "..math.floor(tps))
    commands.exec("/scoreboard players set MS tps_display "..string.format("%.0f", ticktime))

    sleep(1)
end

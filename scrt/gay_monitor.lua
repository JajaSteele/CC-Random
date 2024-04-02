local color = 1
while true do
    peripheral.find("monitor").setBackgroundColor(color)
    color = color*2
    if color == colors.black then
        color = 1
    end
    sleep(0.25)
end

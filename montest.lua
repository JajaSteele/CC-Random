while true do
    local monitor = peripheral.find("monitor")
    if monitor then
        local sizeX,sizeY = monitor.getSize()

        for i1=1, sizeY do
            local str = ""
            for i2=1, sizeX do
                str = str..math.random(0,9)
            end
            monitor.setCursorPos(1,i1)
            monitor.write(str)
        end
    end
    local cb = peripheral.find("chatBox")
    if cb then
        cb.sendMessage("Loaded.","montest")
        os.sleep(1.1)
    else
        os.sleep(0.2)
    end
end
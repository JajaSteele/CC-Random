local monitor = peripheral.find("monitor")

function mslowPrint(x1,delay1,color1)
    i1 = 1
    maxW,maxH = monitor.getSize()
    posW, posH = monitor.getCursorPos()
    monitor.setTextColor(color1)
    for i2=1, #x1 do
        if (posW+string.len(x1[i2])) > maxW then
            i1 = i1+1
            monitor.setCursorPos(1,i1)
            print("Reached End!")
        end
        print(posW+string.len(x1[i2]).."/"..maxW)
        for i=1, string.len(x1[i2]) do
            posW, posH = monitor.getCursorPos()
            if string.sub(x1[i2], i, i) == " " and posW == 1 then
                break
            end
            monitor.setCursorPos(posW,i1)
            monitor.write(string.sub(x1[i2], i, i))
            os.sleep(delay1)
            posW2, posH2 = monitor.getCursorPos()
        end
    end
end
local args = {...}

if args[1] ~= nil then
    delay = tonumber(args[2])
    color = colors[args[3]]
    monitor.clear()
    monitor.setCursorPos(1,1)
    local text1={}; for w in args[1]:gsub("%f[%w].-%f[^%w]","\0%0\0"):gmatch"%Z+" do table.insert(text1, w) end
    mslowPrint(text1,delay,color)
end
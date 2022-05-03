m = peripheral.find("monitor")
args = {...}

function mwrite(x1,y1,t1)
    m.setCursorPos(1,y1)
    x2,y2 = m.getSize()
    m.write(string.rep(" ", x2))
    m.setCursorPos(x1,y1)
    m.write(t1)
end

function mclear()
    m.clear()
    m.setCursorPos(1,1)
end

function mclearline(c1)
    m.setCursorPos(1,c1)
    x2,y2 = m.getSize()
    m.write(string.rep(" ", x2))
    m.setCursorPos(1,c1)
end

m.clear()
m.setCursorPos(1,1)

mwrite(1,1,"Welcome.")
mwrite(1,2,"To Clock App")

os.sleep(2)

m.clear()

m.setTextScale(5)
x1,y1 = m.getSize()

while true do
    time = textutils.formatTime(os.time("ingame"))
    timeIRL = textutils.formatTime(os.time("local"))
    timeUTC = textutils.formatTime(os.time("utc"))
    timeoffset = (x1-string.len(time))+1
    timeoffset2 = (x1-string.len(timeIRL))+1
    timeoffset3 = (x1-string.len(timeUTC))+1
    m.setCursorPos(1,2)
    m.write("MCW ")
    m.setCursorPos(1,3)
    m.write("LCL ")
    m.setCursorPos(1,4)
    m.write("UTC ")
    x2,y2 = m.getSize()
    m.setCursorPos(1,1)
    m.write(string.rep("-", x2))
    m.setCursorPos(1,5)
    m.write(string.rep("-", x2))
    mwrite(timeoffset,2,time)
    mwrite(timeoffset2,3,timeIRL)
    mwrite(timeoffset3,4,timeUTC)
    m.setCursorPos(1,2)
    m.write("MCW ")
    m.setCursorPos(1,3)
    m.write("LCL ")
    m.setCursorPos(1,4)
    m.write("UTC ")
    os.sleep(0.5)
end
print(m.getSize())
local crystallizer = peripheral.find("sgjourney:crystallizer")

print("register crystallizer once")
for i1=1, 5 do
    print(crystallizer.list())
    sleep(0.05)
end

print("register crystallizer at every loop iteration")
for i1=1, 5 do
    local crystallizer = peripheral.find("sgjourney:crystallizer")
    print(crystallizer.list())
    sleep(0.05)
end

print("testing 1000 times..")
local posx, posy = term.getCursorPos()
local res = 0
for i1=1, 1000 do
    local stat = crystallizer.list()
    if not stat then
        res = res+1
    end
    term.setCursorPos(posx, posy)
    term.clearLine()
    term.write(i1.."/1000")
end

print("Failed "..res.." out of 1000 tests")
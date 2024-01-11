local sg = peripheral.find("basic_interface")

local monitor = peripheral.find("monitor")

rs.setAnalogOutput("back", 0)
print("Rotating back to PoO")

sg.rotateClockwise(0)

repeat
    sleep(0.5)
until sg.getCurrentSymbol() == 0

print("Done")

print("Enter pulse length:")
local pulse_length = tonumber(read())

for i1=1, 39 do
    rs.setAnalogOutput("back", 14)
    sleep(pulse_length)
    rs.setAnalogOutput("back", 0)
    term.write("Target Symbol: "..i1.." | Result Symbol: "..sg.getCurrentSymbol())
    monitor.clear()
    monitor.setCursorPos(1,1)
    monitor.write("Cur: "..sg.getCurrentSymbol())
    monitor.setCursorPos(1,2)
    monitor.write("Tar: "..i1)
    if i1 ~= sg.getCurrentSymbol() then
        term.setTextColor(colors.red)
        term.write(" | ERROR: "..(sg.getCurrentSymbol()-i1))
        term.setTextColor(colors.white)

        monitor.setTextColor(colors.red)
        monitor.setCursorPos(1,3)
        monitor.write("Err: "..(sg.getCurrentSymbol()-i1))
        monitor.setTextColor(colors.white)
    end
    print("")
    sleep(1)
end
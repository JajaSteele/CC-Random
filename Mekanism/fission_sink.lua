local sink = peripheral.find("cookingforblockheads:sink")
local p2p = peripheral.find("ae2:cable_bus")

term.clear()
term.setCursorPos(1,1)
print("DO NOT TERMINATE")
print("This computer provides coolant")
while true do
    term.setCursorPos(1,3)
    print("Transfer per tick:")
    print((sink.pushFluid(peripheral.getName(p2p)) or "None").."                  ")
end
local condenser = peripheral.find("ae2:condenser")
local sink = peripheral.find("cookingforblockheads:sink")

while true do
    local count = 0
    for i1=1, 16 do
        count = count + condenser.pullFluid(peripheral.getName(sink), 1000000000)
    end
    print(count)
end
local condenser_list = {peripheral.find("ae2:condenser")}
local sink = peripheral.find("cookingforblockheads:sink")

local threads = {}

print("Found "..#condenser_list.." condensers..")
for k, condenser in pairs(condenser_list) do
    for i1=1, 16 do
        threads[#threads+1] = function()
            while true do
                for i1=1, 8 do
                    condenser.pullFluid(peripheral.getName(sink))
                end
            end
        end
    end
end

print("Starting "..#threads.." threads")
parallel.waitForAny(table.unpack(threads))
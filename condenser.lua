local condensers = {peripheral.find("ae2:condenser")}
local sink = peripheral.find("cookingforblockheads:sink")

local threads = {}

for k,v in pairs(condensers) do
    for i1=1, 512 do
        threads[#threads+1] = function()
            local name = peripheral.getName(v)
            while true do
                sink.pushFluid(name, 9999999999)
            end
        end
    end
end

print("Created "..#threads.." threads")
parallel.waitForAny(table.unpack(threads))
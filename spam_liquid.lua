local pulleys = {peripheral.find("create:hose_pulley")}
local b = peripheral.find("utilitix:experience_crystal")

local threads = {}

print("Thread Count:")
local count = tonumber(read()) or 1

for k,hose in pairs(pulleys) do
    for i1=1, count/(#pulleys) do
        threads[#threads+1] = function()
            while true do
                hose.pushFluid(peripheral.getName(b))
            end
        end
    end
end

while true do
    local stat, err = pcall(function()
        parallel.waitForAll(table.unpack(threads))
    end)
    if not stat then if err == "Terminated" then break else print(err) end end
end
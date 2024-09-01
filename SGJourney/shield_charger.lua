local interfaces = {peripheral.find("advanced_crystal_interface")}

local group_a = {}
local group_b = {}

local filter_mode = false

local base_gen = interfaces[1].getStargateGeneration() 
for k,v in pairs(interfaces) do
    if v.getStargateGeneration() ~= base_gen then
        filter_mode = true
        break
    end
end

local count = 0
for k,interface in pairs(interfaces) do
    if filter_mode then
        if interface.getStargateGeneration() == 3 then
            group_b[#group_b+1] = interface
        else
            group_a[#group_a+1] = interface
        end
    else
        if count%2 == 0 then
            group_a[#group_a+1] = interface
        else
            group_b[#group_b+1] = interface
        end
        count = count+1
    end
end

local dial_threads = {}

print("A = "..(#group_a))
print("B = "..(#group_b))

for k,inter in ipairs(group_a) do
    dial_threads[#dial_threads+1] = function()
        while true do
            local address = group_b[k].getLocalAddress()
            inter.disconnectStargate()
            for k,symbol in ipairs(address) do
                inter.engageSymbol(symbol)
            end
            inter.engageSymbol(0)
            repeat
                sleep()
            until inter.isWormholeOpen()
        end
    end
end

local stat, err = pcall(function()
    parallel.waitForAll(table.unpack(dial_threads))
end)

if not stat then
    if err == "Terminated" then
        for k,inter in ipairs(group_a) do
            local address = group_b[k].getLocalAddress()
            if inter.isStargateConnected() or inter.getChevronsEngaged() >= 9 then
                repeat
                    sleep()
                until inter.isWormholeOpen()
            else
                sleep(0.5)
            end
            inter.disconnectStargate()
        end
        print("Disconnected all gates: Program Terminated")
    else
        error(err)
    end
end
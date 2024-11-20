print("Horizontal radius?")
local hrange = tonumber(read())
print("vertical radius?")
local vrange = tonumber(read())

print("Filter?")
local filter = read()

local cx,cy,cz = commands.getBlockPosition()

local id_list = {}
local found = {}

local function cmdThread()
    for y=-vrange, vrange do
        for x=-hrange, hrange do
            for z=-hrange, hrange do
                print(x, y, z)
                repeat
                    local stat, err = pcall(function()
                        local id = commands.execAsync(string.format("execute if block %d %d %d %s", cx+x, cy+y, cz+z, filter))
                        id_list[id] = {x = cx+x, y = cy+y, z = cz+z}
                    end)
                until stat
            end
            sleep()
        end
    end
end

local function asyncResponseThread()
    while true do
        local event, id, success = os.pullEvent("task_complete")
        if success then
            local data = id_list[id]
            print("Found at x"..data.x.." y"..data.y.." z"..data.z)
            found[#found+1] = {
                x = data.x,
                y = data.y,
                z = data.z,
            }
        end
    end
end

parallel.waitForAny(cmdThread, asyncResponseThread)
local sx,sy,sz = commands.getBlockPosition()
local monitor = peripheral.find("monitor")

local side = {
    {1,0,0},
    {0,1,0},
    {0,0,1},
    {-1,0,0},
    {0,-1,0},
    {0,0,-1},
}

while true do
    if monitor then
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Click")
        monitor.setCursorPos(1,2)
        monitor.write("To Fix")
        monitor.setCursorPos(1,3)
        monitor.write("Cables")

        os.pullEvent("monitor_touch")
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Crawling")
    end

    local active_threads = 0
    local job_list = {}

    local crawl

    local quit = false
    local threads = {}
    for i1=1, 64 do
        threads[i1] = function()
            while true do
                if #job_list > 0 then
                    active_threads = active_threads + 1
                    local job = table.remove(job_list, 1)
                    crawl(job.x,job.y,job.z)
                    active_threads = active_threads - 1
                end
                sleep()
                if quit then
                    return
                end
            end
        end
    end

    local block_count = 0

    threads[#threads+1] = function()
        print("Starting first job")
        job_list[#job_list+1] = {x=sx, y=sy, z=sz}
        while true do
            if monitor then
                monitor.setCursorPos(1,2)
                monitor.write("Found:")
                monitor.setCursorPos(1,3)
                monitor.write(tostring(block_count))
            end
            sleep()
            if active_threads == 0 then
                quit = true
                break
            end
        end
    end

    local block_map = {}
    local block_lookup = {}
    function crawl(cx,cy,cz)
        for k, side in pairs(side) do
            local x,y,z = cx+side[1],cy+side[2],cz+side[3]
            local block_info = commands.getBlockInfo(x,y,z)
            if block_info.name == "computronics:audio_cable" then
                if not block_map[x] then
                    block_map[x] = {}
                end
                if not block_map[x][z] then
                    block_map[x][z] = {}
                end
                if not block_map[x][z][y] then
                    block_map[x][z][y] = true
                    block_lookup[#block_lookup+1] = {
                        x=x,
                        y=y,
                        z=z
                    }
                    block_count = block_count + 1
                    print("Found: "..block_count.." at "..x.." "..y.." "..z)
                    job_list[#job_list+1] = {x=x, y=y, z=z}
                end
            end
        end
    end

    parallel.waitForAll(table.unpack(threads))

    threads = {}
    for i1=1, 64 do
        threads[i1] = function()
            while true do
                if #job_list > 0 then
                    active_threads = active_threads + 1
                    local job = table.remove(job_list, 1)
                    commands.setblock(job.x, job.y, job.z, "minecraft:air")
                    commands.setblock(job.x, job.y, job.z, "computronics:audio_cable")
                    active_threads = active_threads - 1
                end
                sleep()
                if quit then
                    return
                end
            end
        end
    end

    threads[#threads+1] = function()
        while true do
            print(active_threads.." > "..#job_list)
            if monitor then
                monitor.setCursorPos(1,2)
                monitor.write("Left:")
                monitor.setCursorPos(1,3)
                monitor.write(tostring(#job_list).."     ")
            end
            sleep()
            if active_threads == 0 then
                quit = true
                break
            end
        end
    end

    job_list = block_lookup
    quit = false

    if monitor then
        monitor.clear()
        monitor.setCursorPos(1,1)
        monitor.write("Fixing")
    end

    parallel.waitForAll(table.unpack(threads))

    print("Done fixing.")
    if not monitor then
        break
    end
end
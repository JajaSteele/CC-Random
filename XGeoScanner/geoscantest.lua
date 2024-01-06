local scan_count = 0

local scan

local ply

local filter = {"minecraft:damaged_anvil"}

local function check(t,l)
    local res = false
    for k,v in pairs(l) do
        if t == v then
            return true
        end
    end
end

local function coreThread()
    while true do
        if not peripheral.isPresent("geoScanner") then
            pocket.equipBack()
        end
        local geo = peripheral.find("geoScanner")

        scan = geo.scan(8)
        print(#scan)
        print("ID: "..scan_count)
        scan_count = scan_count+1

        pocket.equipBack()
        ply = peripheral.find("playerDetector")
        sleep(2.25)
    end
end

local function drawPosThread()
    while true do
        if peripheral.isPresent("playerDetector") then
            local pos = ply.getPlayerPos("JajaSteele")
        end
        for k,v in pairs(scan or {}) do
            if check(v.name, filter) then
                print(os.time()..(v.name))
            end
        end
        sleep()
    end
end

parallel.waitForAny(coreThread, drawPosThread)
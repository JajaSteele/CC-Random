local interfaces = {peripheral.find("advanced_crystal_interface")}

local rotate_threads = {}

for k,v in pairs(interfaces) do
    v.disconnectStargate()
    print("Disconnecting gate")
    if v.openIris then
        v.openIris()
        print("Opening iris")
    end
    if v.rotateAntiClockwise then
        if v.isChevronOpen() then
            v.closeChevron()
        end
        rotate_threads[#rotate_threads+1] = function()
            print("Reseting rotation")
            if (0-v.getCurrentSymbol()) % 39 < 19 then
                v.rotateAntiClockwise(0)
            else
                v.rotateClockwise(0)
            end
    
            repeat
                sleep()
            until v.getCurrentSymbol() == 0
        end
    end
end

if #rotate_threads > 0 then
    parallel.waitForAll(table.unpack(rotate_threads))
end
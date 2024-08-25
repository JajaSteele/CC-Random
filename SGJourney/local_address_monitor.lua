local monitor = peripheral.find("monitor")
local interface = peripheral.find("advanced_crystal_interface")

local optimal_scale = 5
local example_text = "-69-69-69-69-69-69-69-69-"
repeat
    monitor.setTextScale(optimal_scale)
    local mx, my = monitor.getSize()
    if mx >= #example_text then
        break
    else
        optimal_scale = optimal_scale-0.5
    end
until optimal_scale == 0.5

monitor.setTextScale(optimal_scale)

local address = {}

local function addressThread()
    while true do
        if interface.getLocalAddress then
            pcall(function()
                local new_address = interface.getLocalAddress()
                if new_address and #new_address > 0 then
                    address = new_address
                    os.queueEvent("update_address")
                end
            end)
        else
            interface = peripheral.find("advanced_crystal_interface")
        end
        sleep(0.5)
    end
end

local function monitorThread()
    while true do
        monitor.setCursorPos(1,1)
        monitor.clearLine()
        monitor.write("-"..table.concat(address, "-").."-")
        os.pullEvent("update_address")
    end
end

parallel.waitForAny(addressThread,monitorThread)
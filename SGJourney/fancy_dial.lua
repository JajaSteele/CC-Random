local address = {26, 35, 15, 28, 33, 1, 8, 22}
local monitor = peripheral.find("monitor")
monitor.setTextScale(4.5)

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local is_dialing = true
local function dialThread()
    interface.rotateAntiClockwise(-1)
    for k,v in ipairs(address) do
        repeat
            sleep()
        until ((interface.getCurrentSymbol()/38)*#address) >= k
        interface.engageSymbol(v)
        sleep(0.25)
    end
    is_dialing = false
end

local function zeroThread()
    repeat
        local symbol = interface.getCurrentSymbol()
        sleep()
        print(symbol)
        monitor.setCursorPos(1,1)
        monitor.write(symbol.."  ")
    until not is_dialing and symbol == 0
    interface.endRotation()
    interface.engageSymbol(0)
end

interface.disconnectStargate()

if (0-interface.getCurrentSymbol()) % 39 < 19 then
    interface.rotateAntiClockwise(0)
else
    interface.rotateClockwise(0)
end

repeat
    sleep()
until interface.getCurrentSymbol() == 0

parallel.waitForAll(dialThread, zeroThread)

os.pullEvent("stargate_outgoing_wormhole")
sleep(3)
interface.disconnectStargate()
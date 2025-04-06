local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local count = 0
while true do
    interface.rotateAntiClockwise(-1)
        
    os.sleep(0.75)

    while not interface.isCurrentSymbol(0) do
        local sym = interface.getCurrentSymbol()
        print(sym)
        sleep()
    end

    interface.endRotation()
    count = count+1
    print("Passed test "..count.." times")
end
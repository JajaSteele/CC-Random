local interface = peripheral.find("advanced_crystal_interface")

while true do
    local event, address = os.pullEvent("stargate_incoming_wormhole")

    if address then
        print("Incoming Wormhole!")
        repeat
            sleep()
        until interface.isWormholeOpen()

        sleep(0.1)
        print("Closing..")
        interface.disconnectStargate()
        sleep(0.1)

        print("Dialing back: "..table.concat(address, "-"))

        for k,v in ipairs(address) do
            interface.engageSymbol(v)
        end

        interface.engageSymbol(0)
    end
end
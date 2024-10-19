local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

print("Starting anti-kawoosh iris program..")

if interface.isStargateConnected() and not interface.isWormholeOpen() and interface.getChevronsEngaged() < 2 then
    if interface.isStargateDialingOut() then
        os.queueEvent("stargate_outgoing_wormhole")
    else
        os.queueEvent("stargate_incoming_wormhole")
    end
end

while true do
    local data = {os.pullEvent()}
    if data[1] == "stargate_incoming_wormhole" or data[1] == "stargate_outgoing_wormhole" then
        print("Connection detected! Closing iris")
        interface.closeIris()
        repeat
            sleep(0.1)
        until interface.isWormholeOpen() or not interface.isStargateConnected()
        print("Kawoosh finished! Opening iris")
        interface.openIris()
    elseif data[1] == "stargate_disconnected" then
        print("Connection closed! Opening iris")
        interface.openIris()
    end
end
local end_automata = peripheral.find("endAutomata")
while true do
    local event, user, chat, id, hidden = os.pullEvent("chat")
    if chat == "spawn" and hidden then
        print("Spawning dragon..")
        for i1=1, 4 do
            end_automata.warpToPoint(tostring(i1))
            turtle.digDown()
            turtle.placeDown()
            repeat
                sleep()
            until end_automata.getOperationCooldown("warp") == 0
        end

        end_automata.warpToPoint("exit")
    end
end
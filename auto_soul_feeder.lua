local automata = peripheral.find("weakAutomata")

turtle.select(1)

while true do
    local item = turtle.getItemDetail()
    if item and item.name:match("weak_automata") then
        local stat, msg = automata.feedSoul()
        print(stat,msg)
    end
    sleep(0.1)
end
local automata = peripheral.find("weakAutomata") or peripheral.find("endAutomata")

if automata then
    turtle.select(1)
    while true do
        local stat, num = automata.chargeTurtle()
        if not stat then
            error(num)
        else
            print("+"..num.." "..turtle.getFuelLevel().."/"..turtle.getFuelLimit())
            if num == 0 then
                return
            end
        end
    end
end

print("Done!")
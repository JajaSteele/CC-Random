local output = peripheral.find("minecraft:dispenser")

local input = peripheral.find("ae2:interface")

local sides = {
    "top",
    "bottom",
    "left",
    "right",
    "front",
    "back"
}

while true do
    os.pullEvent("redstone")

    for k,v in pairs(sides) do
        if rs.getInput(v) then
            for i1=1, 9 do
                local item = input.getItemDetail(i1)
                local move_count = 0
                if item then
                    print("moving x"..item.count.." "..item.displayName)
                    repeat
                        move_count = move_count+output.pullItems(peripheral.getName(input), i1, item.count-move_count)
                    until move_count >= item.count
                    print("done")
                end
            end
            break
        end
    end
end
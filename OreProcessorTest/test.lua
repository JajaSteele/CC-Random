inv = peripheral.wrap("front")

while true do
    term.clear()
    term.setCursorPos(1,1)
    firstItem = inv.getItemDetail(1)
    if firstItem then
        if firstItem.tags["forge:raw_materials"] then
            print("Raw Ore Detected!\n")
            fullCount = 0
            for i1=1, inv.size() do
                newItem = inv.getItemDetail(i1)
                if newItem then
                    fullCount = fullCount+newItem.count
                end
            end
            if math.fmod(fullCount,3) ~= 0 then
                print("Not Multiple of 3, Refused!")
            else
                print("Multiple of 3, Accepted!")
            end
        end
    end
    print("\nClick to Continue..")
    os.pullEvent("mouse_click")
end
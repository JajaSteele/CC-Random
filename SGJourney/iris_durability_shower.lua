local reader = peripheral.find("blockReader")

term.clear()
while true do
    local dur = "UNKNOWN"
    term.setCursorPos(1,1)
    local data = reader.getBlockData()
    local item = data.IrisInventory.Items[1]
    local tag
    if item then
        tag = item.tag
        if tag and tag.durability then
            dur = tag.durability
        else
            dur = "FULL DURABILITY"
        end
    else
        dur = "NO IRIS"
    end

    term.clearLine()
    term.write("Durability: "..dur)
    sleep(0.5)
end
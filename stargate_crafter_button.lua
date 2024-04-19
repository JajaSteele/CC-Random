local output = peripheral.find("minecraft:barrel")

local input = peripheral.find("ae2:interface")

local speaker = peripheral.find("speaker")

local monitor = peripheral.find("monitor")

local sides = {
    "top",
    "bottom",
    "left",
    "right",
    "front",
    "back"
}

local function getItemSlot(name, storage)
    local item_list = storage.list()

    if item_list then
        for k,v in pairs(item_list) do
            if v.name == name then
                return k
            end
        end
    end
end

local function getItemCount(name, storage)
    local item_list = storage.list()
    local count = 0
    if item_list then
        for k,v in pairs(item_list) do
            if v.name == name then
                count = count+v.count
            end
        end
    end

    return count
end


local function getSlotCount(name, storage, slot)
    local item = storage.getItemDetail(slot)
    
    return item.count
end
local function moveItem(name, from_storage, to_storage, to_slot, count)
    local moved_count = 0
    repeat
        local item_slot = getItemSlot(name, from_storage)
        if item_slot then
            moved_count = moved_count + (from_storage.pushItems(peripheral.getName(to_storage), item_slot, (count or 64)-moved_count, to_slot) or 0)
        else
            return nil
        end
    until moved_count >= count
    return moved_count
end

while true do
    local base_count = getItemCount("sgjourney:classic_stargate_base_block", input)
    local chevron_count = getItemCount("sgjourney:classic_stargate_chevron_block", input)
    local ring_count = getItemCount("sgjourney:classic_stargate_ring_block", input)
    for k,v in pairs(sides) do
        if rs.getInput(v) then

            if base_count == 1 and chevron_count == 9 and ring_count == 14 then
                moveItem("sgjourney:classic_stargate_base_block", input, output, nil, 1)
                moveItem("sgjourney:classic_stargate_chevron_block", input, output, nil, 9)
                moveItem("sgjourney:classic_stargate_ring_block", input, output, nil, 14)

                print("Building a gate..")
                speaker.playSound("block.note_block.bell", 10, 1)
                repeat
                    local is_off = true
                    for k,v1 in pairs(sides) do
                        if rs.getInput(v1) then
                            is_off = false
                            break
                        end
                    end
                until is_off
            else
                speaker.playSound("block.note_block.bass", 10, 0)
                repeat
                    local is_off = true
                    for k,v1 in pairs(sides) do
                        if rs.getInput(v1) then
                            is_off = false
                            break
                        end
                    end
                until is_off
            end
        end
    end
    monitor.setCursorPos(1,1)
    monitor.clearLine()
    monitor.setTextColor(colors.white)
    monitor.write("Gate Crafting Buffer")

    if base_count == 1 and chevron_count == 9 and ring_count == 14 then
        monitor.setTextColor(colors.lime)
    else
        monitor.setTextColor(colors.orange)
    end

    monitor.setCursorPos(1, 3)
    monitor.clearLine()
    monitor.write("Base Block : "..base_count.."/ 1")
    monitor.setCursorPos(1, 4)
    monitor.clearLine()
    monitor.write("Chevron Block : "..chevron_count.."/ 9")
    monitor.setCursorPos(1, 5)
    monitor.clearLine()
    monitor.write("Ring Block : "..ring_count.."/ 14")
    
    monitor.setCursorPos(1, 7)
    monitor.clearLine()
    if base_count == 1 and chevron_count == 9 and ring_count == 14 then
        monitor.write("-= READY TO CRAFT =-")
    end
    sleep(0.5)
end
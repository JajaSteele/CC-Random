local crystallizer_list = {peripheral.find("sgjourney:crystallizer")}

local interface = peripheral.find("ae2:interface")

local function getItemSlot(name, storage)
    local item_list = storage.list()

    for k,v in pairs(item_list) do
        if v.name == name then
            return k
        end
    end
end

local function getItemCount(name, storage)
    local item_list = storage.list()
    local count = 0

    for k,v in pairs(item_list) do
        if v.name == name then
            count = count+v.count
        end
    end

    return count
end

local function getSlotCount(name, storage, slot)
    local item = storage.getItemDetail(slot)

    return (item or {count=0}).count
end

local function moveItem(name, from_storage, to_storage, to_slot, count)
    local moved_count = 0
    repeat
        local item_slot = getItemSlot(name, from_storage)
        if item_slot then
            moved_count = moved_count + from_storage.pushItems(peripheral.getName(to_storage), item_slot, (count or 64)-moved_count, to_slot)
        else
            return nil
        end
    until moved_count >= count
    return moved_count
end

while true do
    for k,crystallizer in pairs(crystallizer_list) do
        if crystallizer.getItemDetail(4) then
            crystallizer.pushItems(peripheral.getName(interface), 4, 64)
            print("Moved output from "..peripheral.getName(interface))
        end
    end
    sleep(0.25)
end
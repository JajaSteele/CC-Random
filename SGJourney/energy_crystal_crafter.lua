local crystallizer_list = {peripheral.find("sgjourney:crystallizer")}
local barrel = peripheral.find("minecraft:barrel")

local tank = peripheral.find("mob_grinding_utils:tank")

local pattern = peripheral.find("ae2:pattern_provider")

print(barrel)
print(tank)
print(pattern)

local function getItemSlot(name, storage)
    if storage then
        local item_list = storage.list()

        if not item_list then return end
        for k,v in pairs(item_list) do
            if v.name == name then
                return k
            end
        end
    end
end

local function getItemCount(name, storage)
    if storage then
        local item_list = storage.list()
        local count = 0

        for k,v in pairs(item_list) do
            if v.name == name then
                count = count+v.count
            end
        end

        return count
    else
        return 0
    end
end

local function getSlotCount(name, storage, slot)
    if storage then
        local item = storage.getItemDetail(slot)

        return (item or {count=0}).count
    else
        return {count=0}
    end
end

local function getNaquadahAmount()
    return tank.tanks()[1].amount
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
        local input_slot = crystallizer.getItemDetail(1)

        if not input_slot then
            if getItemCount("minecraft:redstone", barrel) >= 6 and getItemCount("sgjourney:crystal_base", barrel) >= 1 and getNaquadahAmount() >= 200 then
                print("Filling "..peripheral.getName(crystallizer))
                moveItem("sgjourney:crystal_base", barrel, crystallizer, 1, 1)
                moveItem("minecraft:redstone", barrel, crystallizer, 2, 3)
                moveItem("minecraft:redstone", barrel, crystallizer, 3, 3)
                tank.pushFluid(peripheral.getName(crystallizer), 200)
            end
        else
            local slot_2 = getSlotCount("minecraft:redstone", crystallizer, 2)
            local slot_3 =  getSlotCount("minecraft:redstone", crystallizer, 3)
            
            if slot_2 < 3 then
                moveItem("minecraft:redstone", barrel, crystallizer, 1, 3-slot_2)
                print("Refilled Slot 2 of "..peripheral.getName(crystallizer))
            end
            if slot_3 < 3 then
                moveItem("minecraft:redstone", barrel, crystallizer, 1, 3-slot_3)
                print("Refilled Slot 3 of "..peripheral.getName(crystallizer))
            end
        end    
        
        if getItemSlot("sgjourney:energy_crystal", crystallizer) then
            print("Removed Energy Crystal from "..peripheral.getName(crystallizer))
            moveItem("sgjourney:energy_crystal", crystallizer, pattern, nil, 1)
        end
    end
    sleep(0.25)
end
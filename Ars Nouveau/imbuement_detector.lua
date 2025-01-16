local chamber = peripheral.find("ars_nouveau:imbuement_chamber")

local old_item
local new_item

while true do
    old_item = new_item
    new_item = chamber.getItemDetail(1)
    
    if (old_item and new_item and old_item.name ~= new_item.name) or (not old_item and not new_item) then
        if old_item then print(old_item.name) end
        if new_item then print(new_item.name) end
    end
    
    if old_item and new_item and (old_item.name ~= new_item.name) then
        print("Pulsing")
        redstone.setOutput("bottom", true)
        sleep(0.15)
        redstone.setOutput("bottom", false)
    end
    sleep(0.25)
end
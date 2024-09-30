local inv = peripheral.find("inventoryManager")
local me = peripheral.find("meBridge")

local picker = peripheral.find("picker")

local function pickListener()
    while true do
        local event, success, block_name, block_nbt = os.pullEvent("picker_pickblock")
        if not success then
            sleep(0.05)
            local curr_item = inv.getItemInHand()
            if not curr_item or curr_item.name ~= block_name then
                if curr_item then
                    local free_slot = inv.getFreeSlot()
                    if free_slot > 0 then

                    else

                    end
                end
            end
        end
    end
end

parallel.waitForAll(pickListener)
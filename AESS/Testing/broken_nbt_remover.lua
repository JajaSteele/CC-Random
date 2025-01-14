local me = peripheral.find("meBridge")

local to_remove = {}

local old_content = {
    item = nil,
    fluid = nil,
    gas = nil
}
local new_content = {
    item = nil,
    fluid = nil,
    gas = nil
}

local function compareContentItems(old,new)
    local searcheable_old = {}
    for k,item in pairs(old) do
        searcheable_old[item.fingerprint] = item
    end

    local searcheable_new = {}
    for k,item in pairs(new) do
        searcheable_new[item.fingerprint] = item
    end

    for k,item in pairs(old) do
        local new_item = searcheable_new[item.fingerprint]
        if new_item then
            if new_item.amount < item.amount then
                print("More "..item.name.." in old")
                to_remove[#to_remove+1] = {
                    fingerprint = item.fingerprint,
                    name = item.name,
                    count = item.amount or 0
                }
                sleep(0.1)
            elseif new_item.amount > item.amount then
                print("More "..item.name.." in new")
                to_remove[#to_remove+1] = {
                    fingerprint = item.fingerprint,
                    name = item.name,
                    count = item.amount or 0
                }
                sleep(0.1)
            end
        else
            print("Couldn't find "..item.name.." in new")
            to_remove[#to_remove+1] = {
                fingerprint = item.fingerprint,
                name = item.name,
                count = item.amount or 0
            }
            sleep(0.1)
        end
    end

    for k,item in pairs(new) do
        local old_item = searcheable_old[item.fingerprint]
        if not old_item then
            print("Couldn't find "..item.name.." in old")
            to_remove[#to_remove+1] = {
                fingerprint = item.fingerprint,
                name = item.name,
                count = item.amount or 0
            }
            sleep(0.1)
        end
    end
end

print("Scanning")
local new_list = me.listItems()
old_content.item = new_content.item or new_list
new_content.item = new_list
print("Comparing")
compareContentItems(old_content.item, new_content.item)

print("Removing")
for k,v in pairs(to_remove) do
    print("Remove: "..v.name.." x"..v.count)
    os.pullEvent("mouse_click")
end
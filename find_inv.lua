local invs = {peripheral.find("inventory")}

local args = {...}

local found_list = {}

for k, inv in pairs(invs) do
    if inv.list then
        local item_list = inv.list()
        if args[1] == "empty" then
            local count = 0
            for k,item_stack in pairs(item_list) do
                count = count+1
            end

            if count > 0 then
                local name = peripheral.getName(inv)
                if args[2] then
                    if name:lower():match(args[2]:lower()) then
                        found_list[name] = name
                    end
                else
                    found_list[name] = name
                end
            end
        else
            for k,item_stack in pairs(item_list) do
                if item_stack.name:match(args[1]:lower()) then
                    local name = peripheral.getName(inv)
                    if args[2] then
                        if name:lower():match(args[2]:lower()) then
                            found_list[name] = name
                        end
                    else
                        found_list[name] = name
                    end
                end
            end
        end
    end
end

for k,v in pairs(found_list) do
    print(v)
end
local deployer_inv = peripheral.find("create:deployer")
local input_inv

for k,v in pairs({peripheral.find("inventory")}) do
    local is_deployer = false
    local types = {peripheral.getType(v)}
    for k1,v1 in pairs(types) do
        if v1 == "create:deployer" then
            is_deployer = true
            break
        end
    end
    if not is_deployer then
        input_inv = v
        break
    end
end

local counter = 1
while true do
    if not rs.getInput("bottom") then
        if input_inv.getItemDetail(counter) == nil then
            counter = 1
        else
            print("Pushing from slot "..counter)
            input_inv.pushItems(peripheral.getName(deployer_inv), counter, 1)
            counter = counter+1
        end
        sleep(0.05)
    end
    if counter > (input_inv.size() or 27) then
        if input_inv.getItemDetail(1) == nil then
            os.reboot()
        else
            counter = 1
        end
    end
    sleep()
end
print("Terminated")

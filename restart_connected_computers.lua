local computers = {peripheral.find("computer")}

print("Computer Count: "..(#computers))

sleep(0.75)

for k,computer in ipairs(computers) do
    local id = computer.getID()
    if computer.isOn() then
        computer.reboot()
        print("Activated Computer "..id.. "("..k.."/"..(#computers)..")")
    else
        computer.turnOn()
        print("Activated Computer "..id.. "("..k.."/"..(#computers)..")")
    end
    sleep(0.25)
end
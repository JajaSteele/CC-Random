local computers = {peripheral.find("computer")}

print("Computer Count: "..(#computers))

sleep(0.75)

for k,computer in pairs(computers) do
    local id = computer.getID()
    if computer.isOn() then
        computer.reboot()
        print("Rebooted Computer "..id)
    else
        computer.turnOn()
        print("Activated Computer "..id)
    end
end
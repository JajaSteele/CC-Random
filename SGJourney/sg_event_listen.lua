local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

term.clear()
term.setCursorPos(1,1)

while true do
    local event = {os.pullEvent()}
    print(textutils.serialize(event, { compact = true }))
end
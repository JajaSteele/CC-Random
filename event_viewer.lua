local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)


local modems = {peripheral.find("modem")}

local modem

local args = {...}

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))

    modem.open(2707)
end

term.redirect(monitor)
while true do
    local event = {os.pullEvent()}
    if (not args[1] or event[1] == args[1]) and (not args[2] or event[3].sType ~= args[2]) then
        print(textutils.serialize(event))
    end
end
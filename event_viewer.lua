local monitor = peripheral.find("monitor")
monitor.setTextScale(0.5)


local modems = {peripheral.find("modem")}

local modem

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
    local event = {rednet.receive()}
    print(textutils.serialize(event))
end
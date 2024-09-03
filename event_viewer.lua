local monitor = peripheral.find("monitor")


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

if monitor then
    term.redirect(monitor)
    monitor.setTextScale(0.5)
end

if modem then
    rednet.broadcast({sType = "lookup", sProtocol = "jjs_sg_remotedial"})
    modem.open(os.getComputerID())
end

while true do
    local event = {os.pullEvent()}
    --if type(event[5]) == "table" then print(event[5].sProtocol) end
    if (not args[1] or event[1] == args[1]) and ((type(event[5]) ~= "table") or ((not args[2] or not event[5].sType or event[5].sType ~= args[2]) and (not args[3] or event[5].sProtocol == args[3]))) then
        print(textutils.serialize(event, {compact=true}))
    end
end
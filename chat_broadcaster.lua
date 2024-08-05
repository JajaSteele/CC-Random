local chat_box = peripheral.find("chatBox")

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
end

while true do
    local event, username, message, uuid, hidden = os.pullEvent("chat")
    if not hidden then
        rednet.broadcast({message=message, username=username}, "chat_event_broadcast")
        print("Broadcasted:\n"..message.."\n"..username)
    end
end
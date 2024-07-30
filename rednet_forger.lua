print("Welcome to Rednet-Forger! Your real ID is: "..os.getComputerID())

print("Enter your forged sender ID:")
local sender = tonumber(read())

print("Enter the recipient ID:")
local receiver = tonumber(read())

print("Enter your message:")
local msg = read()

print("Enter your protocol:")
local prot = read()

print("Done! Do you want to receive something? (y/n)")

local receive_stuff = read()

local receive = false
local receive_prot = ""

if receive_stuff == "y" or receive_stuff == "yes" then
    receive = true
    print("Enter receive protocol:")
    receive_prot = read()
end

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

modem.transmit(receiver, sender, {
    nRecipient = receiver,
    nMessageID = math.random(100000000, 999999999),
    message = msg,
    nSender = sender,
    sProtocol = prot
})

if receive then
    modem.open(sender)
    local data
    repeat
        data = {os.pullEvent("modem_message")}
        print(data[5].sProtocol, data[5].nRecipient)
    until data[5].sProtocol == receive_prot and data[5].nRecipient == sender
    print(textutils.serialize(data))
    print("Save to file? (y/n)")
    local save_stuff = read()

    if save_stuff == "y" or save_stuff == "yes" then
        local save = io.open(math.random(1000, 9999)..".txt", "w")
        save:write(textutils.serialize(data))
        save:close()
    end
end
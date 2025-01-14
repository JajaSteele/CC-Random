local ch = peripheral.find("chatBox")

local timestamp = os.date()

ch.sendMessage("["..timestamp.."] Computer has started up!", (os.getComputerLabel() or "") .." "..os.getComputerID())

while true do
    ch.sendMessage("Still on..", (os.getComputerLabel() or "") .." "..os.getComputerID())
    sleep(1.5)
end
local ch = peripheral.find("chatBox")

local timestamp = os.date()

ch.sendMessage("["..timestamp.."] Computer has started up!", (os.getComputerLabel() or "") .." "..os.getComputerID())
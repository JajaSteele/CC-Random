local ch = peripheral.find("chatBox")

local timestamp = os.date()

ch.sendMessage("["..timestamp.."] Computer has started up!", (os.getComputerLabel() or "") .." "..os.getComputerID())

print("loaded!")

commands.exec("scoreboard objectives remove chunkload")

commands.exec("scoreboard objectives add chunkload dummy \"Chunkload\"")

commands.exec("scoreboard objectives setdisplay sidebar chunkload")

local count = 1
while true do
    commands.exec("scoreboard players set "..((os.getComputerLabel() or "NoLabel").."_"..os.getComputerID()).." chunkload "..count)
    count = count+1
    sleep(0.25)
end
local b = peripheral.find("blockReader")

term.clear()
term.setCursorPos(1,1)
print("Blocks left to absorb:")

while true do
    term.setCursorPos(1,2)
    print(b.getBlockData().Info.absorbing.."      ")
    sleep(0.5)
end
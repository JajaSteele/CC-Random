local sg = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

sg.rotateAntiClockwise(5)
repeat
    sleep()
until sg.getCurrentSymbol() == 5
sg.openChevron()
sleep(0.25)
sg.closeChevron()

sleep(0.25)

sg.engageSymbol(0)
sleep(0.25)
sg.rotateClockwise(0)
repeat
    sleep()
until sg.getCurrentSymbol() == 0
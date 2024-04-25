local sequencer = peripheral.find("Create_SequencedGearshift")

while true do
    sequencer.rotate(10, 1)
    repeat
        sleep()
    until not sequencer.isRunning()
    sleep(0.1)
    sequencer.rotate(10, 1)
    repeat
        sleep()
    until not sequencer.isRunning()
    sleep(0.1)
    sequencer.rotate(10, -1)
    repeat
        sleep()
    until not sequencer.isRunning()
    sleep(0.1)
    sequencer.rotate(10, -1)
    repeat
        sleep()
    until not sequencer.isRunning()
    sleep(0.1)
end
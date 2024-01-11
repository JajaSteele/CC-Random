local sg = peripheral.find("basic_interface")

if sg.getCurrentSymbol() < 19 then
    sg.rotateClockwise(0)
else
    sg.rotateAntiClockwise(0)
end
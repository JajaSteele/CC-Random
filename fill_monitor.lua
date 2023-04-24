local mn = peripheral.find("monitor")

local sX, sY = mn.getSize()

for i1=1, sX do
    for i2=1, sY do
        mn.setCursorPos(i1,i2)
        mn.write("#")
    end
end
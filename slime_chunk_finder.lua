local env = peripheral.find("environmentDetector")

while true do
    term.clear()
    term.setCursorPos(1,1)
    if env.isSlimeChunk() then
        term.setTextColor(colors.lime)
        term.write("Slime Chunk!")
    else
        term.setTextColor(colors.red)
        term.write("No Slime Chunk..")
    end
    sleep(0.25)
end
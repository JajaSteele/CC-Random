local mixer = peripheral.find("mechanicalMixer")

while true do
    rs.setOutput("top", mixer.isRunning())
end
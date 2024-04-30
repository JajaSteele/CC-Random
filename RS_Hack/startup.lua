local sides = {
    "front",
    "back",
    "left",
    "right",
    "top",
    "bottom"
}

for k,v in pairs(sides) do
    rs.setOutput(v, true)
end

print("Press ENTER to exit")
repeat
    local event = {os.pullEvent()}
until event[1] == "key" and event[2] == keys.enter

for k,v in pairs(sides) do
    rs.setOutput(v, false)
end
local chest = peripheral.find("inventory")

term.clear()
term.setCursorPos(1,1)

for i1=1, chest.size() do
    local data = chest.getItemDetail(i1)
    if data then
        print(data.displayName)
    end
end
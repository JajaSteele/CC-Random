local list = fs.list("/")

for k,v in pairs(list) do
    if not fs.isReadOnly(v) then
        fs.delete(v)
        print("Deleted "..v)
    end
end
print("Done!")
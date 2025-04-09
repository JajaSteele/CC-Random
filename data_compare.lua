local scanner = peripheral.find("blockReader")

local old = textutils.serialize(scanner.getBlockData())
local new = textutils.serialize(scanner.getBlockData())

while true do
    old = new
    new = textutils.serialize(scanner.getBlockData())

    local new_table = {}
    local old_table = {}
    for line in new:gmatch(".-\n") do
        new_table[#new_table+1] = line
    end
    for line in old:gmatch(".-\n") do
        old_table[#old_table+1] = line
    end

    for k, line in pairs(new_table) do
        if not old_table[k] or old_table[k] ~= line then
            print(line)
        end
    end
    sleep(1)
end
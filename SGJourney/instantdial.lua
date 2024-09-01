local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local address = {}

print("Address:")
local temp_addr1 = read()
local temp_addr2 = split(temp_addr1, " ")
for k,v in ipairs(temp_addr2) do
    if tonumber(v) then
        address[#address+1] = tonumber(v)
    end
end

local address_table = {}
for k,v in ipairs(address) do
    print("Added Symbol: "..v)
    address_table[#address_table+1] = {
        previous=address_table[#address_table] or nil,
        symbol=v
    }
end
address_table[#address_table+1] = {
    previous=address_table[#address_table] or nil,
    symbol=0
}

local threads = {}
local pos = 1

for k,v in pairs(address_table) do
    threads[#threads+1] = function()
        local symbol = v
        local symbol_pos = k
        repeat
        until pos == symbol_pos
        pos = pos+1
        interface.engageSymbol(symbol.symbol)
        print("Engaging symbol "..symbol.symbol)
    end
end

print("Dialing in:")
for i1=3, 1, -1 do
    print(i1.."s")
    sleep(1)
end

parallel.waitForAll(table.unpack(threads))
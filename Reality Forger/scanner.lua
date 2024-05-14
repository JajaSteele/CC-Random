local compass = peripheral.find("compass")

while compass.getFacing() ~= "east" do
    turtle.turnLeft()
end

local hub = peripheral.find("peripheralium_hub")
local stat, err = pcall(function()
    hub.unequip("peripheralworks:universal_scanner")

    turtle.place()

    sleep(0.25)

    local scanner = peripheral.find("universal_scanner")

    print("Scanning..")
    local scan_data = scanner.scan("block")
    print("Scan finished")

    local modems = {peripheral.find("modem")}

    local modem

    for k,v in pairs(modems) do
        if v.isWireless() == true then
            modem = modems[k]
        end
    end

    if modem then
        rednet.open(peripheral.getName(modem))
    end

    local reality_table = {}
    local compressed_table = {}

    print("Processing scan..")
    for i1=1,  #scan_data do
        local data = scan_data[i1]
        print(string.format("%.1f%%", (i1/#scan_data)*100))

        reality_table[#reality_table+1] = {
            pos = {
                x=data.x,
                y=data.y,
                z=data.z
            },
            data = {
                block = data.name
            }
        }
    end

    print("Size = "..#(textutils.serialise(reality_table)))
    print("Grouping..")
    for k,v in pairs(reality_table) do
        if compressed_table[v.data.block] then
            compressed_table[v.data.block][#compressed_table[v.data.block]+1] = v.pos
        else
            compressed_table[v.data.block] = {v.pos}
        end
    end

    local data_to_save = textutils.serialise(compressed_table)

    print("Grouped Size = "..#(data_to_save))

    while true do
        print("Enter the ID of the receiver:")
        local receiver_id = tonumber(read())
        if not receiver_id then
            print("Malformed ID!")
        else
            rednet.send(receiver_id, data_to_save, "reality_scan")
        end
    end
end)

if not stat then
    print(err)
    turtle.dig()
    hub.equip(1)
end
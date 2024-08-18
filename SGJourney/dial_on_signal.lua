local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local function engageChevron(number)
    if interface.engageSymbol and not (interface.rotateClockwise and settings.get("sg.slowdial")) then
        interface.engageSymbol(number)
    elseif interface.rotateClockwise then
        if interface.isChevronOpen(number) then
            interface.closeChevron()
        end

        if (number-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(number)
        else
            interface.rotateClockwise(number)
        end
        
        repeat
            sleep(0)
        until interface.getCurrentSymbol() == number

        
        interface.openChevron()
        sleep(0)
        interface.closeChevron()
    else
        print("Couldn't dial number!")
    end
end

local address = {}

print("Address:")
local temp_addr1 = read()
local temp_addr2 = split(temp_addr1, "-")
for k,v in ipairs(temp_addr2) do
    if tonumber(v) then
        address[#address+1] = tonumber(v)
    end
end

local side_list = {
    "back",
    "front",
    "top",
    "bottom",
    "left",
    "right"
}

local redstone_status = false
while true do
    interface.disconnectStargate()
    for k,v in ipairs(address) do
        engageChevron(v)
    end
    os.pullEvent("redstone")
    local new_status = false
    for k,side in pairs(side_list) do
        local signal = redstone.getInput(side)
        if signal then
            new_status = true
            break
        end
    end

    if redstone_status == false and new_status == true then
        engageChevron(0)
    elseif redstone_status == true and new_status == false then
        interface.disconnectStargate()
    end
    redstone_status = new_status
end
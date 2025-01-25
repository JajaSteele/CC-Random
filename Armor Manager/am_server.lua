local inv = peripheral.find("inventoryManager")
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

local args = {...}
local config = {}

if args[1] == "config" or not fs.exists("/.armor_config.txt") then
    print("Welcome to the configuration wizard!")
    print("Enter ID of trusted pocket")
    config.trusted = tonumber(read())

    local configfile = io.open("/.armor_config.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end
local function loadConfig()
    if fs.exists(".armor_config.txt") then
        local file = io.open(".armor_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open(".armor_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

loadConfig()

local function receiverThread()
    while true do
        local sender, msg, prot = rednet.receive("jjs_armor_order")
        if sender == config.trusted and type(msg) == "table" then
            rednet.send(sender, "", "jjs_armor_confirm")
            os.queueEvent("armor_order", msg)
            print("Added order")
        end
    end
end

local function senderThread()
    while true do
        local sender, msg, prot = rednet.receive("jjs_armor_fetch")
        if sender == config.trusted then
            local data = inv.getArmor()
            local clean_data = {}
            for k,v in pairs(data) do
                clean_data[v.slot] = {name=v.name, displayName=v.displayName}
            end
            rednet.send(sender, clean_data, "jjs_armor_data")
        end
    end
end

local function armorThread()
    while true do
        local event, order = os.pullEvent("armor_order")
        for k,v in pairs(order) do
            local list = inv.getItemsChest("front")
            local pull_slot
            for k,item in pairs(list) do
                if item.name == v.name and item.displayName == v.displayName then
                    pull_slot = item.slot
                    break
                end
            end
            if pull_slot then
                inv.removeItemFromPlayer("front", {fromSlot=v.slot})
                inv.addItemToPlayer("front", {toSlot=v.slot, fromSlot=pull_slot})
            end
        end
    end
end
parallel.waitForAny(receiverThread, senderThread, armorThread)
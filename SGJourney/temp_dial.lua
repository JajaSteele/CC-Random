local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

local function split(s, delimiter)
    local result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

term.clear()
term.setCursorPos(1,1)
print("-=# Hello! Welcome to the Temporary Dial program #=-")
print("Enter a Separator (character between each symbol number): ")
local separator = read()

print("Enter Address: (Separated by '"..separator.."')")
local address = read()

local temp_address = split(address, separator)

local dial_address = {}

for k,v in ipairs(temp_address) do
    if tonumber(v) then
        dial_address[#dial_address+1] = tonumber(v)
    end
end

dial_address[#dial_address+1] = 0

term.write("Dialing: ")

for k,v in ipairs(dial_address) do
    if interface.engageSymbol then
        interface.engageSymbol(v)
        term.write(v.." ")
    elseif interface.rotateClockwise then
        if (v-interface.getCurrentSymbol()) % 39 < 19 then
            interface.rotateAntiClockwise(v)
        else
            interface.rotateClockwise(v)
        end

        repeat
            sleep()
        until interface.isCurrentSymbol(v)

        interface.openChevron()
        sleep(0.125)
        interface.closeChevron()
        term.write(v.." ")
    end
end
print("")
print("Address dialed, proceeding..")

sleep(1)

print("Self-Deleting: "..shell.getRunningProgram())
fs.delete(shell.getRunningProgram())
print("Goodbye!")
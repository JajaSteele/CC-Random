local script_version = "1.1"

-- AUTO UPDATE STUFF
local curr_script = shell.getRunningProgram()
local script_io = io.open(curr_script, "r")
local local_version_line = script_io:read()
script_io:close()

local function getVersionNumbers(first_line)
    local major, minor, patch = first_line:match("local script_version = \"(%d+)%.(%d+)\"")
    return {tonumber(major) or 0, tonumber(minor) or 0}
end

local local_version = getVersionNumbers(local_version_line)

print("Local Version: "..string.format("%d.%d", table.unpack(local_version)))

local update_source = "https://raw.githubusercontent.com/JajaSteele/CC-Random/refs/heads/main/SGJourney/auto_dial_back.lua"
local update_request = http.get(update_source)
if update_request then
    local script_version_line = update_request.readLine()
    update_request:close()
    local script_version = getVersionNumbers(script_version_line)
    print("Remote Version: "..string.format("%d.%d", table.unpack(script_version)))

    if script_version[1] > local_version[1] or (script_version[1] == local_version[1] and script_version[2] > local_version[2]) then
        print("Remote version is newer, updating local")
        sleep(0.5)
        local full_update_request = http.get(update_source)
        if full_update_request then
            local full_script = full_update_request.readAll()
            full_update_request:close()
            local local_io = io.open(curr_script, "w")
            local_io:write(full_script)
            local_io:close()
            print("Updated local script!")
            sleep(0.5)
            print("REBOOTING")
            sleep(0.5)
            os.reboot()
        else
            print("Full update request failed")
        end
    end
else
    print("Update request failed")
end
-- END OF AUTO UPDATE

local interface = peripheral.find("advanced_crystal_interface")

local threads = {}
local pos = 1

while true do
    local event, address = os.pullEvent("stargate_incoming_wormhole")
    print("Incoming Wormhole!")

    if address then
        pcall(function()
            interface.closeIris()
        end)
        print("Awaiting connection")
        repeat
            sleep()
        until interface.getOpenTime() >= 5 or not interface.isStargateConnected()
        if #interface.getConnectedAddress() > 6 then
            address = interface.getConnectedAddress()
        end

        print("Awaiting kawoosh")
        repeat
            sleep()
        until interface.isWormholeOpen() or not interface.isStargateConnected()

        print("Closing gate")
        interface.disconnectStargate()

        print("Dialing back: "..table.concat(address, "-"))

        threads = {}
        pos = 1

        print("Preparing address table")
        local address_table = {}
        for k,v in ipairs(address) do
            address_table[#address_table+1] = {
                previous=address_table[#address_table] or nil,
                symbol=v
            }
        end
        address_table[#address_table+1] = {
            previous=address_table[#address_table] or nil,
            symbol=0
        }

        print("Preparing threads")
        for k, v in pairs(address_table) do
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

        print("Launching "..#threads.." threads")
        parallel.waitForAll(table.unpack(threads))

        print("Awaiting kawoosh")
        repeat
            sleep()
        until interface.isWormholeOpen() or not interface.isStargateConnected()
        pcall(function()
            interface.openIris()
        end)
    end
end
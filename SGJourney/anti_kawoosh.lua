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

local update_source = "https://raw.githubusercontent.com/JajaSteele/CC-Random/refs/heads/main/SGJourney/anti_kawoosh.lua"
local update_request = http.get(update_source)
if update_request then
    local script_version_line = update_request.readLine()
    update_request:close()
    local script_version = getVersionNumbers(script_version_line)
    print("Remote Version: "..string.format("%d.%d", table.unpack(script_version)))

    if script_version[1] > local_version[1] or (script_version[1] == local_version[1] and script_version[2] > local_version[2]) then
        print("Remote version is newer, updating local")
        local full_update_request = http.get(update_source)
        if full_update_request then
            local full_script = full_update_request.readAll()
            full_update_request:close()
            local local_io = io.open(curr_script, "w")
            local_io:write(full_script)
            local_io:close()
            print("Updated local script!")
            print("REBOOTING")
            os.reboot()
        else
            print("Full update request failed")
        end
    end
else
    print("Update request failed")
end
-- END OF AUTO UPDATE

local interface = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")

print("Starting anti-kawoosh iris program..")

if interface.isStargateConnected() and not interface.isWormholeOpen() and interface.getChevronsEngaged() < 2 then
    if interface.isStargateDialingOut() then
        os.queueEvent("stargate_chevron_engaged", 0, false, true)
    else
        os.queueEvent("stargate_incoming_connection")
    end
end

while true do
    local data = {os.pullEvent()}
    if data[1] == "stargate_incoming_connection" or (data[1] == "stargate_chevron_engaged" and data[6] == 0 and not data[5]) then
        print("Connection detected! Closing iris")
        interface.closeIris()
        repeat
            sleep(0.1)
        until interface.isWormholeOpen() or not interface.isStargateConnected()
        print("Kawoosh finished! Opening iris")
        interface.openIris()
    elseif data[1] == "stargate_disconnected" then
        print("Connection closed! Opening iris")
        interface.openIris()
    end
end
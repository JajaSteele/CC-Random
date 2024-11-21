fs.delete("/easydial.lua")
shell.run("wget https://raw.githubusercontent.com/JajaSteele/CC-Random/refs/heads/main/SGJourney/easydial.lua")

local delay = 0

local startup_program = ([[
    while true do
        local stat, err = pcall(function()
            print("Starting Program '&p' in ]]..delay..[[s")
            sleep(]]..delay..[[)
            if not shell.execute("&p") then
                error("Program Errored")
            end
        end)
        if not stat then 
            print(err) 
            print("Restarting in ]]..(1)..[[s") 
            sleep(]]..(1)..[[) 
            if err == "Terminated" then 
                print("Program Terminated") break 
            end 
        end
    end
]])

startup_program = startup_program:gsub("&p", "easydial.lua")

if fs.exists("/startup.lua") or fs.exists("/startup") then
    print("startup file will be overriden!")
    sleep(1)
end
print("Setting up startup file..")
local startup_io = io.open("/startup.lua", "w")
startup_io:write(startup_program)
startup_io:close()

print("Done!")
sleep(0.5)

term.clear()
term.setCursorPos(1,1)

if shell.getRunningProgram() then
    fs.delete(shell.getRunningProgram())
end

print("Peripherals:")
print("Required = - Optional = +")
print("- Interface (Basic/Crystal/Advanced)")
print("+ Wireless Modem (for address book dialing)")
print("+ Monitor (to display the status)")
print("+ Display Link (to display the status)")
print("+ Transceiver (for iris control)")
print("+ Environment Detector (for radiation warning)")
print("")
print("Press any key to reboot")

os.pullEvent("key")

os.reboot()
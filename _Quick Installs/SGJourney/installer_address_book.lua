fs.delete("/address_book.lua")
shell.run("wget https://raw.githubusercontent.com/JajaSteele/CC-Random/refs/heads/main/SGJourney/address_book.lua")

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

startup_program = startup_program:gsub("&p", "address_book.lua")

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

local running_path = shell.getRunningProgram()

if running_path and not running_path:match("wget%.lua") and not running_path:match("pastebin%.lua") then
    fs.delete(running_path)
end

print("Peripherals:")
print("Required = - Optional = +")
print("+ Wireless Modem (To dial on easydial)")
print("+ Chatbox (To share addresses in chat)")
print("")
print("Press any key to reboot")

os.pullEvent("key")

os.reboot()
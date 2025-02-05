local completion = require("cc.completion")

local function path_completion(text)
    if fs.exists(text) and fs.isDir(text) then
        return completion.choice(text, fs.list(text))
    else
        return completion.choice(text, fs.list(""))
    end
end

term.clear()
term.setCursorPos(1,1)
print("Welcome to EasyStartup!")
print("Enter the desired file to auto startup:")
local file = read(nil, nil, path_completion)
print("Enter a delay: (in seconds)")
local delay = read(nil, nil, nil, "1")

print("Restart on erroring? (y/n) (ignores Terminated)")
local pcall_mode = read(nil, nil, nil, "y")

local startup_file = io.open("startup.lua", "w")

local startup_program = ([[
    print("Starting Program '&p' in ]]..delay..[[s")
    sleep(]]..delay..[[)
    shell.run("&p")
]])

local startup_program_pcall = ([[
    while true do
        local stat, err = pcall(function()
            print("Starting Program '&p' in ]]..delay..[[s")
            sleep(]]..delay..[[)
            if not shell.run("&p") then
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


if pcall_mode == "y" or pcall_mode == "yes" or pcall_mode == "true" then
    startup_program = startup_program_pcall:gsub("&p", file)
else
    startup_program = startup_program:gsub("&p", file)
end

startup_file:write(startup_program)

startup_file:close()

print("Done!")

fs.delete("easystartup.lua")

print("Restarting computer..")

sleep(0.5)

os.reboot()
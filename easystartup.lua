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

local startup_file = io.open("startup.lua", "w")

local startup_program = ([[
    print("Starting Program '&p' in ]]..delay..[[s")
    sleep(]]..delay..[[)
    shell.execute("&p")
]])

startup_program = startup_program:gsub("&p", file)

startup_file:write(startup_program)

startup_file:close()

print("Done!")

fs.delete("easystartup.lua")

print("Restarting computer..")

sleep(0.5)

os.reboot()
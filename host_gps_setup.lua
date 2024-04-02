local startup = io.open("/startup.lua", "w")
print("Enter coords of this computer: (x y z)")
local coords = read()

startup:write([[print("Starting GPS Host!") shell.run("gps", "host", "]]..coords..[[")]])

startup:close()

fs.delete("/host_gps_setup.lua")
os.reboot()
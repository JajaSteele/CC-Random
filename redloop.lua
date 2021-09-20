local args = {...}


if args[1] == "setup" then
    if fs.exists("/config/") == false then
        fs.makeDir("/config")
    end
    if fs.exists("/config/redloop.txt") == false then
        print("Hello and welcome! Please choose your config!")
        config1 = {}
        print("1. Delay in Seconds: ")
        config1["delay"] = tonumber(io.read())
        print("Selected: "..config1["delay"])
        print("2. Side for Output:\n(top,bottom,left,right,front,back)")
        config1["side"] = io.read()
        print("Selected: "..config1["side"])
        configfile1 = fs.open("/config/redloop.txt", "w")
        configfile1.write(textutils.serialize(config1))
        configfile1.close()
    end

    if fs.exists("/config/redloop.txt") then
        print("Config successfully created!")
        configfile2 = fs.open("/config/redloop.txt", "r")
        config2 = configfile2.readAll()
        config3 = textutils.unserialize(config2)
        configfile2.close()

        delay = tonumber(config3["delay"])
        side = config3["side"]
    end

    if fs.exists("/startup.lua") == false then
        startupfile = fs.open("/startup.lua", "a")
        code = 'if fs.exists("/config/redloop.txt") then print("Config detected! Reading file..") configfile2 = fs.open("/config/redloop.txt", "r") config2 = configfile2.readAll() config3 = textutils.unserialize(config2) configfile2.close() delay = tonumber(config3["delay"]) side = config3["side"] end while true do os.sleep(delay) redstone.setOutput(side, true) os.sleep(0.1) redstone.setOutput(side, false) end'
        startupfile.write(code)
        startupfile.close()
        print("startup.lua created!")
    end
    shell.run("startup.lua")
end
if args[1] == "reset" then
    if fs.exists("/config/redloop.txt") then
        fs.delete("/config/redloop.txt")
        print("Deleted config.")
    end
    if fs.exists("/startup.lua") then
        fs.delete("/startup.lua")
        print("Deleted startup.")
    end
end
if args[1] == nil then
    print("Usage: redloop <option>\nOptions:\n reset: deletes the config and startup file\n setup: starts the config stuff")
end
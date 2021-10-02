local args = {...}

if args[1] ~= nil then
    if args[1] == "reset" then
        shell.run("rm /Base64")
        shell.run("rm /startup.lua")
        shell.run("rm /config/codescreen.txt")
    end
end

print("Checking for dependencies..")
if not fs.exists("/Base64") then
    print("Not found! Downloading..")
    shell.run("pastebin get QYvNKrXE Base64")
    print("Done!")
    os.loadAPI("/Base64")
    print("Library Loaded.\n")
    print("Validating..\n")
    os.sleep(0.1)
    test1 = Base64.encode("Test12345")
    test2 = Base64.decode(test1)
    os.sleep(0.1)
    if test2 == "Test12345" then
        print("Successfully Validated!")
    end
else
    print("All Dependencies found!")
    os.loadAPI("/Base64")
    print("Library Loaded.\n")
    print("Validating..\n")
    os.sleep(0.1)
    test1 = Base64.encode("Test12345")
    test2 = Base64.decode(test1)
    os.sleep(0.1)
    if test2 == "Test12345" then
        print("Successfully Validated!")
    end
end

function configsetup()
    if not fs.exists("/config") then
        fs.makeDir("/config")
    end
    config1 = {}
    configfile1 = fs.open("/config/codescreen.txt", "w")
    print("Welcome new user!")
    print("Configuration File Initialized and ready to write.")
    os.sleep(0.1)
    print("Please enter your new password: ")
    local newpass1 = read("*")
    print("Done! \nPlease enter output side: \n(bottom, top, back, front, right, left)")
    local newside1 = read()
    print("Done! Verifying Inputs..")
    validside1 = false
    if newpass1 ~= "" then
        for i = 1, #rs.getSides() do
            if newside1 == rs.getSides()[i] then
                validside1 = true
                break
            end
        end
        if validside1 then
            print("Validated! Saving settings..")
            config1["pass"] = Base64.encode(Base64.encode(Base64.encode(Base64.encode(newpass1))))
            config1["Comment"] = "Yup.. encrypted hehe"
            config1["side"] = newside1
            configfile1.write(textutils.serialize(config1))
            configfile1.close()
            print("Saved, testing file..")
            configfile1test = fs.open("/config/codescreen.txt", "r")
            config2 = textutils.unserialize(configfile1test.readAll())
            if config2["pass"] ~= nil and config2["side"] ~= nil then
                print("File validated!")
            end
            configfile1test.close()
        else
            print("Warning! Side isn't valid!\nSide input: "..newside1)
        end
    end
end

if not fs.exists("/config/codescreen.txt") then
    configsetup()
else
    configfile2 = fs.open("/config/codescreen.txt", "r")
    if configfile2.readAll() == "" then
        configsetup()
    end
end

if not fs.exists("/startup.lua") then
    print("startup.lua not found! Creating file..")
    sufile = fs.open("/startup.lua", "w")
    sufile.write( [[
        print("Checking for dependencies..\n")
if not fs.exists("/Base64") then
    term.setTextColor(colors.red)
    term.write("Warning! Dependency not found")
    x1,x2 = term.getCursorPos()
    term.setCursorPos(1,x2+1)
    term.write("Run codescreen.lua again")
    term.setCursorPos(1,x2+3)
    return
else
    print("Found all dependencies!\n")
    os.loadAPI("/Base64")
    print("Library Loaded.\n")
    print("Validating..\n")
    os.sleep(0.1)
    test1 = Base64.encode("Test12345")
    test2 = Base64.decode(test1)
    os.sleep(0.1)
    if test2 == "Test12345" then
        print("Successfully Validated!\n")
    end
    valid1 = true
end

if not fs.exists("/config/codescreen.txt") then
    term.setTextColor(colors.red)
    print("Warning! Config invalid/non-existant , Run codescreen.lua again!")
    return
else
    print("Config found! Reading..")
    configfile1 = fs.open("/config/codescreen.txt", "r")
    config1 = textutils.unserialize(configfile1.readAll())
    pass1 = config1["pass"]
    side1 = config1["side"]
    pass2 = Base64.decode(pass1)
    pass3 = Base64.decode(pass2)
    pass4 = Base64.decode(pass3)
    passfinal = Base64.decode(pass4)
end

if valid1 then
    print("Starting Program..")
    x2, y2 = term.getSize()
    term.setBackgroundColor(colors.black)
    while true do
        term.clear()
        term.setBackgroundColor(colors.gray)
        term.setCursorPos(1,1)
        for i1 = 1, 2 do
            term.setCursorPos(1,i1)
            for i = 1, x2 do
                term.write(" ")
            end
        end
        term.setCursorPos(x2/4,y2/3)
        term.setBackgroundColor(colors.gray)
        term.setTextColor(colors.blue)
        for i3 = 1, ((x2/4)*2)+4 do
            term.write("-")
        end
        string1 = "CodeScreen"
        x3, y3 = term.getCursorPos()
        term.setCursorPos((x3/2)+1,y3)
        term.setTextColor(colors.cyan)
        term.write(string1)
        term.setBackgroundColor(colors.lightGray)
        term.setCursorPos(x2/4,(y2/3)+1)
        for i4 = (y2/3)+1, (y2/3)+8 do
            term.setCursorPos(x2/4,i4)
            for i = 1, ((x2/4)*2)+4 do
                term.write(" ")
            end
        end
        term.setBackgroundColor(colors.black)
        term.setCursorPos(x2/4+2,(y2/3)+4)
        for i4 = (y2/3)+3, (y2/3)+5 do
            term.setCursorPos(x2/4+3,i4)
            for i = 1, ((x2/4)*2)-2 do
                term.write(" ")
            end
        end
        term.setTextColor(colors.lightBlue)
        term.setCursorPos(x2/4+3,(y2/3)+4)
        for i = 1, ((x2/4)*2)-2 do
            term.write("-")
        end
        term.setCursorPos(x2/4+3,(y2/3)+6)
        for i = 1, ((x2/4)*2)-2 do
            term.write("-")
        end
        string2 = "Enter Password:"
        term.setCursorPos((x2/4+3)+1,(y2/3)+3)
        term.setTextColor(colors.white)
        term.write("Enter Password Below:")
        term.setCursorPos((x2/4+3)+2,(y2/3)+5)
        passread = read("*")
        term.setBackgroundColor(colors.black)
        term.setCursorPos(x2/4+3,(y2/3)+3)
        for i = 1, ((x2/4)*2)-2 do
            term.write(" ")
        end
        if passread == passfinal then
            term.setCursorPos((x2/4+3)+3,(y2/3)+3)
            term.setTextColor(colors.lime)
            term.write("Password Accepted")
            rs.setOutput(side1, true)
            os.sleep(2)
            rs.setOutput(side1, false)
        else
            if passread == "reboot" then
                term.setCursorPos((x2/4+3)+2,(y2/3)+3)
                term.setTextColor(colors.red)
                term.write("Rebooting!")
                os.sleep(1)
                os.reboot()
            else
                term.setCursorPos((x2/4+3)+3,(y2/3)+3)
                term.setTextColor(colors.red)
                term.write("Password Refused")
                os.sleep(2)
            end
        end 
    end
end
]])

sufile.close()

if fs.exists("/startup.lua") then
    print("Done!")
    print("Rebooting computer..")
    os.reboot()
end
end
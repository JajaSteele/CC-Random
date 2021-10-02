local args = {...}
m = peripheral.find("monitor")

if args[1] ~= nil then
    if args[1] == "reset" then
        shell.run("rm /Base64")
        shell.run("rm /startup.lua")
        shell.run("rm /config/codescreen2.txt")
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
    test1 = Base64.encode("WYBP")
    test2 = Base64.decode(test1)
    os.sleep(0.1)
    if test2 == "WYBP" then
        print("Successfully Validated!")
    end
else
    print("All Dependencies found!")
    os.loadAPI("/Base64")
    print("Library Loaded.\n")
    print("Validating..\n")
    os.sleep(0.1)
    test1 = Base64.encode("WYBP")
    test2 = Base64.decode(test1)
    os.sleep(0.1)
    if test2 == "WYBP" then
        print("Successfully Validated!")
    end
end

function configsetup()
    if not fs.exists("/config") then
        fs.makeDir("/config")
    end
    config1 = {}
    configfile1 = fs.open("/config/codescreen2.txt", "w")
    print("Welcome new user!")
    print("Configuration File Initialized and ready to write.")
    os.sleep(0.1)
    print("Please enter your new password: \n(W,Y,B,P)")
    local newpass1 = read()
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
            configfile1test = fs.open("/config/codescreen2.txt", "r")
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

if not fs.exists("/config/codescreen2.txt") then
    configsetup()
else
    configfile2 = fs.open("/config/codescreen2.txt", "r")
    if configfile2.readAll() == "" then
        configsetup()
    end
end

if not fs.exists("/startup.lua") then
    print("startup.lua not found! Creating file..")
    sufile = fs.open("/startup.lua", "w")
    sufile.write( [[
        print("Checking for dependencies..\n")
        m = peripheral.find("monitor")
        if not fs.exists("/Base64") then
            term.setTextColor(colors.red)
            term.write("Warning! Dependency not found")
            x1,x2 = term.getCursorPos()
            term.setCursorPos(1,x2+1)
            term.write("Run codescreen2.lua again")
            term.setCursorPos(1,x2+3)
            return
        else
            print("Found all dependencies!\n")
            os.loadAPI("/Base64")
            print("Library Loaded.\n")
            print("Validating..\n")
            os.sleep(0.1)
            test1 = Base64.encode("WYBP")
            test2 = Base64.decode(test1)
            os.sleep(0.1)
            if test2 == "WYBP" then
                print("Successfully Validated!\n")
            end
            valid1 = true
        end
        
        if not fs.exists("/config/codescreen2.txt") then
            term.setTextColor(colors.red)
            print("Warning! Config invalid/non-existant , Run codescreen2.lua again!")
            return
        else
            print("Config found! Reading..")
            configfile1 = fs.open("/config/codescreen2.txt", "r")
            config1 = textutils.unserialize(configfile1.readAll())
            pass1 = config1["pass"]
            side1 = config1["side"]
            pass2 = Base64.decode(pass1)
            pass3 = Base64.decode(pass2)
            pass4 = Base64.decode(pass3)
            passfinal = Base64.decode(pass4)
        end
        
        if valid1 then
            function drawChar(x1,y1,c1,c2,c3)
                m.setCursorPos(x1,y1)
                m.setTextColor(c2)
                m.setBackgroundColor(c3)
                m.write(c1)
            end
            function drawBox(x1,y1,x2,y2,c1,c2,c3)
                x0, y0 = m.getCursorPos()
                xs, ys = m.getSize()
                m.setCursorPos(x1,y1)
                m.setBackgroundColor(c1)
                for i1 = 1, y2 do
                    m.setCursorPos(x1,y1+(i1-1))
                    for i2 = 1, x2 do
                        if c2 ~= nil then
                            m.setTextColor(c3)
                            m.write(c2)
                        else
                            m.write(" ")
                        end
                    end
                end
            end
        
            m.setTextColor(colors.white)
            m.setBackgroundColor(colors.black)
            m.clear()
        
            function clear1()
                x1, y1 = m.getSize()
                drawBox(1,1,x1,y1,colors.lightGray)
                drawBox(1,3,x1,1,colors.lightGray,"-",colors.gray)
                drawBox(4,1,1,y1,colors.lightGray,"|",colors.gray)
                drawChar(4,3,"O",colors.black,colors.lightGray)
                drawBox(1,1,3,2,colors.white)
                drawBox(1,4,3,2,colors.yellow)
                drawBox(5,1,3,2,colors.lightBlue)
                drawBox(5,4,3,2,colors.pink)
            end
        
            function blink1()
                drawChar(4,3,"O",colors.white,colors.lightGray)
                os.sleep(0.25)
                drawChar(4,3,"O",colors.black,colors.lightGray)
            end
            while true do
                codestring = ""
                while true do
                    clear1()
                    local event, side, x, y = os.pullEvent("monitor_touch")
                    x1, y1 = m.getSize()
                    if x < 4 and y < 3 then
                        codestring = codestring.."W"
                        blink1()
                        if string.len(codestring) >= string.len(passfinal) then break end
                    end
                    if x < 4 and y > 3 then
                        codestring = codestring.."Y"
                        blink1()
                        if string.len(codestring) >= string.len(passfinal) then break end
                    end
                    if x > 4 and y < 3 then
                        codestring = codestring.."B"
                        blink1()
                        if string.len(codestring) >= string.len(passfinal) then break end
                    end
                    if x > 4 and y > 3 then
                        codestring = codestring.."P"
                        blink1()
                        if string.len(codestring) >= string.len(passfinal) then break end
                    end
                end
                if codestring == passfinal then
                    drawChar(4,3,"V",colors.lime,colors.lightGray)
                    rs.setOutput(side1,true)
                    os.sleep(2)
                    drawChar(4,3,"O",colors.black,colors.lightGray)
                    rs.setOutput(side1,false)
                else
                    for i1 = 1, 8 do
                        drawChar(4,3,"D",colors.red,colors.lightGray)
                        os.sleep(0.125)
                        drawChar(4,3,"O",colors.black,colors.lightGray)
                        os.sleep(0.125)
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
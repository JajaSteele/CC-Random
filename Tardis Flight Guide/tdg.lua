
chatBox = peripheral.find("chatBox")

function drawMain()
    term.clear()
    term.setCursorPos(1,1)
    resX,resY = term.getSize()
    term.write(string.rep("-",resX))
    term.setCursorPos(1,resY)
    term.write(string.rep("-",resX))
    term.setCursorPos(1,2)
end

function loadUsername()
    file1read = io.open("/guide.cfg")
    if file1read ~= nil then
        mainUser = file1read:read("*a")
        enableChat = true
    else
        mainUser = "-none-"
        enableChat = false
    end
end

function chatPriv(t)
    if chatBox ~= nil and enableChat == true then
        chatBox.sendMessageToPlayer(t,mainUser)
    end
end

function chat(t)
    if chatBox ~= nil and enableChat == true then
        chatBox.sendMessage(t)
    end
end

loadUsername()

while true do
    drawMain()

    print("> Tardis Flight Guide < "..mainUser)

    print("\n1. Vortex Scrap")
    print("2. Time Winds")
    print("3. Spacial Drift")
    print("4. Low Artron Flow")
    print("5. Exterior Bulkhead")
    print("6. Dimensional Drift")
    print("7. Vertical Displacement Error")
    print("8. Time Ram")
    print("9. Artron Pocket\n")
    print("10. Exit to Shell")
    print("11. Set Username (for chat)\n")

    term.write("Select: ")
    res1 = tonumber(io.read())
    if res1 == 1 then
        drawMain()
        print("Vortex Scrap\n")
        print("  To Do:")
        term.setTextColor(colors.lightGray)
        print("    Randomiser\n    Exterior Facing")
        chatPriv("§c§lTO DO:\n§fRandomiser\nExterior Facing")
        term.setTextColor(colors.white)
        print("\n  If Fail:")
        term.setTextColor(colors.red)
        print("    Subsystems Damage")
        term.setTextColor(colors.white)
        print("\n  If Success:")
        term.setTextColor(colors.lime)
        print("    Nothing")
        term.setTextColor(colors.white)
        print("\n--=========--\nPress ENTER to return.")
        io.read()
    end
    if res1 == 2 then
        drawMain()
        print("Time Winds\n")
        print("  To Do:")
        term.setTextColor(colors.lightGray)
        print("    Throttle")
        chatPriv("§c§lTO DO:\n§fThrottle")
        term.setTextColor(colors.white)
        print("\n  If Fail:")
        term.setTextColor(colors.red)
        print("    Subsystems Damage")
        term.setTextColor(colors.white)
        print("\n  If Success:")
        term.setTextColor(colors.lime)
        print("    Nothing")
        term.setTextColor(colors.white)
        print("\n--=========--\nPress ENTER to return.")
        io.read()
    end
    if res1 == 3 then
        drawMain()
        print("Spatial Drift\n")
        print("  To Do:")
        term.setTextColor(colors.lightGray)
        print("    X/Y/Z Control")
        chatPriv("§c§lTO DO:\n§fX/Y/Z Control")
        term.setTextColor(colors.white)
        print("\n  If Fail:")
        term.setTextColor(colors.red)
        print("    Subsystems Damage")
        term.setTextColor(colors.white)
        print("\n  If Success:")
        term.setTextColor(colors.lime)
        print("    Nothing")
        term.setTextColor(colors.white)
        print("\n--=========--\nPress ENTER to return.")
        io.read()
    end
    if res1 == 4 then
        drawMain()
        print("Low Artron Flow\n")
        print("  To Do:")
        term.setTextColor(colors.lightGray)
        print("    Refueler Control")
        chatPriv("§c§lTO DO:\n§fRefueler Control")
        term.setTextColor(colors.white)
        print("\n  If Fail:")
        term.setTextColor(colors.red)
        print("    Loss of Fuel\n    2% chance of Leaky Capacitor")
        term.setTextColor(colors.white)
        print("\n  If Success:")
        term.setTextColor(colors.lime)
        print("    Nothing")
        term.setTextColor(colors.white)
        print("\n--=========--\nPress ENTER to return.")
        io.read()
    end
    if res1 == 5 then
        drawMain()
        print("Exterior Bulkhead\n")
        print("  To Do:")
        term.setTextColor(colors.lightGray)
        print("    Door Control")
        chatPriv("§c§lTO DO:\n§fDoor Control")
        term.setTextColor(colors.white)
        print("\n  If Fail:")
        term.setTextColor(colors.red)
        print("    Doors Opening in the vortex")
        term.setTextColor(colors.white)
        print("\n  If Success:")
        term.setTextColor(colors.lime)
        print("    Nothing")
        term.setTextColor(colors.white)
        print("\n--=========--\nPress ENTER to return.")
        io.read()
    end
    if res1 == 6 then
        drawMain()
        print("Dimensional Drift\n")
        print("  To Do:")
        term.setTextColor(colors.lightGray)
        print("    Dimensional Control")
        chatPriv("§c§lTO DO:\n§fDimensional Control")
        term.setTextColor(colors.white)
        print("\n  If Fail:")
        term.setTextColor(colors.red)
        print("    Destination Dimension changed")
        term.setTextColor(colors.white)
        print("\n  If Success:")
        term.setTextColor(colors.lime)
        print("    Nothing")
        term.setTextColor(colors.white)
        print("\n--=========--\nPress ENTER to return.")
        io.read()
    end
    if res1 == 7 then
        drawMain()
        print("Vertical Displacement Error\n")
        print("  To Do:")
        term.setTextColor(colors.lightGray)
        print("    Vertical Land Type Control")
        chatPriv("§c§lTO DO:\n§fVertical Land Type Control")
        term.setTextColor(colors.white)
        print("\n  If Fail:")
        term.setTextColor(colors.red)
        print("    Vertical Land Type is Randomized")
        term.setTextColor(colors.white)
        print("\n  If Success:")
        term.setTextColor(colors.lime)
        print("    Nothing")
        term.setTextColor(colors.white)
        print("\n--=========--\nPress ENTER to return.")
        io.read()
    end
    if res1 == 8 then
        while true do
            drawMain()
            print("Time Ram\n")
            print("  To Do:")
            print("\n    Pilot A:")
            term.setTextColor(colors.lightGray)
            print("      Communicator\n      Randomiser\n      Throttle")
            term.setTextColor(colors.white)
            print("\n    Pilot B:")
            term.setTextColor(colors.lightGray)
            print("      Communicator\n      Randomiser\n      Dimensional Control")
            term.setTextColor(colors.white)
            print("\n--=========--\nPress ENTER to go next page. Or \"bc\" to broadcast!")
            res3 = io.read()
            if res3 == "bc" then
                chat("§c§nTime Ram Broadcast!§c§l Please Follow Instructions:\n§ePilot A (§b"..mainUser.."§e) Do:\n  > Communicator\n  > Randomiser\n  > Throttle\n§ePilot B (§bOther Player§e) Do:\n  > Communicator\n  > Randomiser\n  > Dimensional Control")
            else
                drawMain()
                print("Time Ram\n")
                print("  If Fail:")
                term.setTextColor(colors.red)
                print("    Crashland/Damage for both tardises")
                term.setTextColor(colors.white)
                print("\n  If Success:")
                term.setTextColor(colors.lime)
                print("    Tardis A lands in Tardis B, no damage")
                term.setTextColor(colors.white)
                print("\n--=========--\nPress ENTER to return.")
                io.read()
                break
            end
        end
    end
    if res1 == 9 then
        drawMain()
        print("Artron Pocket\n")
        print("  To Do:")
        term.setTextColor(colors.lightGray)
        print("    Refueler Control")
        term.setTextColor(colors.white)
        print("\n  If Fail:")
        term.setTextColor(colors.red)
        print("    Nothing")
        term.setTextColor(colors.white)
        print("\n  If Success:")
        term.setTextColor(colors.lime)
        print("    Artron Energy boost")
        term.setTextColor(colors.white)
        print("\n--=========--\nPress ENTER to return.")
        io.read()
    end
    if res1 == 10 then
        drawMain()
        print("Restarting to Shell..")
        os.sleep(1)
        os.reboot()
    end
    if res1 == 11 then
        drawMain()
        term.write("Enter Username: ")
        res2 = io.read()

        file1 = io.open("/guide.cfg","w")
        file1:write(res2)
        file1:close()

        print("Username saved!\n("..res2..")")
        loadUsername()
        os.sleep(2)
        chatPriv("Hello!")
    end
end
modem = peripheral.find("modem")
rednet.open("right")

local completion = require "cc.shell.completion"
local complete = completion.build(
  { completion.choice, { "ranks", "reboot", "update_all", "startup", "config", "update_startup", "close_all", "open_all" } },
  completion.dir
)

shell.setCompletionFunction(shell.getRunningProgram(), complete)

args = {...}

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end
local function clearline()
    oldX,oldY = term.getCursorPos()
    term.write(string.rep(" ",mX))
    term.setCursorPos(oldX,oldY)
end
local function setpos(x,y)
    term.setCursorPos(x,y)
end
local function sethome(x,y)
    term.setCursorPos(x,y)
    homeX = x
    homeY = y
end
local function down()
    currX,currY = term.getCursorPos()
    term.setCursorPos(homeX,currY+1)
end
local function w(t)
    term.write(t)
end
local function wd(t)
    term.write(t)
    down()
end
local function sc(c)
    term.setTextColor(c)
end
local function sbc(c)
    term.setBackgroundColor(c)
end
local function wdc(t)
    term.write(t)
    clearline()
    down()
end
local function wc(t)
    term.write(t)
    clearline()
end

c = colors

mX,mY = term.getSize()

if args[1] == "reboot" then
    print("Are you sure you want to mass-reboot? (y/n)")
    res = io.read()
    if res == "y" then
        rednet.broadcast("reboot_now","reboot_protocol")
        os.reboot()
    end
end

if args[1] == "update_all" then
    print("Are you sure you want to mass-update? (y/n)")
    res = io.read()
    if res == "y" then
        rednet.broadcast("update_now","reboot_protocol")
        os.reboot()
    end
end

if args[1] == "open_all" then
    print("Are you sure you want to mass-open? (y/n)")
    res = io.read()
    if res == "y" then
        rednet.broadcast("open_all","reboot_protocol")
        os.reboot()
    end
end

if args[1] == "close_all" then
    print("Are you sure you want to mass-close? (y/n)")
    res = io.read()
    if res == "y" then
        rednet.broadcast("close_all","reboot_protocol")
        os.reboot()
    end
end

if args[1] == "startup" then
    shell.run("delete /startup.lua")
    shell.run("move "..shell.getRunningProgram().." /startup.lua")
    os.reboot()
end

if args[1] == "config" then
    newConfig = {}
    clear()
    w("Security Server Config Editor")
    sethome(2,2)
    wc("Discord Hook (y/n): ")
    res = io.read()
    if res == "y" then
        newConfig["dc"] = 1
        down()
        wc("Discord Hook Link:")
        newConfig["dc_link"] = io.read()
    else
        newConfig["dc"] = 0
    end
    down()
    wc("Execute on Startup? (y/n)")
    res = io.read()
    if res == "y" then
        newConfig["startup"] = 1
    else
        newConfig["startup"] = 0
    end
    down()
    wc("RedN Repeat Chan: ")
    newConfig["repeat_chan"] = tonumber(io.read())
    down()
    wc("RedN Broadcast Chan: ")
    newConfig["bc_chan"] = tonumber(io.read())
    down()
    fileconfig1 = io.open("/security_server.cfg","w")
    fileconfig1:write(textutils.serialise(newConfig))
    fileconfig1:close()
    clear()
    return
end

if fs.exists("/security_server.cfg") then
    fileconfig2 = io.open("/security_server.cfg","r")
    serv_config = textutils.unserialise(fileconfig2:read("*a"))
    fileconfig2:close()

    rednet.CHANNEL_BROADCAST = serv_config["repeat_chan"]
    rednet.CHANNEL_REPEAT = serv_config["bc_chan"]
else
    print("No Config! Run \""..shell.getRunningProgram().." config\" to add one.")
    return
end

if args[1] == "update_startup" or (fs.exists("/security_server.lua") and serv_config["startup"] == 1) then
    shell.run("delete /startup.lua")
    os.sleep(1)
    shell.run("move /security_server.lua /startup.lua")
    print("Done! Rebooting..")
    os.sleep(1)
    os.reboot()
end

if serv_config["dc"] == 1 and serv_config["dc_link"] ~= nil then
    shell.run("wget https://github.com/Wendelstein7/DiscordHook-CC/raw/master/DiscordHook.lua /DiscordHook.lua")
    if fs.exists("/DiscordHook.lua") then
        dc_hookapi = require("DiscordHook")
        success, hook = dc_hookapi.createWebhook(serv_config["dc_link"])
        success1 = hook.send("Program Connected: Security-Server ID "..os.getComputerID())
        if success1 then
            print("Successfully connected to the Webhook!")
        else
            print("Error! Unable to send webhook message")
        end
    end
end

function sendhook(t,u)
    if hook ~= nil and serv_config["dc"] == 1 then
        success = hook.send(t,u)
        if not success and args[1] == "debug" then
            print(success)
        end
    end
end

if args[1] == "ranks" then
    if fs.exists("/ranklist.txt") then
        filerank2 = io.open("/ranklist.txt","r")
        ranklist_edit = textutils.unserialise(filerank2:read("*a"))
        filerank2:close()
    else
        print("No Rank list!")
        ranklist_edit = {}
    end
    while true do
        clear()
        print("List of Ranks:")
        sethome(2,2)
        for k,v in pairs(ranklist_edit) do
            wd("- "..k.." >>> "..v)
        end
        setpos(1,mY)
        w("(A) Add/Edit entry | (R) Remove entry | (E) Exit")
        local event, character = os.pullEvent("char")
        if character == "a" then
            setpos(2,2)
            wc("Entry to edit: ")
            newName = io.read()
            setpos(2,2)
            wc("Assigned Rank (number): ")
            newRank = io.read()
            if newRank ~= "max" then
                ranklist_edit[newName] = tonumber(newRank)
            else
                ranklist_edit[newName] = "max"
            end
        end
        if character == "r" then
            setpos(2,2)
            clearline()
            w("Entry to Remove: ")
            removedName = io.read()
            ranklist_edit[removedName] = nil
        end
        if character == "e" then
            os.sleep(0.25)
            filerank3 = io.open("/ranklist.txt","w")
            filerank3:write(textutils.serialise(ranklist_edit))
            filerank3:close()
            setpos(2,2)
            wc("Saved Config!")
            os.sleep(0.25)
            clear()
            return
        end
        if character == "d" then
            setpos(2,2)
            clearline()
            w("Waiting for Modem Message")
            computerID, msg, protocol = rednet.receive()
            setpos(2,2)
            clearline()
            w("Received!")
            os.sleep(0.25)
            if protocol == "check_user" then
                check_data = textutils.unserialise(msg)
                ranklist_edit[check_data[1]] = check_data[2]

                rednet.send(computerID,"granted","check_user_result")
                sendhook("Granting rank "..check_data[2].." to "..check_data[1].." :white_check_mark:",check_data[3])

                os.sleep(0.25)
                filerank3 = io.open("/ranklist.txt","w")
                filerank3:write(textutils.serialise(ranklist_edit))
                filerank3:close()
                setpos(2,2)
                wc("Saved Config!")
                os.sleep(0.25)
                clear()
                os.reboot()
                return
            end
            if protocol == "security_part1" and msg == "give_server_id" then
                print("New Client: "..computerID)
                rednet.send(computerID,"","security_part2")
            end
        end
        os.sleep(0.5)
    end
end

if shell.getRunningProgram() ~= "startup.lua" and shell.getRunningProgram() ~= "/startup.lua" then
    print("To run the program on startup, Run \""..shell.getRunningProgram().." startup\"")
end

if fs.exists("/ranklist.txt") then
    filerank1 = io.open("/ranklist.txt","r")
    ranklist = textutils.unserialise(filerank1:read("*a"))
    filerank1:close()
else
    print("No Rank list! Run \""..shell.getRunningProgram().."\" to edit it.")
    return
end

print("Starting Server!")

function serverThread()
    while true do
        computerID, msg, protocol = rednet.receive()
        if protocol == "security_part1" and msg == "give_server_id" then
            print("New Client: "..computerID)
            rednet.send(computerID,"","security_part2")
        end

        if protocol == "check_user" then
            check_data = textutils.unserialise(msg)
            if ranklist[check_data[1]] == "max" then
                rednet.send(computerID,"granted","check_user_result")
                print(check_data[1].." has max rank, Granted for "..check_data[3])
                sendhook("Checking **"..check_data[1].."**, Rank: **MAX**, Required: **"..check_data[2].."**, Access Granted! :white_check_mark:",check_data[3])
            else
                user_rank_num = tonumber(ranklist[check_data[1]])
                if user_rank_num ~= nil and user_rank_num >= tonumber(check_data[2]) then
                    rednet.send(computerID,"granted","check_user_result")
                    print(check_data[1].." == "..user_rank_num.." >= "..check_data[2].." | Granted for "..check_data[3])
                    sendhook("Checking **"..check_data[1].."**, Rank: **"..user_rank_num.."**, Required: **"..check_data[2].."**, Access Granted! :white_check_mark:",check_data[3])
                else
                    rednet.send(computerID,"denied","check_user_result")
                    if user_rank_num ~= nil then
                        print(check_data[1].." == "..user_rank_num.." >= "..check_data[2].." | Denied for "..check_data[3])
                        sendhook("Checking **"..check_data[1].."**, Rank: **"..user_rank_num.."**, Required: **"..check_data[2].."**, Access Denied! :octagonal_sign:",check_data[3])
                    else
                        print(check_data[1].." == -1 >= "..check_data[2].." | Denied for "..check_data[3])
                        sendhook("Checking **"..check_data[1].."**, Rank: **NONE**, Required: **"..check_data[2].."**, Access Denied! :octagonal_sign:",check_data[3])
                    end
                end
            end
        end
        os.sleep(0.1)
    end
end

function touchThread()
    while true do
        local event, button, x, y = os.pullEvent("mouse_click")
        if button == 3 then
            clear()
            print("Exiting!")
            os.sleep(1)
            
        end
    end
end

parallel.waitForAny(serverThread,touchThread)
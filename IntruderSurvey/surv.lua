radar = peripheral.find("playerDetector")
chatbox = peripheral.find("chatBox")

args = {...}

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end

if not fs.exists("/surv.cfg") or args[1] == "cfg" then
    while true do
        newConfig = {}
        clear()
        print("Hello! Welcome to configuration util.")
        print("Enter your Username: (This username will be ignored by the radar)")
        newConfig["username"] = io.read()
        clear()
        print("Enable chat-alert? (true/false) (Will send msg to the username)")
        enable_chat = io.read()
        clear()

        if enable_chat == "true" then
            newConfig["enablechat"] = true
        else
            newConfig["enablechat"] = false
        end

        print("Enable Discord Integration? (true/false)")
        enable_dc = io.read()
        clear()

        if enable_dc == "true" then
            newConfig["enabledc"] = true
        else
            newConfig["enabledc"] = false
        end

        if newConfig["enabledc"] == true then
            print("Please copy your discord webhook link below:")
            newConfig["dc_hook"] = io.read()
            clear()
        end

        print("Enter the surveying range:")
        newConfig["range"] = tonumber(io.read())
        clear()

        print("Enter the name of this place:")
        newConfig["basename"] = io.read()
        clear()

        print("Confirm Config? (y/n)")
        print(table.concat(newConfig,"\n"))
        term.write("confirm: ")
        res1 = io.read()
        clear()
        if res1 == "y" then break end
    end
    fileconfig2 = io.open("/surv.cfg","w")
    print("Saving Config..")
    fileconfig2:write(textutils.serialize(newConfig))
    print("Done!")
    fileconfig2:close()
end

   
fileconfig1 = io.open("/surv.cfg","r")
if fileconfig1 ~= nil then
    config = textutils.unserialize(fileconfig1:read("*a"))
end
fileconfig1:close()

if config["enabledc"] == true then
    if not fs.exists("/lib") then
        fs.makeDir("/lib")
    end
    if fs.exists("/DiscordHook.lua") then
        dc_hookapi = require("/lib/DiscordHook")
    else
        shell.run("wget https://raw.githubusercontent.com/Wendelstein7/DiscordHook-CC/master/DiscordHook.lua /lib/DiscordHook.lua")
        dc_hookapi = require("/lib/DiscordHook")
    end
    success, hook = dc_hookapi.createWebhook(config["dc_hook"])
    success1 = hook.send("Program Connected: **Survey, "..config["basename"].."**")
    if success1 then
        print("Successfully connected to the Webhook!")
    else
        print("Error! Unable to send webhook message")
    end
end

local function msg(t,u)
    if config["enablechat"] == true and chatbox ~= nil then
        if u ~= nil then
            chatbox.sendMessage(t,u)
        else
            chatbox.sendMessage(t,config["basename"])
        end
    end
end

local function msgUser(t,d,u)
    if config["enablechat"] == true and chatbox ~= nil then
        if u ~= nil then
            chatbox.sendMessageToPlayer(t,d,u)
        else
            chatbox.sendMessageToPlayer(t,d,config["basename"])
        end
    end
end

local function msgOwner(t,u)
    if config["enablechat"] == true and chatbox ~= nil then
        if u ~= nil then
            if args[1] == "debug" then
                chatbox.sendMessage(t,u)
            else
                chatbox.sendMessageToPlayer(t,config["username"],u)
            end
        else
            if args[1] == "debug" then
                chatbox.sendMessage(t,config["basename"])
            else
                chatbox.sendMessageToPlayer(t,config["username"],config["basename"])
            end
        end
    end
end

local function compare(t1,value)
    local result = false
    for k,v in pairs(t1) do
        if v == value then
            result = true
            break
        end
    end
    return result
end

local function getDiff(t1,t2)
    difflist = {}
    dc_difflist = {}
    chat_difflist = {}
    print_difflist = {}
    if #t1 == #t2 then
        return nil
    else
        if #t1 > #t2 then
            for i1=1, #t1 do
                if not compare(t2,t1[i1]) and t1[i1] ~= config["username"] then
                    if args[1] == "debug" then
                        print("t1 bigger than t2 (joined)")
                        print(textutils.serialize(t1))
                        print(textutils.serialize(t2))
                    end
                    table.insert(difflist,t1[i1])
                    table.insert(chat_difflist,"§e§l"..t1[i1].." §aEntered §e§l"..config["basename"])
                    table.insert(print_difflist,t1[i1].." Entered "..config["basename"])
                    table.insert(dc_difflist,"**"..t1[i1].."** Entered **"..config["basename"].."**")
                end
            end
        elseif #t1 < #t2 then
            for i1=1, #t2 do
                if not compare(t1,t2[i1]) and t2[i1] ~= config["username"] then
                    if args[1] == "debug" then
                        print("t2 bigger than t1 (left)")
                        print(textutils.serialize(t1))
                        print(textutils.serialize(t2))
                    end
                    table.insert(difflist,t2[i1])
                    table.insert(chat_difflist,"§e§l"..t2[i1].." §cLeft §e§l"..config["basename"])
                    table.insert(print_difflist,t2[i1].." Left "..config["basename"])
                    table.insert(dc_difflist,"**"..t2[i1].."** Left **"..config["basename"].."**")
                end
            end
        end
        return difflist, chat_difflist, dc_difflist, print_difflist
    end
end


msgOwner("Starting Survey!")
msgOwner("Range: "..config["range"])

while true do
    if old_ply == nil then
        old_ply = radar.getPlayersInRange(config["range"])
    else
        old_ply = current_ply
    end
    current_ply = radar.getPlayersInRange(config["range"])
    os.sleep(1)
    diffs,chat_diffs,dc_diffs,print_diffs = getDiff(current_ply,old_ply)
    
    if chat_diffs ~= nil then
        if table.concat(chat_diffs,"\n") ~= "\n" then
            msgOwner(table.concat(chat_diffs,"\n"))
        end
    end
    if dc_diffs ~= nil then
        if table.concat(dc_diffs,"\n") ~= "\n" then
            hook.send(table.concat(dc_diffs,"\n"))
        end
    end
    if print_diffs ~= nil then
        if table.concat(print_diffs,"\n") ~= "\n" then
            print(table.concat(print_diffs,"\n"))
        end
    end
end
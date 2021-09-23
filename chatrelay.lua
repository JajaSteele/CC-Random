cb = peripheral.find("chatBox")
pd = peripheral.find("playerDetector")

if fs.exists("/DiscordHook.lua") == false then
    shell.execute("wget", "https://raw.githubusercontent.com/Wendelstein7/DiscordHook-CC/master/DiscordHook.lua", "DiscordHook.lua")
end
if fs.exists("/config/onlineplayer.txt") == false then
    print("1. Welcome! Please enter your webhook URL: ")
    whURL = io.read()
    print("2. Enter a name: ")
    name1 = io.read()
    print("3. Enter the server's name: ")
    servname1 = io.read()
    print("Configuration Done!")
    configfile1 = fs.open("/config/onlineplayer.txt", "w")
    config1 = {url=whURL,name=name1,server=servname1}
    configfile1.write(textutils.serialize(config1))
    configfile1.close()
    print(textutils.serialize(config1))
end
if fs.exists("/config/onlineplayer.txt") then
    configfile2 = fs.open("/config/onlineplayer.txt", "r")
    config2 = textutils.unserialize(configfile2.readAll())
    configfile2.close()
    if config2["name"] == nil or config2["server"] == nil or config2["url"] == nil then
        print("Warning! Invalid Configuration!")
        fs.delete("/config/onlineplayer.txt")
        print("Config deleted.. Please restart program!")
        return
    end
end
if fs.exists("/DiscordHook.lua") then
    DH = require("DiscordHook")
    success1, hook1 = DH.createWebhook(config2["url"])
    if not success1 then
        error("Webhook connection failed! Reason: " .. hook1)
    else
        hook1.send(":white_check_mark:  **Webhook Connection Established!** \nServer Name: "..config2["server"], config2["name"].." (CC-CR)")
        hook1.send("**Current Players:** \n```\n"..table.concat(pd.getOnlinePlayers(),"\n").."```",config2["server"])
    end
end

coPlayer = pd.getOnlinePlayers()
coPlayer2 = coPlayer

function onlinePlayers()
    while true do
        coPlayer = pd.getOnlinePlayers()
        if textutils.serialize(coPlayer) ~= textutils.serialize(coPlayer2) then
            if #coPlayer > #coPlayer2 then
                term.clear()
                term.setCursorPos(1,2)
                print("Player Joined! List:\n"..table.concat(coPlayer,"\n -"))
                if success1 then
                    hook1.send("**Player Joined!**\n```\n"..table.concat(coPlayer,"\n").."```", config2["server"])
                end
            end
            if #coPlayer < #coPlayer2 then
                term.clear()
                term.setCursorPos(1,2)
                print("Player Left! List:\n"..table.concat(coPlayer,"\n -"))
                if success1 then
                    hook1.send("**Player Left!** \n```\n"..table.concat(coPlayer,"\n").."```", config2["server"])
                end
            end
        end
        coPlayer2 = coPlayer
    end
end
function chatBridge()
    while true do
        event, username, message = os.pullEvent("chat")
        hook1.send("**<"..username..">**  "..message,config2["server"])
        coroutine.yield()
    end
end

parallel.waitForAny(onlinePlayers,chatBridge)
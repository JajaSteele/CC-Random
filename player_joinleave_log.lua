local player_detector = peripheral.find("playerDetector")

local webhook_link = ""

if fs.exists("webhook.txt") then
    local file = io.open("webhook.txt", "r")
    webhook_link = file:read("*a")
    file:close()
else
    print("Enter webhook link:")
    webhook_link = read()

    local file = io.open("webhook.txt", "w")
    file:write(webhook_link)
    file:close()
end

if not fs.exists("/DiscordHook.lua") then
    local file = http.get("https://raw.githubusercontent.com/Wendelstein7/DiscordHook-CC/master/DiscordHook.lua")
    local file2 = io.open("/DiscordHook.lua", "w")
    file2:write(file.readAll())
    file2:close()
    file.close()
end
local discord = require("DiscordHook")
local success, discord_hook = discord.createWebhook(webhook_link)
if not success then
    error("Failed to connect to webhook")
end

discord_hook.sendEmbed(
    "", --Msg
    "<:check:889161173692448800> Server Started!", --Title
    "The CC Server (and probably the minecraft server too) has started", --Description
    nil, --hyperlink
    0xFFAA44, --color
    nil, --image
    nil, --thumbnail
    "Stimky Server Hook", --username
    nil --avatar
)

local function testThread()
    os.queueEvent("playerJoin", "JajaSteele")
    print("Sent Event: Player Joined")
    os.queueEvent("playerLeave", "JajaSteele")
    print("Sent Event: Player Left")
end

local function mainThread()
    while true do
        local event, name = os.pullEvent()
        print("Event: "..event)
        local player_list = player_detector.getOnlinePlayers()
        if event == "playerJoin" then
            print("Player Joined")
            --discord_hook.sendEmbed(
            --    "", --Msg
            --    "**"..name.."** has joined the server", --Title
            --    "*There is now **"..#player_list.."** player"..(#player_list == 1 and "" or "s").." online*", --Description
            --    nil, --hyperlink
            --    0x99FF44, --color
            --    nil, --image
            --    "https://mc-heads.net/avatar/"..name, --thumbnail
            --    "Stimky Server Hook", --username
            --    nil --avatar
            --)
            discord_hook.send("*joined the server*", name, "https://mc-heads.net/avatar/"..name)
        elseif event == "playerLeave" then
            print("Player Left")
            --discord_hook.sendEmbed(
            --    "", --Msg
            --    "**"..name.."** has left the server", --Title
            --    "*There is now **"..#player_list.."** player"..(#player_list == 1 and "" or "s").." online*", --Description
            --    nil, --hyperlink
            --    0xFF5555, --color
            --    nil, --image
            --    "https://mc-heads.net/avatar/"..name, --thumbnail
            --    "Stimky Server Hook", --username
            --    nil --avatar
            --)
            discord_hook.send("*left the server*", name, "https://mc-heads.net/avatar/"..name)
        end
    end
end

parallel.waitForAll(testThread, mainThread)
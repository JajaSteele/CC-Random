local script_version = "1.3"

-- AUTO UPDATE STUFF
local curr_script = shell.getRunningProgram()
local script_io = io.open(curr_script, "r")
local local_version_line = script_io:read()
script_io:close()

local function getVersionNumbers(first_line)
    local major, minor, patch = first_line:match("local script_version = \"(%d+)%.(%d+)\"")
    return {tonumber(major) or 0, tonumber(minor) or 0}
end

local local_version = getVersionNumbers(local_version_line)

print("Local Version: "..string.format("%d.%d", table.unpack(local_version)))

local update_source = "https://raw.githubusercontent.com/JajaSteele/CC-Random/refs/heads/main/Cow%20Empire%20Security%20System/cess.lua"
local update_request = http.get(update_source)
if update_request then
    local script_version_line = update_request.readLine()
    update_request:close()
    local script_version = getVersionNumbers(script_version_line)
    print("Remote Version: "..string.format("%d.%d", table.unpack(script_version)))

    if script_version[1] > local_version[1] or (script_version[1] == local_version[1] and script_version[2] > local_version[2]) then
        print("Remote version is newer, updating local")
        sleep(0.5)
        local full_update_request = http.get(update_source)
        if full_update_request then
            local full_script = full_update_request.readAll()
            full_update_request:close()
            local local_io = io.open(curr_script, "w")
            local_io:write(full_script)
            local_io:close()
            print("Updated local script!")
            sleep(0.5)
            print("REBOOTING")
            sleep(0.5)
            os.reboot()
        else
            print("Full update request failed")
        end
    end
else
    print("Update request failed")
end
-- END OF AUTO UPDATE

if not fs.exists("/DiscordHook.lua") then
    local file = http.get("https://raw.githubusercontent.com/Wendelstein7/DiscordHook-CC/master/DiscordHook.lua")
    local file2 = io.open("/DiscordHook.lua", "w")
    file2:write(file.readAll())
    file2:close()
    file.close()
end

local args = {...}

local config = {}

if args[1] == "config" or not fs.exists("/config_cess.txt") then
    print("Welcome to the configuration wizard!")
    print("Name of this area?")
    config.name = read()

    print("Range? (in blocks)")
    config.range = tonumber(read())

    print("Startup with computer? (y/n)")
    config.autostart = read():lower()
    if config.autostart == "y" then
        config.autostart = true
        local startupfile = io.open("/startup","w")
        startupfile:write([[ shell.execute("]]..shell.getRunningProgram()..[[")]])
        startupfile:close()
    else
        config.autostart = false
        fs.delete("/startup")
    end

    print("Owner Name? (ignored by detection, and used for chat)")
    config.owner = read()

    print("Discord Integration? (y/n)")
    config.isDiscord = read():lower()
    if config.isDiscord == "y" then
        config.isDiscord = true
        print("Discord Webhook URL")
        config.discordWebhook = read()
    else
        config.isDiscord = false
    end

    print("Chatbox Integration? (y/n)")
    config.isChatbox = read():lower()
    if config.isChatbox == "y" then
        config.isChatbox = true
    else
        config.isChatbox = false
    end

    local configfile = io.open("/config_cess.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end

local configfile = io.open("/config_cess.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

local use_discord
local success, discord_hook

if config.isDiscord then
    local discord = require("DiscordHook")
    success, discord_hook = discord.createWebhook(config.discordWebhook)

    if not success then
        error(discord_hook)
    else
        use_discord = true
    end
end

local use_chatbox
local chatbox

if config.isChatbox then
    chatbox = peripheral.find("chatBox")
    if chatbox then
        use_chatbox = true
    end
end

local function getDate(timeOnly)
    if timeOnly then
        return os.date("%H.%M.%S")
    else
        return os.date("%d/%m %H.%M.%S")
    end
end

local chat_queue = {}

local function log(text)
    if use_discord then
        discord_hook.send(text, "CESS - "..(config.name or "Unknown"))
    end
    if use_chatbox then
        chat_queue[#chat_queue+1] = {text=text, timer=60}
    end
    term.setTextColor(colors.yellow)
    print('['..getDate().."] > "..text)
    term.setTextColor(colors.white)
end

local function logPlayers(data)
    local discord_text = ""
    for k,v in pairs(data) do
        if v.action == "entry" then
            discord_text = discord_text..":arrow_lower_right: **"..(v.name or "Unknown").."** > "..v.action.."\n"
        elseif v.action == "exit" then
            discord_text = discord_text..":no_entry: **"..(v.name or "Unknown").."** > "..v.action.."\n"
        end
    end

    if use_discord then
        discord_hook.send(discord_text, "CESS: "..(config.name or "Unknown"))
    end

    local chat_text = ""
    local spacing = ""
    if #data > 1 then
        chat_text = chat_text.."\n"
        spacing = "\n  "
    end
    for k,v in pairs(data) do
        if v.action == "entry" then
            chat_text = chat_text..spacing.."\xA7b"..(v.name or "Unknown").." \xA7e> \xA7a"..v.action
        elseif v.action == "exit" then
            chat_text = chat_text..spacing.."\xA7b"..(v.name or "Unknown").." \xA7e> \xA7c"..v.action
        end
    end

    if use_chatbox then
        chat_queue[#chat_queue+1] = {text=chat_text, timer=360}
    end
    print('['..getDate().."] > Security Notification:")
    for k,v in pairs(data) do
        if v.action == "entry" then
            term.setTextColor(colors.lime)
        elseif v.action == "exit" then
            term.setTextColor(colors.red)
        end
        print("  "..(v.name or "Unknown").." > "..v.action)
        term.setTextColor(colors.white)
    end
end

local function isInsideTable(name, table_to_search)
    for k,v in pairs(table_to_search) do
        if v == name then
            return true
        end
    end
    return false
end

local function tableDifference(table_one, table_two)
    local missing_from_one = {}
    local missing_from_two = {}

    for k,v in pairs(table_one) do
        if not isInsideTable(v, table_two) then
            missing_from_two[#missing_from_two+1] = v
        end
    end

    for k,v in pairs(table_two) do
        if not isInsideTable(v, table_one) then
            missing_from_one[#missing_from_two+1] = v
        end
    end

    return missing_from_one, missing_from_two
end

local function chatManager()
    while true do
        local to_delete = {}
        for k,v in ipairs(chat_queue) do
            if v.text and v.timer then
                local is_sent = chatbox.sendMessageToPlayer(v.text, config.owner, "\xA7bCESS\xA7f-\xA7d"..(config.name or "Unknown").."\xA7f")
                v.timer = v.timer-1
                if is_sent or v.timer < 0 then
                    to_delete[#to_delete+1] = k
                end
            end
        end

        for k,v in pairs(to_delete) do
            table.remove(chat_queue, v)
            table.remove(to_delete, k)
        end
        sleep(0.5)
    end
end

local radar = peripheral.find("playerDetector")

local function playerRadar()
    local old_list = {}
    local new_list = {}
    while true do
        old_list = new_list
        new_list = radar.getPlayersInRange(config.range or 100)

        local player_exits, player_entries = tableDifference(new_list, old_list)

        local security_data = {}
        for k,v in ipairs(player_exits) do
            if v ~= config.owner then
                security_data[#security_data+1] = {name=v, action="exit"}
            end
        end
        for k,v in ipairs(player_entries) do
            if v ~= config.owner then
                security_data[#security_data+1] = {name=v, action="entry"}
            end
        end

        if #security_data > 0 then
            logPlayers(security_data)
        end

        sleep(0.5)
    end
end

local function messageDetector()
    while true do
        local event, username, message, uuid, hidden = os.pullEvent("chat")
        if message == "cess_reboot" and username == config.owner or "" and hidden then
            chat_queue = {}
            os.reboot()
        end
    end
end

log("Starting CESS v"..string.format("%d.%d", table.unpack(local_version)).." ..")

parallel.waitForAll(playerRadar, chatManager, messageDetector)
local chat = peripheral.find("chatBox")
local config

local function clear()
    term.clear()
    term.setCursorPos(1,1)
end

local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

local function check(list_words,list_triggers)
    for k,v in pairs(list_words) do
        for k2,v2 in pairs(list_triggers) do
            if v == v2 then
                return true
            end
        end
    end
    return false
end

if fs.exists("/afk.txt") then
    local configfile = io.open("/afk.txt","r")
    config = textutils.unserialise(configfile:read("*a"))
    configfile:close()
else
    local newconfig = {}
    print("no config!")
    os.sleep(0.5)
    clear()
    print("Username:")
    newconfig.username = io.read()
    clear()
    print("Triggers: (separated by \",\")")
    newconfig.triggers = split(io.read(),",")
    clear()
    print("Computer Name:")
    newconfig.displayname = io.read()
    clear()
    print("Message to Send:")
    print("(Vars: %user% %author%)")
    newconfig.message = io.read()

    local configfile = io.open("/afk.txt","w")
    configfile:write(textutils.serialise(newconfig))
    configfile:close()
    config = newconfig
end

local afkEnabled = true

while true do
    local _, username, message, _, isHidden = os.pullEvent("chat")
    message = message:lower()
    local cmd = split(message," ")
    if isHidden and username == config.username then
        if cmd[1] == "afk" then
            if cmd[2] == "on" then
                afkEnabled = true
                chat.sendMessageToPlayer("AFK Enabled",username,config.displayname)
            elseif cmd[2] == "off" then
                afkEnabled = false
                chat.sendMessageToPlayer("AFK Disabled",username,config.displayname)
            elseif cmd[2] == "toggle" then
                afkEnabled = not afkEnabled
                chat.sendMessageToPlayer("AFK Toggled ("..tostring(afkEnabled)..")",username,config.displayname)
            end
        end
    elseif check(cmd,config.triggers) and username ~= config.username then
        local newmsg = config.message
        newmsg = newmsg:gsub("%%user%%","%%s")
        newmsg = string.format(newmsg,config.username)
        newmsg = newmsg:gsub("%%author%%","%%s")
        newmsg = string.format(newmsg,username)
        chat.sendMessage(newmsg,config.displayname)
        os.sleep(1.1)
        chat.sendMessageToPlayer("§cYou have been mentionned by §6"..username,config.username,config.displayname)
    end
end



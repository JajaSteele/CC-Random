local cb = peripheral.find("chatBox")

local config = {}

if fs.exists("cfg_rs_chat.txt") then
    local cfg_file = io.open("cfg_rs_chat.txt","r")
    config = textutils.unserialise(cfg_file:read("*a"))
    cfg_file:close()
else
    print("Starting Config!")
    print("Side?")
    config.side = read()
    print("Password?")
    config.pass = read()
    print("Need to be hidden? (y/n)")
    local res = read()
    if res == "y" or res == "yes" or res == "true" then
        res = true
    else
        res = false
    end
    config.needs_hidden = res
    print("Owner? (your username or \"NONE\")")
    config.owner = read()
    print("Response")
    config.answertrue = read()
    local cfg_file = io.open("cfg_rs_chat.txt","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

while true do
    local event, username, message, uuid, hidden = os.pullEvent("chat")
    if message == config.pass and (username == config.owner or config.owner == "NONE") and (hidden or not config.needs_hidden) then
        cb.sendMessageToPlayer(config.answertrue, username, "RS-Chat")
        redstone.setOutput(config.side, true)
        os.sleep(0.5)
        redstone.setOutput(config.side, false)
    end
end

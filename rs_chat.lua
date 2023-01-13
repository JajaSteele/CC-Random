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
    local cfg_file = io.open("cfg_rs_chat.txt","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

while true do
    local event, username, message = os.pullEvent("chat")
    if message == config.pass then
        cb.sendMessageToPlayer("§aPassword Accepted!",username,"RS-Chat")
        redstone.setOutput(config.side, true)
        os.sleep(0.5)
        redstone.setOutput(config.side, false)
    end
end

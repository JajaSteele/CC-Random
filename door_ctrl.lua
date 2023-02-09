local cb = peripheral.find("chatBox")

local config = {}

if fs.exists("cfg_door_ctrl.txt") then
    local cfg_file = io.open("cfg_door_ctrl.txt","r")
    config = textutils.unserialise(cfg_file:read("*a"))
    cfg_file:close()
else
    print("Starting Config!")
    print("Close Side?")
    config.side_close = read()
    print("Open Side?")
    config.side_open = read()
    print("Password?")
    config.pass = read()
    local cfg_file = io.open("cfg_door_ctrl.txt","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

local function waitMsg(name)
    while true do
        local event, username, message = os.pullEvent("chat")
        if name and name == username then
            return message
        elseif not name then
            return message
        end
    end
end

while true do
    local event, username, message = os.pullEvent("chat")
    if message:lower():sub(1,8) == "jjs door" then
        local choice = message:lower():sub(10,message:len())
        os.sleep(1)
        if choice == "open" or choice == "close" then
            cb.sendMessageToPlayer("Password? §7(use $ prefix to hide it from other players)", username, "Door Control")
            local pass = waitMsg(username)
            if pass == config.pass then
                cb.sendMessageToPlayer("§aPassword Accepted!", username, "Door Control")
                os.sleep(1)
                if choice == "open" then
                    rs.setOutput(config.side_open, true)
                    os.sleep(0.5)
                    rs.setOutput(config.side_open, false)
                elseif choice == "close" then
                    rs.setOutput(config.side_close, true)
                    os.sleep(0.5)
                    rs.setOutput(config.side_close, false)
                end
            else
                cb.sendMessageToPlayer("§cPassword Denied!", username, "Door Control")
            end
        else
            cb.sendMessageToPlayer("§cIncorrect Action.", username, "Door Control")
        end
    end
end

local waypoint_template = '[name:"%s", x:%s, y:%s, z:%s, dim:%s]'
local chat_box = peripheral.find("chatBox")
print("Enter your username:")
local username = read()

while true do
    term.clear()
    term.setCursorPos(1,1)
    print("Enter observable TP command:")
    local cmd = read()
    -- /observable tp minecraft:overworld position -1424 128 -80
    local dim, x, y, z = cmd:match("/observable tp ([%w_:]-) position ([%-]?%d+) ([%-]?%d+) ([%-]?%d+)")
    if dim and x and y and z then
        local waypoint = string.format(waypoint_template, "<OBVS> "..x..", "..y..", "..z, x, y, z, dim)
        if username == "" then
            chat_box.sendMessage(waypoint)
        else
            chat_box.sendMessageToPlayer(waypoint, username, "AP (Whisper)")
        end
    else
        print("Invalid Command")
    end
end
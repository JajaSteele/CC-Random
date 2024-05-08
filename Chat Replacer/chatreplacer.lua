local chat = peripheral.find("chatBox")

while true do
    local event, username, msg, uuid, hidden = os.pullEvent("chat")

    if hidden then
        local formatted_msg = msg:gsub("&(%S)", "\xA7%1")
        chat.sendMessage(formatted_msg, username, "<>")
        print("<"..username.."> "..msg)
    end
end


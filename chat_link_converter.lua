local chatbox = peripheral.find("chatBox")

while true do
    local event, username, message, uuid, ishidden = os.pullEvent("chat")
    local link = (message.." "):match(".*(http[s]?://.+)%s")

    if link then
        local domain = link:match(".+//(%w+%.%w+)")

        local str = '["",{"text":"(","color":"gray"},{"text":"%s","color":"aqua","clickEvent":{"action":"open_url","value":"%s"},"hoverEvent":{"action":"show_text","contents":"%s"}},{"text":")","color":"gray"}]'
        str = string.format(str, domain, link, "Click to open")

        chatbox.sendFormattedMessage(str, username, "<>")
    end
end
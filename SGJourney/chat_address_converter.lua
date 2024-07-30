local chat = peripheral.find("chatBox")

local chat_queue = {}

local function queueMessage(msg, prefix, brackets)
    chat_queue[#chat_queue+1] = {
        type = "global",
        message = msg,
        prefix = prefix,
        brackets = brackets,
        sent = false
    }
end

local function queueMessageFormatted(msg_json, prefix, brackets)
    chat_queue[#chat_queue+1] = {
        type = "global_json",
        message = msg_json,
        prefix = prefix,
        brackets = brackets,
        sent = false
    }
end

local json_prefabs = {
    header = {{text="Addresses: "},{text="(Click to copy)",color="gray"}},
    header_tiny = {{text="Click to Copy: "}},
    newline = {{text="\n"}},
    address_template = {{text="    ",color="green",hoverEvent={action="show_text",contents="Click to Copy"}},{text="$ADDRESS",color="green",clickEvent={action="copy_to_clipboard",value="$ADDRESS"},hoverEvent={action="show_text",contents="Click to Copy"}}},
    address_template_tiny = {{text="",color="green",hoverEvent={action="show_text",contents="Click to Copy"}},{text="$ADDRESS",color="green",clickEvent={action="copy_to_clipboard",value="$ADDRESS"},hoverEvent={action="show_text",contents="Click to Copy"}}}
}

local function multi_serializejson(...)
    local output = '[""'
    for k,v in ipairs({...}) do
        if type(v) == "string" then
            output = output..","..v
        elseif type(v) == "table" then
            output = output..","..textutils.serialiseJSON(v)
        end
    end
    return output..']'
end

local function chat_thread()
    while true do
        for k, msg_to_send in ipairs(chat_queue) do
            if msg_to_send.sent then
                table.remove(chat_queue, k)
            else
                if msg_to_send.type == "private" then
                    local stat = chat.sendMessageToPlayer(msg_to_send.message, msg_to_send.player, msg_to_send.prefix, msg_to_send.brackets)
                    if stat then
                        chat_queue[k].sent = true
                    end
                    sleep(0.5)
                elseif msg_to_send.type == "global" then
                    local stat = chat.sendMessage(msg_to_send.message, msg_to_send.prefix, msg_to_send.brackets)
                    if stat then
                        chat_queue[k].sent = true
                    end
                    sleep(0.5)
                elseif msg_to_send.type == "toast" then
                    local stat = chat.sendToastToPlayer(msg_to_send.message, msg_to_send.title, msg_to_send.player, msg_to_send.prefix, msg_to_send.brackets)
                    if stat then
                        chat_queue[k].sent = true
                    end
                    sleep(0.5)
                elseif msg_to_send.type == "global_json" then
                    local stat = chat.sendFormattedMessage(msg_to_send.message, msg_to_send.prefix, msg_to_send.brackets)
                    if stat then
                        chat_queue[k].sent = true
                    end
                    sleep(0.5)
                end
            end
            sleep()
        end
        sleep(0.25)
    end
end

local function chat_listener()
    while true do
        local event, username, msg, uuid, hidden = os.pullEvent("chat")

        if not hidden then
            local address_list = {}
            for potential_address in msg:gmatch("-[%d-]+") do
                print(potential_address)
                local new_address = {}
                for number in potential_address:gmatch("%d+") do
                    new_address[#new_address+1] = number
                end
                if #new_address >= 6 and #new_address <= 8 then
                    address_list[#address_list+1] = new_address
                end
            end
            if #address_list > 0 then
                local address_prefabs = {}
                for k,v in ipairs(address_list) do
                    if #address_list > 1 then
                        address_prefabs[#address_prefabs+1] = textutils.serialiseJSON(json_prefabs.address_template):gsub("$ADDRESS", "-"..table.concat(v, "-").."-")
                        if k < #address_list then
                            address_prefabs[#address_prefabs+1] = json_prefabs.newline
                        end
                    else
                        address_prefabs[#address_prefabs+1] = textutils.serialiseJSON(json_prefabs.address_template_tiny):gsub("$ADDRESS", "-"..table.concat(v, "-").."-")
                        if k < #address_list then
                            address_prefabs[#address_prefabs+1] = json_prefabs.newline
                        end
                    end
                end
                if #address_list > 1 then
                    queueMessageFormatted(multi_serializejson(json_prefabs.header, json_prefabs.newline, table.unpack(address_prefabs)), "@", "[]")
                else
                    queueMessageFormatted(multi_serializejson(json_prefabs.header_tiny, table.unpack(address_prefabs)), "@", "[]")
                end
            end
        end
    end
end

--queueMessageFormatted(multi_serializejson(json_prefabs.header, json_prefabs.newline), "@", "[]")

parallel.waitForAny(chat_thread, chat_listener)


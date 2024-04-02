local json_string = '["",{"text":"<","color":"gray"},{"text":"%d","color":"green"},{"text":">(","color":"gray"},{"text":"%s","color":"aqua"},{"text":")","color":"gray"},{"text":" New Pos: "},{"text":"[$POS_X, $POS_Y, $POS_Z]","color":"gold","clickEvent":{"action":"copy_to_clipboard","value":"$POS_X $POS_Y $POS_Z"},"hoverEvent":{"action":"show_text","contents":"Click to copy"}}]'

local function sendPosMsg(x,y,z)
    local cb = peripheral.find("chatBox")
    if cb then
        local msg_to_send = string.format(json_string, os.getComputerID(), os.getComputerLabel())
        msg_to_send = msg_to_send:gsub("$POS_X", tostring(x))
        msg_to_send = msg_to_send:gsub("$POS_Y", tostring(y))
        msg_to_send = msg_to_send:gsub("$POS_Z", tostring(z))
        cb.sendFormattedMessageToPlayer(msg_to_send, "JajaSteele")
    end
end
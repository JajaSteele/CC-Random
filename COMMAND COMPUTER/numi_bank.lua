local chatbox = peripheral.find("chatBox")
local pld = peripheral.find("playerDetector")

local colors = {
    "\xA7c",
    "\xA7b",
    "\xA77",
    "\xA7e",
    "\xA76",
    "\xA78",
}
local names = {
    "spur",
    "bevel",
    "sprocket",
    "cog",
    "crown",
    "sun",
}
local preset = {
    raw_balance = '["",{"text":"Player ","color":"green"},{"text":"%s","color":"aqua"},{"text":" has ","color":"green"},{"text":"%d\xA4","color":"red","clickEvent":{"action":"suggest_command","value":"$bank bal detail"},"hoverEvent":{"action":"show_text","contents":"Click to view detailed balance (or do $bank bal detail)"}}]',
    detail_balance = '["",{"text":"Player ","color":"green"},{"text":"%s","color":"aqua"},{"text":" has:","color":"green"},{"text":"\n"},{"text":"- %d spur","color":"red","hoverEvent":{"action":"show_text","contents":"1\xA4"}},{"text":"\n"},{"text":"- %d bevel","color":"aqua","hoverEvent":{"action":"show_text","contents":"8\xA4"}},{"text":"\n"},{"text":"- %d sprocket","color":"gray","hoverEvent":{"action":"show_text","contents":"16\xA4"}},{"text":"\n"},{"text":"- %d cog","color":"yellow","hoverEvent":{"action":"show_text","contents":"64\xA4"}},{"text":"\n"},{"text":"- %d crown","color":"gold","hoverEvent":{"action":"show_text","contents":"512\xA4"}},{"text":"\n"},{"text":"- %d Sun","color":"dark_gray","hoverEvent":{"action":"show_text","contents":"4096\xA4"}},{"text":"\n"},{"text":"Total: ","color":"green"},{"text":"%d\xA4","color":"red"}]',
    help = '["",{"text":"Available commands:","color":"green"},{"text":"\n"},{"text":"- bal","color":"aqua","clickEvent":{"action":"suggest_command","value":"$bank bal"},"hoverEvent":{"action":"show_text","contents":"Click to auto fill"}},{"text":"\n","hoverEvent":{"action":"show_text","contents":"Click to auto fill"}},{"text":"- bal detail","color":"aqua","clickEvent":{"action":"suggest_command","value":"$bank bal detail"},"hoverEvent":{"action":"show_text","contents":"Click to auto fill"}},{"text":"\n","hoverEvent":{"action":"show_text","contents":"Click to auto fill"}},{"text":"- pay <player> <amount>","color":"aqua","clickEvent":{"action":"suggest_command","value":"$bank pay"},"hoverEvent":{"action":"show_text","contents":"Click to auto fill"}}]'
}

local function isPlayerOnline(name)
    local online = pld.getOnlinePlayers()
    for k,v in pairs(online) do
        if v == name then
            return true
        end
    end
    return false
end

local chat_queue = {}

local function mainThread()
    while true do
        local event, username, message, uuid, hidden = os.pullEvent("chat")
        if hidden then
            local args = {}
            for arg in message:gmatch("[%w]+") do
                args[#args+1] = arg
            end
            if args[1] == "bank" then
                print("["..username.."] > "..table.concat(args, " "))
                local stat, output = commands.exec("/numismatics view "..username)
                if stat then
                    local msg
                    local raw_spur = tonumber(output[1]:match("has (%d+)"))
                    print("["..username.."] > ("..raw_spur..")")
                    if args[2] == "bal" then
                        if args[3] == "detail" then
                            local bank = {
                                math.floor((raw_spur)%8), -- spur
                                math.floor((raw_spur/8)%2), -- bevel
                                math.floor((raw_spur/16)%4), -- sprocket
                                math.floor((raw_spur/64)%8), -- cog
                                math.floor((raw_spur/512)%8), -- crown
                                math.floor((raw_spur/4096)), -- sun
                            }
                            msg = string.format(preset.detail_balance, username, bank[1], bank[2], bank[3], bank[4], bank[5], bank[6], raw_spur)
                        else
                            msg = string.format(preset.raw_balance, username, raw_spur)
                        end
                        chatbox.sendFormattedMessageToPlayer(msg, username, "\xA7aBank\xA7f", "[]")
                    elseif args[2] == "pay" then
                        if args[3] then
                            if isPlayerOnline(args[3]) or args[5] == "bypass" then 
                                local pay_amount = tonumber(args[4])
                                if not pay_amount or pay_amount < 1 then
                                    chatbox.sendMessageToPlayer("\xA7cError: Invalid amount", username, "\xA7aBank\xA7f", "[]")
                                else
                                    pay_amount = math.floor(pay_amount)
                                    if raw_spur >= pay_amount then
                                        local deduct_stat = commands.exec("/numismatics deduct "..username.." "..pay_amount.." SPUR")
                                        if deduct_stat then
                                            local pay_stat = commands.exec("/numismatics pay "..args[3].." "..pay_amount.." SPUR")
                                            if pay_stat then
                                                chatbox.sendMessageToPlayer("\xA7aSuccessfully paid \xA7c"..pay_amount.."\xA4 \xA7ato "..args[3], username, "\xA7aBank\xA7f", "[]")
                                            else
                                                chatbox.sendMessageToPlayer("\xA7cError: Couldn't deposit money to "..args[3]..", refunding..", username, "\xA7aBank\xA7f", "[]")
                                                print("Error while paying money, refunding")
                                                local refund_stat = commands.exec("/numismatics pay "..username.." "..pay_amount.." SPUR")
                                            end
                                        else
                                            chatbox.sendMessageToPlayer("\xA7cError: Couldn't deduct money from "..username, username, "\xA7aBank\xA7f", "[]")
                                            print("Error while deducting money")
                                        end
                                    else
                                        chatbox.sendMessageToPlayer("\xA7cError: Not enough money", username, "\xA7aBank\xA7f", "[]")
                                        print("Not enough money")
                                    end
                                end
                            else
                                chatbox.sendMessageToPlayer("\xA7cError: Player needs to be online \n(or add 'bypass' after the amount argument, MONEY WILL BE VOIDED IF INVALID PLAYER)", username, "\xA7aBank\xA7f", "[]")
                                print("Player not online")
                            end
                        else
                            chatbox.sendMessageToPlayer("\xA7cError: Missing player argument", username, "\xA7aBank\xA7f", "[]")
                            print("No Player Arg")
                        end
                    else
                        chatbox.sendFormattedMessageToPlayer(preset.help, username, "\xA7aBank\xA7f", "[]")
                    end
                else
                    print("Couldn't fetch balance")
                    chatbox.sendMessageToPlayer("\xA7cError: Couldn't fetch balance", username, "\xA7aBank\xA7f", "[]")
                end
            end
        end
    end
end
local script_version = "1.1"

-- AUTO UPDATE STUFF
local curr_script = shell.getRunningProgram()
local script_io = io.open(curr_script, "r")
local local_version_line = script_io:read()
script_io:close()

local function getVersionNumbers(first_line)
    local major, minor, patch = first_line:match("local script_version = \"(%d+)%.(%d+)\"")
    return {tonumber(major) or 0, tonumber(minor) or 0}
end

local local_version = getVersionNumbers(local_version_line)

print("Local Version: "..string.format("%d.%d", table.unpack(local_version)))

local update_source = "https://raw.githubusercontent.com/JajaSteele/CC-Random/refs/heads/main/CC%20Bot%20Link/client.lua"
local update_request = http.get(update_source)
if update_request then
    local script_version_line = update_request.readLine()
    update_request:close()
    local script_version = getVersionNumbers(script_version_line)
    print("Remote Version: "..string.format("%d.%d", table.unpack(script_version)))

    if script_version[1] > local_version[1] or (script_version[1] == local_version[1] and script_version[2] > local_version[2]) then
        print("Remote version is newer, updating local")
        sleep(0.5)
        local full_update_request = http.get(update_source)
        if full_update_request then
            local full_script = full_update_request.readAll()
            full_update_request:close()
            local local_io = io.open(curr_script, "w")
            local_io:write(full_script)
            local_io:close()
            print("Updated local script!")
            sleep(0.5)
            print("REBOOTING")
            sleep(0.5)
            os.reboot()
        else
            print("Full update request failed")
        end
    end
else
    print("Update request failed")
end
-- END OF AUTO UPDATE

local chat_array = {peripheral.find("chatBox")}
local player_detector = peripheral.find("playerDetector")

if not fs.exists("/json.lua") then
    shell.run("wget https://github.com/rxi/json.lua/raw/refs/heads/master/json.lua /json.lua")
end
local json = require("json")

if not fs.exists("/ccryptolib") then
    fs.makeDir("/ccryptolib")
    shell.run("wget https://github.com/migeyel/ccryptolib/raw/refs/heads/main/ccryptolib/chacha20.lua /ccryptolib/chacha20.lua")
    shell.run("wget https://github.com/migeyel/ccryptolib/raw/refs/heads/main/ccryptolib/random.lua /ccryptolib/random.lua")
    shell.run("wget https://github.com/migeyel/ccryptolib/raw/refs/heads/main/ccryptolib/blake3.lua /ccryptolib/blake3.lua")
    fs.makeDir("/ccryptolib/internal")
    shell.run("wget https://github.com/migeyel/ccryptolib/raw/refs/heads/main/ccryptolib/internal/util.lua /ccryptolib/internal/util.lua")
    shell.run("wget https://github.com/migeyel/ccryptolib/raw/refs/heads/main/ccryptolib/internal/packing.lua /ccryptolib/internal/packing.lua")
end
local rand = require "ccryptolib.random"
local chacha20 = require "ccryptolib.chacha20"

if not fs.exists("/base64.lua") then
    shell.run("wget https://github.com/iskolbin/lbase64/raw/refs/heads/master/base64.lua base64.lua")
end
local base64 = require("base64")

local function fill(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end
    for i1=1, (x1-x)+1 do
        for i2=1, (y1-y)+1 do
            term.setCursorPos(x+i1-1,y+i2-1)
            term.write(char or " ")
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

local function rect(x,y,x1,y1,bg,fg,char, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()
    local old_posx,old_posy = term.getCursorPos()
    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    local sizeX=(x1-x)+1
    local sizeY=(y1-y)+1

    for i1=1, sizeX do
        for i2=1, sizeY do
            if i1 == 1 or i1 == sizeX or i2 == 1 or i2 == sizeY then
                term.setCursorPos(x+i1-1,y+i2-1)
                if char == "keep" then
                    term.write()
                else
                    term.write(char or " ")
                end
            end
        end
    end
    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local function write(x,y,text,bg,fg, target)
    local curr_term = term.current()
    term.redirect(target or curr_term)
    local old_posx,old_posy = term.getCursorPos()
    local old_bg = term.getBackgroundColor()
    local old_fg = term.getTextColor()

    if bg then
        term.setBackgroundColor(bg)
    end
    if fg then
        term.setTextColor(fg)
    end

    term.setCursorPos(x,y)
    term.write(text)

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
end

local args = {...}

local config = {}

local _rinit = false
--- Checks if the random byte generator has been initialized, initializes it if not.
local function init_rand()
  if not _rinit then
    rand.initWithTiming()
    print("Initializing random..")
    _rinit = true
  end
end

local DEBUG_MODE = false
local db_print = function(...)
    if DEBUG_MODE then
        local entries = {...}
        for k,v in ipairs(entries) do
            print(v)
        end
    end
end

local function loadConfig()
    if fs.exists(".ccdl_config.txt") then
        local file = io.open(".ccdl_config.txt", "r")
        config = textutils.unserialise(file:read("*a"))
        file:close()
    end
end
local function writeConfig()
    local file = io.open(".ccdl_config.txt", "w")
    file:write(textutils.serialise(config))
    file:close()
end

if args[1] == "config" or not fs.exists("/.ccdl_config.txt") then
    term.clear()
    term.setCursorPos(1,1)

    print("Welcome to the config wizard!")
    print("")
    print("## Paste your code here ##")
    print("")
    print("(If you don't have a code, do the /link command with the bot first)")

    while true do
        local event, pasted_data = os.pullEvent("paste")
        local decrypted
        local decoded
        local stat, err = pcall(function ()
            decrypted = base64.decode(pasted_data)
            decoded = json.decode(decrypted)
        end)
         
        if decoded or stat then
            config.key_encrypt = decoded.encrypt_key
            config.key_value = decoded.link_key
            config.url = decoded.socket_url
            
            break
        else
            write(1,8, "Invalid code!", colors.black, colors.red)
            sleep(1)
            fill(1,8,100,8)
        end
    end

    term.clear()
    term.setCursorPos(1,1)

    print("Enter a name for this server:")
    config.server_name = read()
    if config.server_name == "" then config.server_name = nil end

    writeConfig()
end
loadConfig()

local char_filter_list = {
    ["[\192-\197]"] = "A",
    ["[\200-\203]"] = "E",
    ["[\204-\207]"] = "I",
    ["[\210-\214]"] = "O",
    ["[\217-\220]"] = "U",
    ["[\224-\229]"] = "a",
    ["[\232-\235]"] = "e",
    ["[\236-\239]"] = "i",
    ["[\242-\246]"] = "o",
    ["[\249-\252]"] = "u",
    ["\198"] = "AE",
    ["\199"] = "C",
    ["\230"] = "ae",
    ["\231"] = "c",
}
local function sanitizeMessage(input)
    for k,v in pairs(char_filter_list) do
        input = input:gsub(k,v)
    end
    local out = ""
    for char in input:gmatch("[%w%s%p]") do
        out = out..char
    end
    return out
end

local websocket
local success_connected = false

local chat_queue = {}

local has_greeted = false

local function receiveThread()
    while true do
        local stat, err = pcall(function()
            if not success_connected then
                sleep(0.1)
            else
                local json_data = websocket.receive(nil, true)
                if json_data and type(json_data) == "string" then
                    local data = json.decode(json_data)
                    if data then
                        local decrypted_data = chacha20.crypt(config.key_encrypt, data.nonce, data.data)
                        if decrypted_data then
                            decrypted_data = json.decode(decrypted_data)
                            if decrypted_data.type == "dc_message" and decrypted_data.content then
                                chat_queue[#chat_queue+1] = {
                                    message = decrypted_data.content.message,
                                    username = decrypted_data.content.username
                                }
                                os.queueEvent("new_msg")
                            end
                        end
                    end
                end
            end
        end)
        if not stat then print(err) end
        sleep(0.1)
    end
end

local function sendCrypted(data)
    init_rand()
    local json_data = json.encode(data)
    local nonce = rand.random(12)
    local packed_data = json.encode({
        nonce=nonce,
        data=chacha20.crypt(config.key_encrypt, nonce, json_data)
    })
    websocket.send(packed_data, true)
    db_print("Sending: "..json_data)
end

local function greetThread()
    while true do
        local stat, err = pcall(function()
            if not success_connected then
                sleep(0.1)
            else
                local data = {
                    type="mc_greeting",
                    content={
                        name=config.server_name or "Unknown",
                        info="-# V"..script_version..", "..(_HOST):gsub("ComputerCraft", "CC"):gsub("Minecraft", "MC")..", "..os.getComputerID()
                    }
                }
                sendCrypted(data)
                chat_queue[#chat_queue+1] = {
                    message = "Minecraft <> Discord link has started!",
                    username = "CCDL"
                }
                os.queueEvent("new_msg")
                has_greeted = true
                return
            end
        end)
        if not stat then print(err) end
        sleep(0.1)
        if has_greeted then
            break
        end
    end
end

local function sendThread()
    while true do
        local stat, err = pcall(function()
            if not success_connected then
                sleep(0.1)
            else
                local event = {os.pullEvent()}
                db_print("received event: "..event[1])
                if event[1] == "chat" then
                    local event, username, message, uuid, hidden = table.unpack(event)
                    db_print("received msg: "..message)
                    if not hidden then
                        message = sanitizeMessage(message)
                        local data = {
                            type="mc_message",
                            content={
                                message=message,
                                username=username
                            }
                        }
                        sendCrypted(data)
                    end
                elseif event[1] == "playerJoin" or event[1] == "playerLeave" then
                    local event, username, dimension = table.unpack(event)
                    db_print("Event: "..event.." from "..username)
                    local data = {
                        type="mc_traffic",
                        content={
                            username=username,
                            type=event
                        }
                    }
                    sendCrypted(data)
                end
            end
            return true
        end)
        if not stat then print(err) end
        sleep(0.1)
    end
end

local function websocketWatcher()
    while true do
        local event = {os.pullEvent()}
        if event[1] == "websocket_closed" or event[1] == "websocket_failure" then
            print("Attempting reconnect!")
            success_connected = false 
            os.queueEvent("websocket_reconnect")
        end
    end
end

local function websocketController()
    while true do
        os.pullEvent("websocket_reconnect")
        repeat
            if websocket then
                websocket.close()
            end
            websocket = http.websocket({url=(config.url).."/?key="..(config.key_value), timeout=5})
            if websocket then 
                success_connected = true 
                print("Successfully connected.") 
            else 
                success_connected = false 
                if websocket then
                    websocket.close()
                end
                print("Unable to connect.") 
            end
        until success_connected
    end
end

local function chatManager()
    while true do
        local msg = chat_queue[1]
        if msg then
            local message = msg.message
            local name = msg.username
            local attempt = 0
            local success
            repeat
                for k, chatbox in pairs(chat_array) do
                    if chatbox.sendMessage(message, "\xA79"..name.."\xA7f", "<>") then
                        table.remove(chat_queue, 1)
                        success = true
                        break
                    end
                end
                sleep(0.1)
                attempt = attempt+1
            until attempt == 8 or success
        else
            os.pullEvent("new_msg")
        end
    end
end

local function heartbeatThread()
    local data = {type="mc_heartbeat", content=""}
    while true do
        local stat, err = pcall(function()
            if not success_connected then
                sleep(0.1)
            else
                db_print("Sending HB..")
                sendCrypted(data)
                local data = websocket.receive(0.25)
                if not data then
                    print("Heartbeat failed, reconnecting")
                    os.queueEvent("websocket_reconnect")
                else
                    db_print("Received HB")
                end
                sleep(15)
            end
        end)
        if not stat then print(err) sleep(0.1) end
    end
end

os.queueEvent("websocket_reconnect")

local stat, err = pcall(function (...)
    parallel.waitForAll(receiveThread, sendThread, websocketWatcher, websocketController, chatManager, greetThread, heartbeatThread) 
end)
if not stat then
    if err == "Terminated" then
        print("Terminated program.")
    else
        error(err)
    end
    if websocket then
        websocket.close()
    end
end
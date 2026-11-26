
local dependencies = {
    {
        name="X25519",
        path="/ccryptolib/x25519.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/x25519.lua",
    },
    {
        name="Internal.Util",
        path="/ccryptolib/internal/util.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/internal/util.lua",
    },
    {
        name="Internal.Hw",
        path="/ccryptolib/internal/hw.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/internal/hw.lua",
    },
    {
        name="Internal.Curve25519",
        path="/ccryptolib/internal/curve25519.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/internal/curve25519.lua",
    },
    {
        name="Internal.Fp",
        path="/ccryptolib/internal/fp.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/internal/fp.lua",
    },
    {
        name="Internal.Packing",
        path="/ccryptolib/internal/packing.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/internal/packing.lua",
    },
    {
        name="Internal.Edwards25519",
        path="/ccryptolib/internal/edwards25519.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/internal/edwards25519.lua",
    },
    {
        name="Config",
        path="/ccryptolib/config.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/config.lua",
    },
    {
        name="Random",
        path="/ccryptolib/random.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/random.lua",
    },
    {
        name="Blake3",
        path="/ccryptolib/blake3.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/blake3.lua",
    },
    {
        name="Chacha20",
        path="/ccryptolib/chacha20.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/chacha20.lua",
    },
    {
        name="Sha256",
        path="/ccryptolib/sha256.lua",
        url="https://raw.githubusercontent.com/migeyel/ccryptolib/refs/heads/main/ccryptolib/sha256.lua",
    },
}

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

local function write(x,y,text,bg,fg,clearline, target)
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

    if clearline then
        local w,h = term.getSize()
        fill(1,y, w,y, bg or old_bg, fg or old_fg, " ", target)
    end

    term.setCursorPos(x,y)
    term.write(text)

    local new_x, new_y = term.getCursorPos()

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
    return new_x, new_y
end

local function writeWrap(x,y,text,bg,fg, min_x, max_x, target)
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

    local w,h = term.getSize()
    local init_x, init_y = term.getCursorPos()

    for word in text:gmatch("[^%s]+") do
        if #word < max_x-min_x then
            local curr_x, curr_y = term.getCursorPos()
            if curr_x+#word > max_x then
                term.setCursorPos(min_x, curr_y+1)
            end

            term.write(word)
        else
            for char in word:gmatch(".") do
                local curr_x, curr_y = term.getCursorPos()
                if curr_x+1 > max_x then
                    term.setCursorPos(min_x, curr_y+1)
                end
                term.write(char)
            end
        end
        term.write(" ")
    end
    

    local new_x, new_y = term.getCursorPos()

    term.setTextColor(old_fg)
    term.setBackgroundColor(old_bg)
    term.setCursorPos(old_posx,old_posy)
    term.redirect(curr_term)
    return new_x, new_y
end

term.clear()
term.setCursorPos(1,1)

print("Checking dependencies..")
local last_x, last_y = term.getCursorPos()

local dl_count = 0
local dl_error = 0
for k,v in pairs(dependencies) do
    local dl = false
    local tp = 0
    write(last_x, last_y, v.name, colors.black, colors.yellow, true)
    if fs.exists(v.path) then
        local fs_io = io.open(v.path, "rb")
        if fs_io then
            local data = fs_io:read("*a")

            local res, err = http.get(v.url, nil, true)
            if res then
                local data2 = res:readAll()
                res:close()

                if data ~= data2 then
                    write(last_x, last_y, v.name, colors.black, colors.orange, true)
                    sleep(0.05)
                    dl = true
                    tp = 2
                end
            end
            fs_io:close()
        end
    else
        write(last_x, last_y, v.name, colors.black, colors.red, true)
        sleep(0.1)
        dl = true
        tp = 1
    end

    if dl then
        local dep_io = io.open(v.path, "wb")
        if dep_io then
            local res, err = http.get(v.url, nil, true)
            if res then
                dep_io:write(res:readAll())
                dep_io:close()
                res:close()
                write(last_x, last_y, v.name, colors.black, colors.lime, true)
                dl_count = dl_count + 1
            else
                write(last_x, last_y+1, v.url, colors.black, colors.red, true)
                if tp == 1 then
                    dl_error = dl_error + 1
                    return
                end
            end
        else
            write(last_x, last_y+1, v.path, colors.black, colors.red, true)
            if tp == 1 then
                dl_error = dl_error + 1
                return
            end
        end
        sleep(0.05)
    end
end

print("")

if dl_count > 0 then
    if dl_error > 0 then
        print("Failed to download "..dl_error.." dependencies")
    else
        print("Downloaded or updated "..dl_count.." dependencies")
    end
else
    if dl_error > 0 then
        print("Failed to download "..dl_error.." dependencies")
    else
        print("All "..#dependencies.." dependencies are available and up-to-date")
    end
end

local curve = require("ccryptolib.x25519")
local sha256 = require("ccryptolib.sha256")
local random = require("ccryptolib.random")
local cc20 = require("ccryptolib.chacha20")

local logs = {}

local allow_print = true
local function log(str)
    table.insert(logs, 1, str)
    if #logs > 256 then
        table.remove(logs, #logs)
    end
    if allow_print then
        print(str)
    end
end

local w, h = term.getSize()

log("Initializing random")
random.initWithTiming()

local modem = peripheral.find("modem")
rednet.open(peripheral.getName(modem))

local keyring = {}

local threads = {}

local data = {}

local buttons = {}

local nonce = 0

local function encryptSend(target, data)
    if keyring[target] and keyring[target].shared then
        local key = keyring[target].shared
        local encrypted_data = cc20.crypt(key, nonce, textutils.serialise(data), 20, 1)
        nonce = nonce + 1
        local request_id = math.random(10000, 99999)

        local rednet_data = {
            request_id = request_id,
            data=encrypted_data
        }

        rednet.send(
            data.target_id,
            rednet_data
            "jjs_jtcs"
        )
    else
        return nil, "no_shared_key", "The target id doesn't have a shared key saved"
    end
end

local function genericInput(data)
    fill(data.x, data.y, data.x2, data.y, data.bg, data.fg, " ")
    local default
    if type(data.default) == "function" then
        default = tostring(data.default()):sub(1, data.max)
    else
        default = tostring(data.default):sub(1, data.max)
    end

    local input = default
    while true do
        fill(data.x, data.y, data.x2, data.y, data.bg, data.fg, " ")
        if data.hide then
            if #input < data.max then
                write(data.x, data.y, string.rep(data.hide, #input).."_", data.bg, data.fg)
            else
                write(data.x, data.y, string.rep(data.hide, #input), data.bg, data.fg)
            end
        else
            if #input < data.max then
                write(data.x, data.y, input.."_", data.bg, data.fg)
            else
                write(data.x, data.y, input, data.bg, data.fg)
            end
        end
        local ev = {os.pullEvent()}
        if ev[1] == "key" then
            if ev[2] then
                if ev[2] == keys.enter or ev[2] == keys.numPadEnter then
                    break
                elseif ev[2] == keys.backspace then
                    input = input:sub(1,-2)
                end
            end
        elseif ev[1] == "char" then
            input = (input .. (ev[2]:match(data.filter) or "")):sub(1, data.max)
        elseif ev[1] == "mouse_click" then
            if ev[2] == 2 then
                return nil
            end
        elseif ev[1] == "paste" then
            for char in ev[2]:gmatch(data.filter) do
                input = (input .. char):sub(1, data.max)
            end
        end
    end

    if data.end_func then
        data.end_func(input)
    end

    return input
end

local function addTextInput(x,y, x2, max_length, bg,fg, default_input, pattern_filter, end_func, replace_char)
    buttons[#buttons+1] = {
        type="input",
        default = default_input,
        x=x,
        y=y,
        x2=x2,
        bg=bg,
        fg=fg,
        filter=pattern_filter or ".",
        max=max_length,
        end_func=end_func,
        hide=replace_char
    }
end

local function addButton(x,y, x2,y2, func)
    buttons[#buttons+1] = {
        type="button",
        x=x,
        y=y,
        x2=x2,
        y2=y2,
        func=func
    }
end

local menus = {
    {
        name="Connect",
        visible=false,
        id="connect",
        func=function()
            local lx = write(2,3, "Target Server ID:", colors.black, colors.lightGray)
            local lx2 = write(lx+1, 3, data.target_id or "N/A", colors.black, colors.white)
            addTextInput(lx+1, 3, lx+1+5, 5, colors.black, colors.yellow, function()
                return data.target_id or ""
            end, "%d", function(inp)
                local new_id = tonumber(inp)
                if new_id then
                    data.target_id = new_id
                end
            end)
            local _, ly = writeWrap(3,4, "You can find the ID on the computer that is connected to your tardis' console or interface", colors.black, colors.gray, 3, w-2)

            lx = write(2, ly+2, "Connect", colors.black, data.target_id and colors.lime or colors.red)
            if data.target_id then
                addButton(2, ly+2, lx, ly+2, function(btn)
                    local new_private = sha256.pbkdf2(random.random(32), random.random(16), 512)
                    local new_public = curve.publicKey(new_private)

                    keyring[data.target_id] = {
                        private=new_private,
                        public=new_public
                    }

                    rednet.send(
                        data.target_id,
                        {
                            command="init",
                            data={
                                key=new_public
                            }
                        },
                        "jjs_jtcs"
                    )
                    data.awaiting_init = true
                end)
            end
        end
    },
    {
        name="Connect (Password)",
        visible=false,
        id="password",
        func=function()
            local password = keyring[data.target_id].password
            write(2,3, "Server Password:", colors.black, colors.lightGray)
            if password then
                write(3,4, string.rep("*", #password), colors.black, colors.red)
            else
                write(3,4, "Enter Password", colors.black, colors.red)
            end
            addTextInput(3, 4, w-2, 16, colors.black, colors.red, function()
                return keyring[data.target_id].password or ""
            end, ".", function(inp)
                keyring[data.target_id].password = inp
            end, "*")
            local _, ly = writeWrap(3,6, "The server you're trying to connect to (ID "..data.target_id..") requires a password.", colors.black, colors.gray, 3, w-2)

            local lx = write(2, ly+2, "Confirm", colors.black, keyring[data.target_id].password and colors.lime or colors.red)
            addButton(2, ly+2, lx, ly+2, function(btn)
                rednet.send(
                    data.target_id,
                    {
                        command="init",
                        data={
                            key=new_public
                        }
                    },
                    "jjs_jtcs"
                )
            end)
        end
    },
}

local menus_map = {}
for k,v in pairs(menus) do
    menus_map[v.id] = v
end

local cmenu = menus_map.connect

threads[#threads+1] = function() --NETWORK-IN THREAD
    log("Starting network input thread")
    while true do
        local _, sender, msg, prot = os.pullEvent("rednet_message")
        if prot == "jjs_jtcs_c" and type(msg) == "table" then
            log("Received cmd '"..(msg.command or "NONE").."' from sender '"..sender.."'")
            if msg.command == "init" and data.awaiting_init then
                log("Generating key pair..")
                keyring[sender].shared = curve.exchange(keyring[sender].private, msg.data.key)
                if msg.data.need_password then
                    cmenu = menus_map.password
                    os.queueEvent("jjs_drawgui")
                end
                data.awaiting_init = false
            end
        end
    end
end

threads[#threads+1] = function() --GUI DRAW THREAD
    log("Starting GUI drawing thread")
    while true do
        os.pullEvent("jjs_drawgui")
        term.clear()
        fill(1,1, w,1, colors.gray)
        write(2,1, cmenu.name, colors.gray, colors.white)
        buttons = {}
        if cmenu.func then
            cmenu.func()
        end
    end
end

threads[#threads+1] = function() --INPUT THREAD
    log("Starting input thread")
    allow_print = false
    while true do
        local _, btn, x, y = os.pullEvent("mouse_click")

        for k,v in pairs(buttons) do
            if x >= v.x and x <= v.x2 and y >= v.y and y <= (v.y2 or v.y) then
                if v.type == "input" then
                    genericInput(v)
                    os.queueEvent("jjs_drawgui")
                elseif v.type == "button" then
                    if v.func then
                        v.func(btn, x,y)
                    end
                    os.queueEvent("jjs_drawgui")
                end
            end
        end
    end
end

print("STARTING THREADS")
os.queueEvent("jjs_drawgui")
parallel.waitForAll(table.unpack(threads))
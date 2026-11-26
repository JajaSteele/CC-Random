
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

term.clear()
term.setCursorPos(1,1)

print("Checking dependencies..")
local last_x, last_y = term.getCursorPos()

local dl_count = 0
local dl_error = 0
for k,v in pairs(dependencies) do
    local dl = false
    local tp = 0
    write(last_x, last_y, "Checking: "..v.name, colors.black, colors.yellow, true)
    if fs.exists(v.path) then
        local fs_io = io.open(v.path, "rb")
        if fs_io then
            local data = fs_io:read("*a")

            local res, err = http.get(v.url, nil, true)
            if res then
                local data2 = res:readAll()
                res:close()

                if data ~= data2 then
                    write(last_x, last_y, "Outdated dependency: "..v.name, colors.black, colors.orange, true)
                    sleep(0.05)
                    dl = true
                    tp = 2
                end
            end
            fs_io:close()
        end
    else
        write(last_x, last_y, "Missing dependency: "..v.name, colors.black, colors.red, true)
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
                write(last_x, last_y, "Downloaded dependency: "..v.name, colors.black, colors.lime, true)
                dl_count = dl_count + 1
            else
                write(last_x, last_y+1, "Couldn't fetch file: "..v.url, colors.black, colors.red, true)
                if tp == 1 then
                    dl_error = dl_error + 1
                    return
                end
            end
        else
            write(last_x, last_y+1, "Couldn't open file io: "..v.path, colors.black, colors.red, true)
            if tp == 1 then
                dl_error = dl_error + 1
                return
            end
        end
        sleep(0.05)
    end
end

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

local save_data = {}
if fs.exists("/.jtcs_data.txt") then
    local save_io = io.open("/.jtcs_data.txt", "r")
    if save_io then
        save_data = textutils.unserialise(save_io:read("*a"))
        save_io:close()
    else
        error("Unable to open '/.jtcs_data.txt'")
    end
end

local function writeSave()
    local save_io = io.open("/.jtcs_data.txt", "w")
    if save_io then
        save_io:write(textutils.serialise(save_data))
        save_io:close()
    else
        error("Unable to open '/.jtcs_data.txt'")
    end
end

print("Initializing random")
random.initWithTiming()

if not save_data.password then
    print("")
    print("This server has no password")
    print("Enter a new password (Or nothing, to disable authentification)")
    print("(16 characters max.)")
    local new_password_raw = read():sub(1, 16)
    if new_password_raw ~= "" then
        save_data.password = sha256.pbkdf2(new_password_raw, "", 512)
        print("Enter the password again to confirm")
        while true do
            local password_check_raw = read():sub(1, 16)
            if save_data.password == sha256.pbkdf2(password_check_raw, "", 512) then
                print("Password configured successfully!")
                break
            else
                print("Confirmation does not match your initial password!")
            end
        end
    else
        save_data.password = nil
    end
    writeSave()
end
local modem = peripheral.find("modem")
if modem then
    print("Activating rednet on modem '"..peripheral.getName(modem).."'")
    rednet.open(peripheral.getName(modem))
else
    error("No modem! Add a wireless or ender modem first")
end

local keyring = {}

local threads = {}

threads[#threads+1] = function() --NETWORK-IN THREAD
    print("Starting network input thread")
    while true do
        local _, sender, msg, prot = os.pullEvent("rednet_message")
        if prot == "jjs_jtcs" and type(msg) == "table" then
            print("Received cmd '"..(msg.command or "NONE").."' from sender '"..sender.."'")
            if msg.command == "init" then
                print("Generating local key pair..")
                local new_private = sha256.pbkdf2(random.random(32), random.random(16), 512)
                local new_public = curve.publicKey(new_private)

                local new_shared = curve.exchange(new_private, msg.data.key)
                keyring[sender] = {
                    private=new_private,
                    public=new_public,
                    shared=new_shared
                }

                print("Exchanging public key..")
                rednet.send(sender, {
                    command="init",
                    data={
                        key=new_public,
                        need_password=(save_data.password ~= nil)
                    }
                }, "jjs_jtcs_c")
            end
        end
    end
end

print("STARTING THREADS")
os.queueEvent("jjs_drawgui")
parallel.waitForAll(table.unpack(threads))
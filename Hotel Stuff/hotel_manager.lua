local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

local args = {...}

local config = {}

if args[1] == "config" or not fs.exists("/Hotel_clientconfig.txt") then
    print("Welcome to the configuration wizard!")
    print("id_pass?")
    config.id_pass = read()

    local configfile = io.open("/Hotel_clientconfig.txt","w")
    configfile:write(textutils.serialise(config))
    configfile:close()
end

local configfile = io.open("/Hotel_clientconfig.txt","r")
config = textutils.unserialise(configfile:read("*a"))
configfile:close()

modem.closeAll()
os.sleep(0.1)
rednet.open(peripheral.getName(modem))

term.clear()
term.setCursorPos(1,1)

term.write("Searching servers..")

local function sort_func(a,b)
    return a.id < b.id
end

local hotel_list = {rednet.lookup("hotel_server_"..config.id_pass)}
for k,v in ipairs(hotel_list) do
    term.setCursorPos(1,2)
    term.write("Checking server "..k)
    if v then
        rednet.send(v, "", "serverNameRequest")
        local id, msg, protocol = rednet.receive("serverNameReply",1)

        rednet.send(v, config.id_pass, "hotelUserRequest")
        local id, username, protocol = rednet.receive("hotelUserReply",1)

        rednet.send(v, config.id_pass, "hotelDateRequest")
        local id, last_date, protocol = rednet.receive("hotelDateReply",1)
        hotel_list[k] = {
            id=v,
            name=msg or "UNKNOWN",
            user=username or "UNKNOWN",
            date=last_date
        }
    end
end

table.sort(hotel_list, sort_func)

term.clear()
term.setCursorPos(1,1)

print("Hotel Rooms List:")

local oldBG = term.getBackgroundColor()
local oldFG = term.getTextColor()

for k,v in ipairs(hotel_list) do
    if k%2 == 0 then
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.lightGray)
    end
    print("["..v.id.."] "..v.name.." - "..v.user)
    print("Last Used: "..v.date)
    os.sleep(0.05)
end

term.setBackgroundColor(oldBG)
term.setTextColor(oldFG)

print("\nSelect ID: ")

local hotelID = tonumber(read())

rednet.send(hotelID, config.id_pass, "hotelUserRequest")
local id, username, protocol = rednet.receive("hotelUserReply",3)

rednet.send(hotelID, config.id_pass, "hotelDateRequest")
local id, last_date, protocol = rednet.receive("hotelDateReply",3)

term.clear()
term.setCursorPos(1,1)
term.write("Current User:")
term.setCursorPos(1,2)
term.write("  "..username)

term.setCursorPos(1,3)
term.write("Last Entrance:")
term.setCursorPos(1,4)
term.write("  "..last_date)

term.setCursorPos(1,6)
term.write("New User:")
term.setCursorPos(1,7)

local new_username = read()

rednet.send(hotelID, config.id_pass, "changeHotelUser_Auth")
local id, reply = rednet.receive("changeHotelUser_Auth_Reply", 1)
if reply == "ALLOWED" then
    rednet.send(hotelID, new_username, "changeHotelUser_NewUser")
    print("\nAccess Allowed!\n\nUsername successfully changed to: \n"..new_username)
elseif reply == "DENIED" then
    print("Access Denied!")
else
    print("Connection Lost")
end

os.sleep(2)

term.clear()
term.setCursorPos(1,1)
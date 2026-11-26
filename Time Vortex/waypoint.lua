local tardis = peripheral.find("tardis_console")

local chat = peripheral.find("chat_box")

print("Waiting for waypoint in chat (Journeymap)")

while true do
    local event, box, username, msg, hidden, idk = os.pullEvent("chat")
    print("Message: "..msg)
    if msg:match("^%[.+%]$") then
        local inner = msg:match("^%[(.+)%]$")
        print("Matching a waypoint format")
        local data = {}
        for key, val in inner:gmatch("([^%s%p]+):([^%s,]+)") do
            data[key] = val
        end

        tardis.setCourse(data.x, data.y, data.z)
    end
end
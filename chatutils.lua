local cb = peripheral.find("chatBox")

print("Name?")
local name = read()
local last_msg = ""

while true do
    term.clear()
    term.setCursorPos(1,1)
    print("Last Message:")
    print(last_msg)
    print("----------")
    term.write("["..name.."] ")
    local input = read()

    if input == "changeName" then
        print("Enter Name:")
        name = read()
    else
        last_msg = input
        cb.sendMessage(input,name)
    end
end
local file = io.open("inspect.txt", "w")

local stat, data = turtle.inspect()

file:write(textutils.serialise(data))

file:close()

for k,v in pairs(data) do
    print(textutils.serialise(v))
    os.pullEvent("mouse_click")
end
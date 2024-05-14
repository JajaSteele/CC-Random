local commands = {
    [[storage = peripheral.find("nbtStorage")]],
    [[lualzw = require("lualzw")]],
    [[data = textutils.unserialise(lualzw.decompress(storage.read().data))]]
}

for k,cmd in ipairs(commands) do
    for i1=1, #cmd do
        local char = cmd:sub(i1,i1)
        os.queueEvent("char", char)
    end
    os.queueEvent("key", keys.enter)
end
shell.execute("lua")
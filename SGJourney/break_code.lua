local req = http.get("https://raw.githubusercontent.com/JajaSteele/Cassettes/refs/heads/main/rickroll48k.dfpwm")
local lua_lzw = require("lualzw")

if not req then
    error("HTTP failed")
end

print("Checking for dependencies..")
if not fs.exists("/Base64") then
    print("Not found! Downloading..")
    shell.run("pastebin get QYvNKrXE Base64")
    print("Done!")
    os.loadAPI("/Base64")
    print("Library Loaded.\n")
    print("Validating..\n")
    os.sleep(0.1)
    local test1 = Base64.encode("Test12345")
    local test2 = Base64.decode(test1)
    os.sleep(0.1)
    if test2 == "Test12345" then
        print("Successfully Validated!")
    end
else
    print("All Dependencies found!")
    os.loadAPI("/Base64")
    print("Library Loaded.\n")
    print("Validating..\n")
    os.sleep(0.1)
    local test1 = Base64.encode("Test12345")
    local test2 = Base64.decode(test1)
    os.sleep(0.1)
    if test2 == "Test12345" then
        print("Successfully Validated!")
    end
end

local f = peripheral.find("transceiver")

local data = req.readAll()
print("Compressing "..#data.."b")
local comp_data = lua_lzw.compress(data)
print("Encoding "..#comp_data.."b")
local data_store = Base64.encode(comp_data)
print("Result: "..#data_store.."b")


f.setCurrentCode(data_store)
print("Storing: "..(data_store))
textutils.pagedPrint(data_store)
req.close()
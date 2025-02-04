local file = io.open("test.txt", "r")
local json_data = file:read("*a")
file:close()

local file2 = io.open("test_output.lua", "r")
local json_data2 = file2:read("*a")
file2:close()

local json = require("json")
local chacha20 = require("ccryptolib.chacha20")

local data = json.decode(json_data)
local data2 = json.decode(json_data2)
local key = "8U1C8eyur08bQ4M07199N7C4aLXd0l13"

print("Data1:")
print(data.nonce, (#(data.nonce)))
print(data.data)
local decoded = chacha20.crypt(key, data.nonce, data.data)
print(decoded)

print("")
print("Data2:")
print(data2.nonce, (#(data2.nonce)))
print(data2.data)
local decoded = chacha20.crypt(key, data2.nonce, data2.data)
print(decoded)
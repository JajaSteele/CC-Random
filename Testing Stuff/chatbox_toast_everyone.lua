local cb = peripheral.find("chatBox")
local pd = peripheral.find("playerDetector")

for k,v in pairs(pd.getOnlinePlayers()) do
    cb.sendToastToPlayer("This is a test toast", "TEST", v)
    sleep(1.2)
end
local sg = peripheral.find("basic_interface") or peripheral.find("crystal_interface") or peripheral.find("advanced_crystal_interface")
local trans = peripheral.find("transceiver")
local completion = require "cc.completion"

local config = {}

if fs.exists(".iris_detect.config") then
    local cfg_file = io.open(".iris_detect.config","r")
    config = textutils.unserialise(cfg_file:read("*a"))
    cfg_file:close()
else
    print("Redstone Output Side?")
    config.side = read(nil, nil, function(text) return completion.side(text) end)

    local cfg_file = io.open(".iris_detect.config","w")
    cfg_file:write(textutils.serialise(config))
    cfg_file:close()
end

while true do
    local iris_stat = trans.checkConnectedShielding()
    if iris_stat then
        rs.setAnalogOutput(config.side, (iris_stat/100)*15)
        print(iris_stat.."%")
        sleep(0.1)
    else
        rs.setOutput(config.side, false)
        print("Awaiting Stargate Connection..")
        repeat
            local ev = os.pullEvent()
        until ev == "stargate_incoming_wormhole" or ev == "stargate_outgoing_wormhole"
    end
end

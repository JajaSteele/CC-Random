local config
local completion = require "cc.completion"
local sides = {"left","right","front","back","up","bottom"}

local function fullClear()
    term.clear()
    term.setCursorPos(1,1)
end

local function monitorClear()
    monitor.clear()
    monitor.setCursorPos(1,1)
end

local function mprint(t,c)
    oldColor = monitor.getTextColor()
    if c then
        monitor.setTextColor(c)
    end
    monitor.write(tostring(t))
    monitor.setTextColor(oldColor)
    local currX,currY = monitor.getCursorPos()
    monitor.setCursorPos(1,currY+1)
end

local function mwrite(x,y,t)
    local currX,currY = monitor.getCursorPos()
    monitor.setCursorPos(x,y)
    monitor.write(tostring(t))
    monitor.setCursorPos(currX,currY)
end

if fs.exists("/ore.cfg") then
    local configfile = io.open("/ore.cfg","r")
    config = textutils.unserialise(configfile:read("*a"))
    configfile:close()
else
    print("Hello new user!")
    print("Starting the configuration..")
    os.sleep(1)
    newconfig = {}

    fullClear()
    print("Select the input side:")
    newconfig.input_side = read(nil, nil, completion.side)
    os.sleep(0.25)
    fullClear()
    print("Select the output side:")
    newconfig.output_side = read(nil, nil, completion.side)
    os.sleep(0.25)
    fullClear()
    print("Writing to file..")
    local configfile = io.open("/ore.cfg","w")
    configfile:write(textutils.serialise(newconfig))
    configfile:close()
    config = newconfig
end

input_storage = peripheral.wrap(config.input_side)
output_storage = peripheral.wrap(config.output_side)

monitor = peripheral.find("monitor")

while true do
    monitorClear()
    mprint("Press to Start")
    monitor.setTextColor(colors.red)
    mprint("(Put ores first!)")
    monitor.setTextColor(colors.white)
    os.pullEvent("monitor_touch")
    
    monitorClear()
    mprint("Scanning..")
    local item_list = {}
    local input_list = input_storage.list()
    local size = input_storage.size()
    for k,v in pairs(input_list) do
        mwrite(1,2,k.."/"..#input_list)
        name = v.name
        if item_list[name] ~= nil then
            item_list[name].count = item_list[name].count + v.count
        else
            item_list[name] = {}
            item_list[name].count = v.count
        end
        os.sleep(0.025)
    end

    for k,v in pairs(item_list) do
        for i1=1, size do
            mwrite(1,3,i1.."/"..size)
            local item = input_storage.getItemDetail(i1)
            if item and item.name == k then
                if item.tags["forge:raw_materials"] then
                    item_list[k].isRaw = true
                else
                    item_list[k].isRaw = false
                end
                break
            end
        end
    end

    monitorClear()
    for k,v in pairs(item_list) do
        if v.isRaw and math.fmod(v.count,3) ~= 0 then
            mprint("!WARN!",colors.red)
            mprint("Raw Ores must be")
            mprint("in multiple of 3!")
            if math.fmod(v.count,3) == 1 then
                mprint("(Add 2/Remove 1)")
            elseif math.fmod(v.count,3) == 2 then
                mprint("(Add 1/Remove 2")
            end
            os.pullEvent("monitor_touch")
            break
        end
    end

    print(textutils.serialise(item_list))
end
    
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

local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
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

local function mwrite(x,y,t,clear)
    local currX,currY = monitor.getCursorPos()
    monitor.setCursorPos(x,y)
    if clear then
        monitor.clearLine()
    end
    monitor.write(tostring(t))
    monitor.setCursorPos(currX,currY)
end

local function check(value,table1)
  local res = false
  for k,v in pairs(table1) do
    if value == v then
      res = true
      break
    end
  end
  return res
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

local function getTag(match,tags)
    local res = false
    for k,v in pairs(tags) do
        local tag1, n = k:gsub(match,"")
        if n > 0 then
            return(tag1)
        end
    end
end

local accepted_ores = {
    "aluminum",
    "nickel",
    "platinum",
    "silver",
    "tin",
    "zinc",
    "allthemodium",
    "unobtainium",
    "vibranium",
    "copper",
    "gold",
    "iron",
    "lead",
    "osmium",
    "uranium"
}

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
    local transfer_list = {}
    local input_list = input_storage.list()
    local size = input_storage.size()
    for k,v in pairs(input_list) do
        mwrite(1,2,k.."/"..#input_list,true)
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
            mwrite(1,3,i1.."/"..size,true)
            local item = input_storage.getItemDetail(i1)
            if item and item.name == k then
                if item.tags["forge:raw_materials"] then
                    item_list[k].isRaw = true
                    item_list[k].isAccepted = check(getTag("forge:raw_ores/",item.tags),accepted_ores)
                else
                    item_list[k].isRaw = false
                    item_list[k].isAccepted = check(getTag("forge:ores/",item.tags),accepted_ores)
                end
                break
            end
        end
    end

    
    local wrongRawAmount = false
    for k,v in pairs(item_list) do
        mwrite(1,2,k.."/"..#input_list,true)
        if v.isRaw and math.fmod(v.count,3) ~= 0 then
            wrongRawAmount = true
            monitorClear()
            mprint("WARN",colors.red)
            mprint("Raw Ores not in")
            mprint("multiple of 3!")
            mprint("("..split(k,":")[2]..")")
            item_list[k].count = v.count-math.fmod(v.count,3)
            os.sleep(1.35)
            monitorClear()
            mwrite(1,1,"Scanning..")
        end
        transfer_list[k] = 0
    end

    monitorClear()
    mwrite(1,1,"Transferring..")

    for i1=1, size do
        mwrite(1,2,i1.."/"..size,true)
        local item = input_storage.getItemDetail(i1)
        if item and item_list[item.name].isAccepted then
            if item_list[item.name].isRaw then
                local transferAmount = input_storage.pushItems(peripheral.getName(output_storage),i1,item_list[item.name].count-transfer_list[item.name])
                transfer_list[item.name] = transfer_list[item.name]+transferAmount
            else
                local transferAmount = input_storage.pushItems(peripheral.getName(output_storage),i1,64)
                transfer_list[item.name] = transfer_list[item.name]+transferAmount
            end
        end
    end

    monitorClear()
    mprint("Transfer Complete!",colors.lime)
    mprint("Please wait for")
    mprint("ores to process!")
    local fullTransfer = 0
    for k,v in pairs(transfer_list) do
        fullTransfer = fullTransfer+v
    end
    mprint("Total Items: "..fullTransfer)
    os.sleep(3)
end
    
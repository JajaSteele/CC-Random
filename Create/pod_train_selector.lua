local station = peripheral.find("Create_Station")
local monitor = peripheral.find("monitor")
local disk_drive = peripheral.find("drive")

local mon = window.create(monitor, 1,1, monitor.getSize())
local width, height = monitor.getSize()

local station_list = {}

local args = {...}

local function clamp(x,min,max) if x > max then return max elseif x < min then return min else return x end end

if fs.exists(disk_drive.getMountPath().."/station_list.txt") and args[1] ~= "edit" then
    local list_file = io.open(disk_drive.getMountPath().."/station_list.txt", "r")
    station_list = textutils.unserialise(list_file:read("*a"))
    list_file:close()
else
    local list_file = io.open(disk_drive.getMountPath().."/station_list.txt", "w")
    term.clear()
    term.setCursorPos(1,1)
    while true do
        print("Enter a station name:")
        local new_station = read()
        if new_station ~= "" then
            print("Enter a display name for the station:")
            local display_name = read()
            station_list[#station_list+1] = {id=new_station, name=display_name}
        else
            break
        end
    end
    list_file:write(textutils.serialise(station_list))
    list_file:close()
end


local function deepcopy(o, seen)
    seen = seen or {}
    if o == nil then return nil end
    if seen[o] then return seen[o] end
  
    local no
    if type(o) == 'table' then
      no = {}
      seen[o] = no
  
      for k, v in next, o, nil do
        no[deepcopy(k, seen)] = deepcopy(v, seen)
      end
      setmetatable(no, deepcopy(getmetatable(o), seen))
    else -- number, string, boolean, etc
      no = o
    end
    return no
  end
  

local scheduleTemplate = {
    cyclic = false,
    entries = {
        {
        instruction = {
            data = {
            text = "HB-Stop",
            },
            id = "create:destination",
        },
        conditions = {
            {
            {
                data = {
                value = 20,
                time_unit = 1,
                },
                id = "create:delay",
            },
            },
            {
            {
                data = {},
                id = "create:powered",
            },
            },
        },
        },
        {
        instruction = {
            data = {
            text = "TF-Start-Left",
            },
            id = "create:destination",
        },
        conditions = {
            {
            {
                data = {
                value = 5,
                time_unit = 1,
                },
                id = "create:delay",
            },
            },
        },
        },
    },
}

local function createSchedule(destination)
    local new_schedule = deepcopy(scheduleTemplate)

    new_schedule.entries[1].instruction.data.text = destination
    new_schedule.entries[2].instruction.data.text = station.getStationName()

    return new_schedule
end

local scroll = 0
local depart_timer = 0
local selected_entry = 0
local confirm_entry = false

local function centerText(parent_term, x, y, text)
    if parent_term then
        local len = text:len()
        parent_term.setCursorPos(((width/2)-(len/2)), y)
    end
end

local function drawSelector()
    mon.setVisible(false)
    mon.clear()
    mon.setCursorPos(1,1)
    mon.setTextColor(colors.yellow)
    mon.write("Select a Destination:")

    mon.setCursorPos(width/2,2)
    mon.setTextColor(colors.orange)
    mon.write("\x1E  \x1E")


    mon.setCursorPos(1,3)
    local count = 0
    for i1=1, height-4 do
        local entry_num = i1+scroll
        local entry = station_list[entry_num]
        if entry then
            centerText(mon, 1, 3+count, entry.name)
            if entry_num == selected_entry then
                mon.setTextColor(colors.lime)
            else
                mon.setTextColor(colors.white)
            end
            mon.write(entry.name)
            count = count+1
        end
    end

    mon.setCursorPos(width/2,height-1)
    mon.setTextColor(colors.orange)
    mon.write("\x1F  \x1F")

    if depart_timer <= 0 then
        local start_text = "\x11 Confirm \x10"
        centerText(mon, 1, height, start_text)
        mon.setTextColor(colors.green)
        mon.write(start_text)
    else
        local start_text = "\x11 Depart in "..depart_timer.."s \x10"
        centerText(mon, 1, height, start_text)
        mon.setTextColor(colors.red)
        mon.write(start_text)
    end
    mon.setVisible(true)
end

local function drawStandby()
    mon.setVisible(false)
    mon.clear()
    local text1 = station.getStationName()
    local text2 = "STANDBY"
    centerText(mon, 1, height/2, text1)
    mon.setTextColor(colors.orange)
    mon.write(text1)

    centerText(mon, 1, (height/2)+1, text2)
    mon.setTextColor(colors.red)
    mon.write(text2)
    mon.setVisible(true)
end

local is_train_present

local function drawThread()
    while true do
        if station.isTrainPresent() then
            drawSelector()
        else
            drawStandby()
        end
        os.pullEvent("redrawMonitor")
    end
end

local function clickThread()
    while true do
        local event, name, x, y = os.pullEvent("monitor_touch")
        if station.isTrainPresent() then
            if y == 2 then
                scroll = clamp(scroll-1, 0, #station_list)
            elseif y == height-1 then
                scroll = clamp(scroll+1, 0, #station_list)
            elseif y > 2 and y < height-1 then
                local entry_num = (y+scroll)-2
                local entry = station_list[entry_num]
                if entry then
                    selected_entry = entry_num
                end
            elseif y == height then
                if depart_timer <= 0 then
                    local selected_station = station_list[selected_entry]
                    if selected_station then
                        depart_timer = 5
                        confirm_entry = true
                    end
                else
                    depart_timer = 0
                    confirm_entry = false
                end
            end
            os.queueEvent("redrawMonitor")
        end
    end
end

local function trainCheckerThread()
    while true do
        if station.isTrainPresent() then
            if is_train_present ~= true then
                is_train_present = true
                os.queueEvent("redrawMonitor")
            end
        else
            if is_train_present ~= false then
                is_train_present = false
                os.queueEvent("redrawMonitor")
            end
        end
        sleep(0.5)
    end
end

local function timerThread()
    while true do
        if depart_timer > 0 then
            depart_timer = clamp(depart_timer-1, 0, depart_timer)
            os.queueEvent("redrawMonitor")
            sleep(1)
        end
        if depart_timer == 0 and selected_entry ~= 0 and confirm_entry then
            local selected_station = station_list[selected_entry]
            station.setSchedule(createSchedule(selected_station.id))
            selected_entry = 0
            confirm_entry = false
        end
        sleep()
    end
end

parallel.waitForAll(drawThread, clickThread, trainCheckerThread, timerThread)
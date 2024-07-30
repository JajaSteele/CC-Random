print("Rotation Count")

local count = tonumber(read())

local curr_time = os.epoch("ingame")/3600
rs.setAnalogOutput("back", 14)

repeat
    sleep()
until os.epoch("ingame")/3600 >= curr_time+(4*count)

rs.setAnalogOutput("back", 0)
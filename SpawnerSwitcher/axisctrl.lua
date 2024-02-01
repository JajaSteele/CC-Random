local y_gearshift = peripheral.wrap("Create_SequencedGearshift_1")
local x_gearshift = peripheral.wrap("Create_SequencedGearshift_0")

print("Enter Coords:")
print("X:")
local x_target = tonumber(read())
print("Y:")
local y_target = tonumber(read())

x_gearshift.move(8)
sleep(3)
y_gearshift.move(6, -1)
sleep(3)

x_gearshift.move(1-x_target, -1)
sleep(3)
y_gearshift.move(1-y_target)
sleep(3)

rs.setAnalogOutput("back", 15)
sleep(0.25)
rs.setAnalogOutput("back", 0)

x_gearshift.move(8, -1)
sleep(3)

y_gearshift.move(8, 1)
sleep(3)

rs.setAnalogOutput("back", 15)
sleep(0.25)
rs.setAnalogOutput("back", 0)

sleep(8)

x_gearshift.move(8)
sleep(3)
y_gearshift.move(6, -1)
sleep(3)

x_gearshift.move(1-x_target, -1)
sleep(3)
y_gearshift.move(1-y_target)
sleep(3)

rs.setAnalogOutput("back", 15)
sleep(0.25)
rs.setAnalogOutput("back", 0)

x_gearshift.move(8)
sleep(3)
y_gearshift.move(6, -1)
sleep(3)
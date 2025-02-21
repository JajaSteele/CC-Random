local drone = peripheral.find("drone_interface")

local function waitForAction()
    repeat
        sleep()
    until drone.isActionDone()
end

repeat
    sleep(0.5)
until drone.isConnectedToDrone()

local start = {x=21927, y=17, z=-11016}

drone.addArea(start.x, start.y, start.z)
drone.setAction("pneumaticcraft:goto")

waitForAction()

sleep(2)

drone.clearArea()

for i1=1, 20 do
    local curr = drone.getDronePositionVec()
    drone.addArea(math.floor(curr.x)+1, math.floor(curr.y), math.floor(curr.z))
    drone.setAction("pneumaticcraft:goto")

    repeat
        sleep()
    until drone.getDronePositionVec().x >= curr.x+0.5

    drone.clearArea()
end
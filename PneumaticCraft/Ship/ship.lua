local drone = peripheral.find("drone_interface")
local ply = peripheral.find("playerDetector")

local modems = {peripheral.find("modem")}

local modem

for k,v in pairs(modems) do
    if v.isWireless() == true then
        modem = modems[k]
    end
end

if modem then
    rednet.open(peripheral.getName(modem))
end

print("Computer ID: "..os.getComputerID())

local current_player = ""

local function rotate_point(cx, cy, angle, px, py)
    local absangl = math.abs(angle);
    local s = math.sin(absangl * (math.pi/180));
    local c = math.cos(absangl * (math.pi/180));

    -- translate point back to origin:
    px = px - cx
    py = py - cy

    -- rotate point
    local xnew
    local ynew
    if (angle > 0) then
        xnew = px * c - py * s
        ynew = px * s + py * c
    else 
        xnew = px * c + py * s;
        ynew = -px * s + py * c;
    end

    -- translate point back:
    px = xnew + cx;
    py = ynew + cy;
    return px, py
end

local input_axis = {
    x=0,
    y=0,
    z=0
}

local function droneThread()
    while true do
        local player_dat = ply.getPlayer(current_player)
        if player_dat and player_dat.yaw and drone.isConnectedToDrone() then
            local current = drone.getDronePositionVec()
            local target = {}
            target.x, target.z = rotate_point(current.x, current.z, (player_dat.yaw+90)%360, current.x+(input_axis.x*3), current.z+(input_axis.z*3))
            target.y = current.y + (input_axis.y * 2)
            target.x, target.y, target.z = math.floor(target.x), math.floor(target.y), math.floor(target.z)
            drone.clearArea()
            drone.addArea(target.x, target.y, target.z)
            drone.setAction("pneumaticcraft:goto")
            sleep()
        end
    end
end

local function remoteThread()
    while true do
        local sender, msg, protocol = rednet.receive("jjs_pnc_ship")
        if type(msg) == "table" then
            if msg.type == "axis_input" then
                input_axis[msg.content.axis] = msg.content.value
                print("Set axis: "..msg.content.axis.." to "..msg.content.value)
            elseif msg.type == "connection" then
                current_player = msg.content.user
                print("Set player: "..current_player)
            end
        end
    end
end

local stat, err = pcall(function ()
    parallel.waitForAll(remoteThread, droneThread)
end)

if not stat then
    if err == "Terminated" then

    end
    print(err)
end